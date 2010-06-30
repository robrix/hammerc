// HammerRuleCompiler.m
// Created by Rob Rix on 2009-12-06
// Copyright 2009 Monochrome Industries

#import "HammerBlockRuleVisitor.h"
#import "HammerCompiledRule.h"
#import "HammerRuleCompiler.h"
#import "HammerRuleCompilerVisitor.h"

#import "Auspicion.h"
#import "Hammer.h"

#import "ARXModule+RuntimeTypeEncodings.h"

@implementation HammerRuleCompiler

@synthesize module;

+(id)compiler {
	return [[self alloc] init];
}

-(id)init {
	if(self = [super init]) {
		context = [[ARXContext context] retain];
		module = [[ARXModule moduleWithName: @"HammerRuleCompilerModule" inContext: context] retain];
		printer = [[HammerRulePrinter alloc] init];
		
		ARXModuleImportType(module, HammerIndex);
		ARXModuleImportType(module, CFIndex);
		[module setType: context.int1Type forName: @"Boolean"];
		ARXModuleImportType(module, UniChar);
		CFCharacterSetRef characterSet = NULL;
		CFStringRef string = NULL;
		[module setObjCType: @encode(__typeof__(characterSet)) forName: @"CFCharacterSetRef"];
		[module setObjCType: @encode(__typeof__(string)) forName: @"CFStringRef"];
		
		ARXStructureType *rangeType = (ARXStructureType *)ARXModuleImportType(module, NSRange);
		[rangeType declareElementNames: [NSArray arrayWithObjects:
			@"location",
			@"length",
		nil]];
		
		ARXModuleImportType(module, HammerRuleRef);
		ARXModuleImportType(module, HammerSequenceRef);
		ARXModuleImportType(module, HammerMatchRef);
		ARXModuleImportType(module, NSString *);
		ARXStructureType *parserStateType = (ARXStructureType *)ARXModuleImportType(module, HammerParserState);
		[parserStateType declareElementNames: [NSArray arrayWithObjects:
			@"sequence",
			@"errorContext",
			@"matchContext",
			@"ruleGraph",
			@"isIgnoringMatches",
		nil]];
		[module setType: [ARXType pointerTypeToType: parserStateType] forName: @"HammerParserState*"];
		
		ARXFunctionType *lengthOfMatch = [ARXType functionType: context.integerType,
			[module typeNamed: @"HammerIndex"],
			[module typeNamed: @"HammerParserState*"],
		nil];
		[lengthOfMatch declareArgumentNames: [NSArray arrayWithObjects: @"initial", @"state", nil]];
		[module setType: lengthOfMatch forName: @"lengthOfMatch"];
		
		ARXFunctionType *rangeOfMatch = [ARXType functionType: context.int1Type,
			[ARXType pointerTypeToType: [module typeNamed: @"NSRange"]],
			[module typeNamed: @"HammerIndex"],
			[module typeNamed: @"HammerParserState*"],
		nil];
		[rangeOfMatch declareArgumentNames: [NSArray arrayWithObjects: @"outrange", @"initial", @"state", nil]];
		[module setType: rangeOfMatch forName: @"rangeOfMatch"];
	}
	return self;
}


