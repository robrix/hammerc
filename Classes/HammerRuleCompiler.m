// HammerRuleCompiler.m
// Created by Rob Rix on 2009-12-06
// Copyright 2009 Monochrome Industries

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
		[module setType: [ARXType pointerTypeToType: parserStateType] forName: @"HammerParserState *"];
		
		ARXFunctionType *lengthOfMatch = [ARXType functionType: context.integerType,
			[module typeNamed: @"HammerIndex"],
			[module typeNamed: @"HammerParserState *"],
		nil];
		[lengthOfMatch declareArgumentNames: [NSArray arrayWithObjects: @"initial", @"state", nil]];
		[module setType: lengthOfMatch forName: @"lengthOfMatch"];
		
		ARXFunctionType *rangeOfMatch = [ARXType functionType: context.int1Type,
			[ARXType pointerTypeToType: [module typeNamed: @"NSRange"]],
			[module typeNamed: @"HammerIndex"],
			[module typeNamed: @"HammerParserState *"],
		nil];
		[rangeOfMatch declareArgumentNames: [NSArray arrayWithObjects: @"outrange", @"initial", @"state", nil]];
		[module setType: rangeOfMatch forName: @"rangeOfMatch"];
	}
	return self;
}


-(HammerRuleRef)compileRule:(HammerRuleRef)rule {
	HammerBuiltRuleFunctions *builtFunctions = nil;
	@try {
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
	// [optimizer addCFGSimplificationPass];
	
	[optimizer optimizeModule: module];
	
	HammerCompiledRuleRef compiledRule = HammerCompiledRuleCreate(rule, [compiler compiledFunction: builtFunctions.lengthOfMatch], [compiler compiledFunction: builtFunctions.rangeOfMatch]);
	
	return compiledRule;
}


-(NSString *)nameForRule:(HammerRuleRef)rule {
	return [NSString stringWithFormat: @"%s(%@)", RXObjectTypeGetName(RXGetType(rule)), [printer printRule: rule]];
}


-(ARXFunction *)lengthOfIgnorableCharactersFunction {
	return [module externalFunctionWithName: @"HammerRuleLengthOfIgnorableCharactersFromCursor" type: [ARXType functionType: [module typeNamed: @"HammerIndex"], [module typeNamed: @"HammerParserState *"], [module typeNamed: @"HammerIndex"], nil]];
/*
	return [module functionWithName: @"HammerRuleLengthOfIgnorableCharactersFromCursor" type: [ARXType functionType: [module typeNamed: @"HammerIndex"], [module typeNamed: @"HammerParserState *"], [module typeNamed: @"HammerIndex"], nil] definition: ^(ARXFunctionBuilder *function) {
		ARXPointerValue
			*length = [function allocateVariableOfType: [module typeNamed: @"HammerIndex"] value: [context constantUnsignedInteger: NSNotFound]],
			*ignorableRule = [function allocateVariableOfType: [module typeNamed: @"HammerRuleRef"] value: [[self ruleGraphGetRuleForNameFunction] call: ((ARXPointerValue *)[function argumentNamed: @"state"]).value elementNamed: @"ruleGraph"]];
		
	}];
*/
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForRule:(HammerRuleRef)rule {
	return [self performSelector: NSSelectorFromString([NSString stringWithFormat: @"lengthOfMatchDefinitionFor%@:", (NSString *)HammerRuleGetShortTypeName(rule)]) withObject: rule];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForRule:(HammerRuleRef)rule withVisitedSubrule:(ARXFunction *)subrule {
	return [self performSelector: NSSelectorFromString([NSString stringWithFormat: @"lengthOfMatchDefinitionFor%@:withVisitedSubrule:", (NSString *)HammerRuleGetShortTypeName(rule), subrule]) withObject: rule withObject: subrule];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForRule:(HammerRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	return [self performSelector: NSSelectorFromString([NSString stringWithFormat: @"lengthOfMatchDefinitionFor%@:withVisitedSubrules:", (NSString *)HammerRuleGetShortTypeName(rule), subrules]) withObject: rule withObject: subrules];
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

-(ARXModuleFunctionDefinitionBlock)rangeOfMatchFunctionForAlternationRule:(HammerAlternationRuleRef)rule {
	NSLog(@"type of a function: %s", @encode(HammerRuleLengthOfMatchMethod));
	return nil;
}


-(ARXFunction *)sequenceGetLengthFunction {
	return [module externalFunctionWithName: @"HammerSequenceGetLength" type: [ARXType functionType: [module typeNamed: @"HammerIndex"], [module typeNamed: @"HammerSequenceRef"], nil]];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchFunctionForCharacterRule:(HammerCharacterRuleRef)rule {
	return [^(ARXFunctionBuilder *function) {
		[[[function argumentNamed: @"initial"] isUnsignedLessThan: [self.sequenceGetLengthFunction
			call: [[function pointerArgumentNamed: @"state"].structureValue elementNamed: @"sequence"]]]
				select: [context constantUnsignedInteger: 1]
				    or: [context constantUnsignedInteger: NSNotFound]];
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


-(void)initializeDataForCharacterSetRule:(HammerCharacterSetRuleRef)rule {
	// fixme: constant pointers are only viable for JIT
	// fixme: actually call the initializers from a function
	[module initializeGlobal: [context constantPointer: (void *)HammerCharacterSetRuleGetCharacterSet(rule) ofType: [module typeNamed: @"CFCharacterSetRef"]] forName: [self nameForRule: rule]];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForCharacterSetRule:(HammerCharacterSetRuleRef)rule {
	return [^(ARXFunctionBuilder *function) {
		[self initializeDataForCharacterSetRule: rule];
		
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

-(void)initializeDataForLiteralRule:(HammerLiteralRuleRef)rule {
	// fixme: constant pointers are only viable for JIT
	// fixme: actually call the initializers from a function
	[module initializeGlobal: [context constantPointer: (void *)HammerLiteralRuleGetSequence(rule) ofType: [module typeNamed: @"HammerSequenceRef"]] forName: [self nameForRule: rule]];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForLiteralRule:(HammerLiteralRuleRef)rule {
	return [^(ARXFunctionBuilder *function) {
		[self initializeDataForLiteralRule: rule];
		
		ARXValue *sequence = [[function structureArgumentNamed: @"state"] elementNamed: @"sequence"];
		[function return: [[[self.sequenceContainsSequenceAtIndexFunction call: sequence, [module globalNamed: [self nameForRule: rule]], [function argumentNamed: @"initial"]] toBoolean]
			select: [context constantUnsignedInteger: HammerSequenceGetLength(HammerLiteralRuleGetSequence(rule))]
			   or: [context constantUnsignedInteger: NSNotFound]]];
	} copy];
}


@end