-(HammerRuleRef)compileRule:(HammerRuleRef)rule {
	HammerBuiltRuleFunctions *builtFunctions = nil;
	ARXFunction *initializer = nil;
	@try {
		HammerBlockRuleVisitor *ruleVisitor = [[HammerBlockRuleVisitor alloc] init];
		
		[ruleVisitor visitRule: rule withVisitBlock: ^(HammerRuleRef rule, NSString *shortName) {
			SEL declarator = NSSelectorFromString([NSString stringWithFormat: @"declareGlobalDataFor%@:", shortName]);
			if([self respondsToSelector: declarator]) {
				[self performSelector: declarator withObject: rule];
			}
		}];
		
		initializer = [module functionWithName: [NSString stringWithFormat: @"%@ initialize", [self nameForRule: rule]] type: [ARXType functionType: context.voidType, nil] definition: ^(ARXFunctionBuilder *function){
			[ruleVisitor visitRule: rule withVisitBlock: ^(HammerRuleRef rule, NSString *shortName) {
				SEL selector = NSSelectorFromString([NSString stringWithFormat: @"initializeDataFor%@:", shortName]);
				if([self respondsToSelector: selector]) {
					[self performSelector: selector withObject: rule];
				}
			}];
			[function return];
		}];
		
		HammerRuleCompilerVisitor *visitor = [[HammerRuleCompilerVisitor alloc] initWithCompiler: self];
		builtFunctions = HammerRuleAcceptVisitor(rule, visitor);
	}
	@catch(NSException *exception) {
		NSLog(@"%@", [[exception callStackSymbols] componentsJoinedByString: @"\n"]);
		@throw exception;
	}
	
	NSError *error = nil;
	if(![module verifyWithError: &error]) {
		// LLVMDumpModule([module moduleRef]);
		NSLog(@"Error in module: %@", error.localizedDescription);
		return nil;
	}
	
	ARXCompiler *compiler = [ARXCompiler compilerWithContext: context];
	[compiler addModule: module];
	
	ARXOptimizer *optimizer = [ARXOptimizer optimizerWithCompiler: compiler];
	[optimizer addConstantPropagationPass];
	[optimizer addInstructionCombiningPass];
	[optimizer addPromoteMemoryToRegisterPass];
	// [optimizer addGVNPass];
	[optimizer addCFGSimplificationPass];
	
	[optimizer optimizeModule: module];
	
	void (*initialize)() = [compiler compiledFunction: initializer];
	initialize();
	
	HammerCompiledRuleRef compiledRule = HammerCompiledRuleCreate(rule, [compiler compiledFunction: builtFunctions.lengthOfMatch], [compiler compiledFunction: builtFunctions.rangeOfMatch]);
	
	return compiledRule;
}


-(NSString *)nameForRule:(HammerRuleRef)rule {
	return [NSString stringWithFormat: @"%s(%@)", RXObjectTypeGetName(RXGetType(rule)), [printer printRule: rule]];
}


-(ARXFunction *)lengthOfIgnorableCharactersFunction {
	return [module externalFunctionWithName: @"HammerRuleLengthOfIgnorableCharactersFromCursor" type: [ARXType functionType: [module typeNamed: @"HammerIndex"], [module typeNamed: @"HammerParserState*"], [module typeNamed: @"HammerIndex"], nil]];
}

-(ARXModuleFunctionDefinitionBlock)rangeOfMatchSkippingIgnorableCharactersDefinitionForRule:(HammerRuleRef)rule withLengthOfMatchFunction:(ARXFunction *)lengthOfMatch {
	return [^(ARXFunctionBuilder *function) {
		ARXPointerValue
			*length = [function allocateVariableOfType: [module typeNamed: @"HammerIndex"] value: [lengthOfMatch call: [function argumentNamed: @"initial"], [function argumentNamed: @"state"]]],
			*ignorable = [function allocateVariableOfType: [module typeNamed: @"HammerIndex"] value: [context constantUnsignedInteger: NSNotFound]];
		
		[[length.value equals: [context constantUnsignedInteger: NSNotFound]] ifTrue: ^{
			ignorable.value = [[self lengthOfIgnorableCharactersFunction] call: [function argumentNamed: @"state"], [function argumentNamed: @"initial"]];
			[[ignorable.value notEquals: [context constantUnsignedInteger: NSNotFound]] ifTrue: ^{
				length.value = [lengthOfMatch call: [[function argumentNamed: @"initial"] plus: ignorable.value], [function argumentNamed: @"state"]];
			}];
		}];
		
		[function structureArgumentNamed: @"outrange"].elements = [NSArray arrayWithObjects:
			[[function argumentNamed: @"initial"] plus: [[ignorable.value equals: [context constantUnsignedInteger: NSNotFound]] select: [context constantUnsignedInteger: 0] or: ignorable.value]],
			length.value,
		nil];
		[function return: [length.value notEquals: [context constantUnsignedInteger: NSNotFound]]];
	} copy];
}


-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForAlternationRule:(HammerAlternationRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	return [^(ARXFunctionBuilder *function) {
		ARXPointerValue *length = [function allocateVariableOfType: context.integerType value: [context constantUnsignedInteger: NSNotFound]];
		ARXBlock *returnBlock = [function addBlockWithName: @"return"];
		
		for(HammerBuiltRuleFunctions *subrule in subrules) {
			[[(length.value = [subrule.lengthOfMatch call: [function argumentNamed: @"initial"], [function argumentNamed: @"state"]]) notEquals: [context constantUnsignedInteger: NSNotFound]] ifTrue: ^{
				[function goto: returnBlock];
			}];
		}
		
		[function goto: returnBlock];
		
		[returnBlock define: ^{
			[function return: length.value];
		}];
	} copy];
}

-(ARXFunction *)rulesShouldBuildMatchesFunction {
	return [module externalFunctionWithName: @"HammerParserStateRulesShouldBuildMatches" type: [ARXType functionType: context.int1Type, [module typeNamed: @"HammerParserState*"], nil]];
}

-(ARXModuleFunctionDefinitionBlock)rangeOfMatchDefinitionForAlternationRule:(HammerAlternationRuleRef)rule withLengthOfMatchFunction:(ARXFunction *)lengthOfMatch {
	return [^(ARXFunctionBuilder *function) {
		ARXStructureValue *innerState = (ARXStructureValue *)[function allocateVariableOfType: [module typeNamed: @"HammerParserState"]];
		NSLog(@"%@", [function structureArgumentNamed: @"state"]);
		NSLog(@"%@", [[function structureArgumentNamed: @"state"] type]);
		innerState.elements = [function structureArgumentNamed: @"state"].elements;
		NSLog(@"%@", innerState);
		ARXPointerValue *result = [function allocateVariableOfType: context.int1Type value: [[self rangeOfMatchSkippingIgnorableCharactersDefinitionForRule: rule withLengthOfMatchFunction: lengthOfMatch] call: [function argumentNamed: @"outrange"], [function argumentNamed: @"initial"], innerState]];
		
		[[[result.value invert] and: [self.rulesShouldBuildMatchesFunction call: [function argumentNamed: @"state"]]] ifTrue: ^{
			[[function structureArgumentNamed: @"state"] setElement:
				[[[[innerState structureElementNamed: @"errorContext"] elementNamed: @"rule"] notEquals: [context constantNullOfType: [module typeNamed: @"HammerRuleRef"]]]
				select: [innerState structureElementNamed: @"errorContext"]
				    or: [context constantStructure: [function argumentNamed: @"initial"], rule, nil]]
			forName: @"errorContext"];
		}];
		[function return: result.value];
	} copy];
}


-(ARXFunction *)sequenceGetLengthFunction {
	return [module externalFunctionWithName: @"HammerSequenceGetLength" type: [ARXType functionType: [module typeNamed: @"HammerIndex"], [module typeNamed: @"HammerSequenceRef"], nil]];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForCharacterRule:(HammerCharacterRuleRef)rule {
	return [^(ARXFunctionBuilder *function) {
		[function return: [[[function argumentNamed: @"initial"] isUnsignedLessThan: [self.sequenceGetLengthFunction
			call: [[function structureArgumentNamed: @"state"] elementNamed: @"sequence"]]]
				select: [context constantUnsignedInteger: 1]
				    or: [context constantUnsignedInteger: NSNotFound]]];
	} copy];
}


-(ARXFunction *)characterIsMemberFunction {
	return [module externalFunctionWithName: @"CFCharacterSetIsCharacterMember" type: [ARXType functionType: [module typeNamed: @"Boolean"], [module typeNamed: @"CFCharacterSetRef"], [module typeNamed: @"UniChar"], nil]];
}

-(ARXFunction *)getCharacterAtIndexFunction {
	return [module externalFunctionWithName: @"CFStringGetCharacterAtIndex" type: [ARXType functionType: [module typeNamed: @"UniChar"], [module typeNamed: @"HammerSequenceRef"], [module typeNamed: @"CFIndex"], nil]];
}

-(ARXFunction *)sequenceGetStringFunction {
	return [module externalFunctionWithName: @"HammerSequenceGetString" type: [ARXType functionType: [module typeNamed: @"CFStringRef"], [module typeNamed: @"HammerSequenceRef"], nil]];
}


-(void)declareGlobalDataForCharacterSetRule:(HammerCharacterSetRuleRef)rule {
	[module declareGlobalOfType: [module typeNamed: @"CFCharacterSetRef"] forName: [self nameForRule: rule]];
}

-(void)initializeDataForCharacterSetRule:(HammerCharacterSetRuleRef)rule {
	// fixme: constant pointers are only viable for JIT
	// fixme: actually call the initializers from a function
	[module setGlobal: [context constantPointer: (void *)HammerCharacterSetRuleGetCharacterSet(rule) ofType: [module typeNamed: @"CFCharacterSetRef"]] forName: [self nameForRule: rule]];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForCharacterSetRule:(HammerCharacterSetRuleRef)rule {
	return [^(ARXFunctionBuilder *function) {
		ARXValue *sequence = [[function structureArgumentNamed: @"state"] elementNamed: @"sequence"];
		[function return: [[[[function argumentNamed: @"initial"] isUnsignedLessThan: [self.sequenceGetLengthFunction call: sequence]]
			and: [self.characterIsMemberFunction call: [module globalNamed: [self nameForRule: rule]], [self.getCharacterAtIndexFunction call: [self.sequenceGetStringFunction call: sequence], [function argumentNamed: @"initial"], nil], nil]
		] select: [context constantUnsignedInteger: 1]
		      or: [context constantUnsignedInteger: NSNotFound]]];
	} copy];
}

// -(ARXModuleFunctionDefinitionBlock)rangeOfMatchDefinitionForCharacterSetRule:(HammerCharacterSetRuleRef)rule {
// 	
// }


-(ARXFunction *)sequenceContainsSequenceAtIndexFunction {
	return [module externalFunctionWithName: @"HammerSequenceContainsSequenceAtIndex" type: [ARXType functionType: context.int1Type, [module typeNamed: @"HammerSequenceRef"], [module typeNamed: @"HammerSequenceRef"], [module typeNamed: @"HammerIndex"], nil]];
}

-(void)declareGlobalDataForLiteralRule:(HammerLiteralRuleRef)rule {
	[module declareGlobalOfType: [module typeNamed: @"HammerSequenceRef"] forName: [self nameForRule: rule]];
}

-(void)initializeDataForLiteralRule:(HammerLiteralRuleRef)rule {
	// fixme: constant pointers are only viable for JIT
	// fixme: actually call the initializers from a function
	[module setGlobal: [context constantPointer: (void *)HammerLiteralRuleGetSequence(rule) ofType: [module typeNamed: @"HammerSequenceRef"]] forName: [self nameForRule: rule]];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForLiteralRule:(HammerLiteralRuleRef)rule {
	return [^(ARXFunctionBuilder *function) {
		ARXValue *sequence = [[function structureArgumentNamed: @"state"] elementNamed: @"sequence"];
		[function return: [[[self.sequenceContainsSequenceAtIndexFunction call: sequence, [module globalNamed: [self nameForRule: rule]], [function argumentNamed: @"initial"]] toBoolean]
			select: [context constantUnsignedInteger: HammerSequenceGetLength(HammerLiteralRuleGetSequence(rule))]
			   or: [context constantUnsignedInteger: NSNotFound]]];
	} copy];
}

@end
