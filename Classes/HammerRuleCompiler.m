// HammerRuleCompiler.m
// Created by Rob Rix on 2009-12-06
// Copyright 2009 Monochrome Industries

#import "HammerCompiledRule.h"
#import "HammerRuleCompiler.h"

#import <Auspicion/Auspicion.h>
#import <Hammer/Hammer.h>

#import "LLVMModule+RuntimeTypeEncodings.h"

@interface HammerRuleCompiler () <HammerRuleVisitor>

-(void)pushRule;
-(NSArray *)popRule;

-(NSString *)nameForFunction:(NSString *)function forRule:(HammerRuleRef)rule;
-(NSString *)nameForRule:(HammerRuleRef)rule;

@end

@implementation HammerRuleCompiler

-(id)init {
	if(self = [super init]) {
		context = [[LLVMContext context] retain];
		builder = [[LLVMBuilder builderWithContext: context] retain];
		
		module = [[LLVMModule moduleWithName: @"HammerRuleCompilerModule" inContext: context] retain];
		
		LLVMModuleImportType(module, HammerIndex);
		LLVMModuleImportType(module, NSRange);
		
		LLVMModuleImportType(module, HammerRuleRef);
		LLVMModuleImportType(module, HammerSequenceRef);
		LLVMModuleImportType(module, HammerMatchRef);
		LLVMModuleImportType(module, NSString *);
		LLVMModuleImportType(module, HammerParserState *);
		
		[module setType: [LLVMType functionType: context.integerType,
			[module typeNamed: @"HammerIndex"],
			[module typeNamed: @"HammerParserState *"],
		nil] forName: @"HammerRuleLengthOfMatchFunction"];
		
		[module setType: [LLVMType functionType: context.int1Type,
			[LLVMType pointerTypeToType: [module typeNamed: @"NSRange"]],
			[module typeNamed: @"HammerIndex"],
			[module typeNamed: @"HammerParserState *"],
		nil] forName: @"HammerRuleRangeOfMatchFunction"];
		
		printer = [[HammerRulePrinter alloc] init];
	}
	return self;
}

-(void)dealloc {
	[context release];
	[builder release];
	[module release];
	[printer release];
	[super dealloc];
}


-(HammerRuleRef)compileRule:(HammerRuleRef)rule {
	NSArray *builtFunctionsArray = nil;
	builtFunctionsStack = [[NSMutableArray alloc] init];
	[self pushRule];
	
	@try {
		HammerRuleAcceptVisitor(rule, self);
	}
	@catch(NSException *exception) {
		NSLog(@"%@", [[exception callStackSymbols] componentsJoinedByString: @"\n"]);
		@throw exception;
	}
	
	builtFunctionsArray = [self popRule];
	
	NSError *error = nil;
	if(![module verifyWithError: &error]) {
		// LLVMDumpModule([module moduleRef]);
		NSLog(@"Error in module: %@", error.localizedDescription);
		return nil;
	}
	
	LLVMCompiler *compiler = [LLVMCompiler sharedCompiler];
	[compiler addModule: module];
	
	LLVMOptimizer *optimizer = [LLVMOptimizer optimizerWithCompiler: compiler];
	[optimizer addConstantPropagationPass];
	[optimizer addInstructionCombiningPass];
	[optimizer addPromoteMemoryToRegisterPass];
	// [optimizer addGVNPass];
	// [optimizer addCFGSimplificationPass];
	
	[optimizer optimizeModule: module];
	
	NSAssert(builtFunctionsArray.count >= 1, @"No functions were built.");
	HammerBuiltRuleFunctions *builtFunctions = builtFunctionsArray.lastObject;
	
	HammerCompiledRuleRef compiledRule = HammerCompiledRuleCreate(rule, [compiler compiledFunction: builtFunctions.lengthOfMatch], [compiler compiledFunction: builtFunctions.rangeOfMatch]);
	
	[builtFunctionsStack release];
	
	return compiledRule;
}


/*
-(LLVMFunction *)lengthOfIgnorableCharactersFunction {
	return [module functionWithName: @"HammerRuleLengthOfIgnorableCharactersFromCursor" type: [LLVMType functionType: [module typeNamed: @"HammerIndex"], [module typeNamed: @"HammerParserState *"], [module typeNamed: @"HammerIndex"]] definition: ^(LLVMFunctionBuilder *) {
		LLVMValue
			*length = [function allocateVariableOfType: [module typeNamed: @"HammerIndex"] value: LLVMConstant(NSNotFound)],
			*ignorableRule = [function allocateVariableOfType: [module typeNamed: @"HammerRuleRef"] value: [[self ruleGraphGetRuleForNameFunction] call: ]];
		
	}];
}


-(LLVMFunction *)rangeOfMatchSkippingIgnorableCharactersFunctionForRule:(HammerRuleRef)rule withLengthOfMatchFunction:(LLVMFunction *)lengthOfMatch {
	return [module functionWithName: [self nameForFunction: @"rangeOfMatchSkppingIgnorableCharacters" forRule: rule] type: [module typeNamed: @"HammerRuleRangeOfMatchFunction"] definitionBlock: ^(LLVMFunctionBuilder *function) {
		[function declareArguments: [NSArray arrayWithObjects: @"outrange", @"initial", @"state", nil]];
		
		LLVMValue
			*length = [function allocateVariableOfType: [module typeNamed: @"HammerIndex"] value: [lengthOfMatch call: [function argumentNamed: @"initial"], [function argumentNamed: @"state"]]],
			*ignorable = [function allocateVariableOfType: [module typeNamed: @"HammerIndex"] value: LLVMConstant(NSNotFound)];
		
		[[length.value equals: LLVMConstant(NSNotFound)] ifTrue: ^{
			ignorable.value = [[self lengthOfIgnorableCharactersFunction] call: [function argumentNamed: @"state"], [function argumentNamed: @"initial"]];
			[[ignorable.value notEquals: LLVMConstant(NSNotFound)] ifTrue: ^{
				length.value = [lengthOfMatch call: [[function argumentNamed: @"initial"] plus: ignorable.value], [function argumentNamed: @"state"]];
			}];
		}];
		
		[function argumentNamed: @"outrange"].value = [LLVMStruct structWithValues:
			[[function argumentNamed: @"initial"] plus: [[ignorable.value equals: LLVMConstant(NSNotFound)] select: LLVMConstant(0) or: ignorable.value]],
			length.value,
		nil];
		[function return: [length notEquals: LLVMConstant(NSNotFound)]];
	}];
}
*/


-(LLVMFunction *)defaultRangeOfMatchFunctionForRule:(HammerRuleRef)rule withLengthOfMatchFunction:(LLVMFunction *)lengthOfMatch {
	NSString *name = [self nameForFunction: @"rangeOfMatchFromCursor:withParser:" forRule: rule];
	
	LLVMFunction *ignorableCharactersFromCursor = [module declareExternalFunctionWithName: @"HammerParserIgnorableCharactersFromCursor" type: [LLVMType functionType: context.integerType, context.untypedPointerType, context.integerType, nil]];
	
	LLVMFunction *rangeOfMatch = [module functionWithName: name];
	if(!rangeOfMatch) {
		rangeOfMatch = [module functionWithName: name typeName: @"HammerRuleRangeOfMatchFunction"];
		[builder positionAtEndOfFunction: rangeOfMatch];
		
		LLVMBlock
			*tryIgnorableBlock = [rangeOfMatch appendBlockWithName: @"tryIgnorable"],
			*retryAfterIgnorableBlock = [rangeOfMatch appendBlockWithName: @"retryAfterIgnorable"],
			*returnBlock = [rangeOfMatch appendBlockWithName: @"return"];
		
		LLVMValue
			*notFound = [context constantUnsignedInteger: NSNotFound],
			*zero = [context constantUnsignedInteger: 0],
			*length = [builder allocateLocal: @"length" type: context.integerType],
			*ignorable = [builder allocateLocal: @"ignorable" type: context.integerType];
		
		// NSUInteger length = [self lengthOfMatchFromCursor: initial withParser: parser];
		[builder set: length, [builder call: lengthOfMatch, [rangeOfMatch parameterAtIndex: 1], [rangeOfMatch parameterAtIndex: 2], nil]];
		
		// NSUInteger ignorable = NSNotFound;
		[builder set: ignorable, notFound];
		
		// if(length == NSNotFound)
		[builder if: [builder equal: [builder get: length], notFound] then: tryIgnorableBlock else: returnBlock];
		[builder positionAtEndOfBlock: tryIgnorableBlock]; {
			// ignorable = HammerParserIgnorableCharactersFromCursor(parser, initial);
			[builder set: ignorable, [builder call: ignorableCharactersFromCursor, [rangeOfMatch parameterAtIndex: 2], [rangeOfMatch parameterAtIndex: 1], nil]];
			
			// if(ignorable != NSNotFound)
			[builder if: [builder notEqual: [builder get: ignorable], notFound] then: retryAfterIgnorableBlock else: returnBlock];
			[builder positionAtEndOfBlock: retryAfterIgnorableBlock]; {
				// length = [self lengthOfMatchFromCursor: initial + ignorable withParser: parser];
				[builder set: length, [builder call: lengthOfMatch, [builder add: [rangeOfMatch parameterAtIndex: 1], [builder get: ignorable]], [rangeOfMatch parameterAtIndex: 2], nil]];
				
				[builder jumpToBlock: returnBlock];
			}
		}
		
		[builder positionAtEndOfBlock: returnBlock]; {
			[builder setElements: [rangeOfMatch parameterAtIndex: 0],
				[builder add:
					[rangeOfMatch parameterAtIndex: 1],
					[builder condition: [builder equal: [builder get: ignorable], notFound]
						then: zero
						else: [builder get: ignorable]
					]
				],
				[builder get: length],
			nil];
			
			[builder return: [builder notEqual: [builder get: length], notFound]];
		}
	}
	return rangeOfMatch;
}


-(HammerBuiltRuleFunctions *)defaultFunctionsForRule:(HammerRuleRef)rule withLengthOfMatchFunction:(LLVMFunction *)lengthOfMatch {
	HammerBuiltRuleFunctions *functions = [[[HammerBuiltRuleFunctions alloc] init] autorelease];
	functions.lengthOfMatch = lengthOfMatch;
	functions.rangeOfMatch = [self defaultRangeOfMatchFunctionForRule: rule withLengthOfMatchFunction: lengthOfMatch];
	return functions;
}


-(void)addBuiltFunctions:(HammerBuiltRuleFunctions *)functions {
	[builtFunctionsStack.lastObject addObject: functions];
}


-(void)pushRule {
	[builtFunctionsStack addObject: [NSMutableArray array]];
}

-(NSArray *)popRule {
	NSArray *lastFunctions = [[builtFunctionsStack.lastObject retain] autorelease];
	[builtFunctionsStack removeLastObject];
	return lastFunctions;
}


-(LLVMFunction *)parserIsAtEndFunction {
	return [module declareExternalFunctionWithName: @"HammerParserCursorIsAtEnd" type: [LLVMType functionType: context.int1Type,
		context.untypedPointerType,
		context.integerType,
	nil]];
}

-(LLVMFunction *)parserGetInputStringFunction {
	return [module declareExternalFunctionWithName: @"HammerParserGetInputString" type: [LLVMType functionType: context.untypedPointerType, context.untypedPointerType, nil]];
}


-(NSString *)nameForFunction:(NSString *)function forRule:(HammerRuleRef)rule {
	return [NSString stringWithFormat: @"%s(%@) %@", RXObjectTypeGetName(RXGetType(rule)), [printer printRule: rule], function];
}

-(NSString *)nameForRule:(HammerRuleRef)rule {
	return [self nameForFunction: @"lengthOfMatchFromCursor:withParser:" forRule: rule];
}


-(void)leaveAlternationRule:(HammerAlternationRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfBlock: lengthOfMatch.entryBlock];
		
		LLVMValue *length = [builder allocateLocal: @"length" type: context.integerType];
		
		LLVMBlock *returnBlock = [lengthOfMatch appendBlockWithName: @"return"];
		
		NSUInteger i = 0;
		for(HammerBuiltRuleFunctions *subrule in subrules) {
			LLVMBlock *subruleBlock = [lengthOfMatch appendBlockWithName: [NSString stringWithFormat: @"subrule %d", i]];
			[builder jumpToBlock: subruleBlock];
			[builder positionAtEndOfBlock: subruleBlock];
			
			[builder set: length, [builder call: subrule.lengthOfMatch, [lengthOfMatch parameterAtIndex: 0], [lengthOfMatch parameterAtIndex: 1], nil]];
			
			LLVMBlock *subruleNotMatchedBlock = [lengthOfMatch appendBlockWithName: [NSString stringWithFormat: @"subrule %d not matched", i]];
			[builder if: [builder notEqual: [builder get: length], [context constantUnsignedInteger: NSNotFound]] then: returnBlock else: subruleNotMatchedBlock];
			
			[builder positionAtEndOfBlock: subruleNotMatchedBlock];
			i++;
		}
		
		[builder jumpToBlock: returnBlock];
		
		[builder positionAtEndOfBlock: returnBlock];
		[builder return: [builder get: length]];
	}
	
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveCharacterRule:(HammerCharacterRuleRef)rule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfFunction: lengthOfMatch];
		
		[builder return: [builder condition:
			[builder not: [builder call: [self parserIsAtEndFunction], [lengthOfMatch parameterAtIndex: 1], [lengthOfMatch parameterAtIndex: 0], nil]]
			then: [context constantUnsignedInteger: 1]
			else: [context constantUnsignedInteger: NSNotFound]
		]];
	}
	
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveCharacterSetRule:(HammerCharacterSetRuleRef)rule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction *isCharacterMemberFunction = [module declareExternalFunctionWithName: @"CFCharacterSetIsCharacterMember" type: [LLVMType functionType: context.int1Type, context.untypedPointerType, context.int16Type, nil]];
	LLVMFunction *characterAtIndexFunction = [module declareExternalFunctionWithName: @"CFStringGetCharacterAtIndex" type: [LLVMType functionType: context.int16Type, context.untypedPointerType, context.integerType, nil]];
	
	LLVMValue *notFound = [context constantUnsignedInteger: NSNotFound];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfFunction: lengthOfMatch];
		
		[builder return: [builder condition: [builder and:
				[builder not: [builder call: [self parserIsAtEndFunction], [lengthOfMatch parameterAtIndex: 1], [lengthOfMatch parameterAtIndex: 0], nil]],
				[builder call: isCharacterMemberFunction,
					[context constantUntypedPointer: HammerCharacterSetRuleGetCharacterSet(rule)],
					[builder call: characterAtIndexFunction,
						[builder call: [self parserGetInputStringFunction], [lengthOfMatch parameterAtIndex: 1], nil],
						[lengthOfMatch parameterAtIndex: 0],
					nil],
				nil]
			]
			then: [context constantUnsignedInteger: 1]
			else: notFound
		]];
	}
	
	name = [self nameForFunction: @"range:ofMatchFromCursor:withParser:" forRule: rule];
	LLVMFunction *rangeOfMatch = [module functionWithName: name];
	if(!rangeOfMatch) {
		rangeOfMatch = [module functionWithName: name typeName: @"HammerRuleRangeOfMatchFunction"];
		[builder positionAtEndOfFunction: rangeOfMatch];
		
		[builder setElements: [rangeOfMatch parameterAtIndex: 0],
			[rangeOfMatch parameterAtIndex: 1],
			[context constantUnsignedInteger: 1],
		nil];
		
		[builder return: [builder notEqual: [builder call: lengthOfMatch, [rangeOfMatch parameterAtIndex: 1], [rangeOfMatch parameterAtIndex: 2], nil], notFound]];
	}
	
	HammerBuiltRuleFunctions *functions = [[[HammerBuiltRuleFunctions alloc] init] autorelease];
	functions.lengthOfMatch = lengthOfMatch;
	functions.rangeOfMatch = rangeOfMatch;
	
	[self addBuiltFunctions: functions];
}


-(void)leaveConcatenationRule:(HammerConcatenationRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction
		*pushMatchContext = [module declareExternalFunctionWithName: @"HammerParserPushMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], nil]],
		*popMatchContext = [module declareExternalFunctionWithName: @"HammerParserPopAndPassUpMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], context.int1Type, nil]];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfBlock: lengthOfMatch.entryBlock];
		
		[builder call: pushMatchContext, [lengthOfMatch parameterAtIndex: 1], nil];
		
		LLVMValue
			*length = [builder allocateLocal: @"length" type: context.integerType],
			*subrange = [builder allocateLocal: @"subrange" type: [module typeNamed: @"NSRange"]];
		
		[builder set: length, [context constantUnsignedInteger: 0]];
		
		LLVMBlock
			*notFoundBlock = [lengthOfMatch appendBlockWithName: @"notFound"],
			*returnLengthBlock = [lengthOfMatch appendBlockWithName: @"returnLength"];
		
		NSUInteger i = 0;
		for(HammerBuiltRuleFunctions *subruleFunctions in subrules) {
			LLVMBlock *subruleBlock = [lengthOfMatch appendBlockWithName: [NSString stringWithFormat: @"subrule %d", i]];
			LLVMBlock *subruleFoundBlock = [lengthOfMatch appendBlockWithName: [NSString stringWithFormat: @"subrule %d found", i]];
			[builder jumpToBlock: subruleBlock];
			[builder positionAtEndOfBlock: subruleBlock]; {
				[builder if: [builder call: subruleFunctions.rangeOfMatch,
					subrange,
					[builder add: [lengthOfMatch parameterAtIndex: 0], [builder get: length]],
					[lengthOfMatch parameterAtIndex: 1],
				nil] then: subruleFoundBlock else: notFoundBlock];
			}
			
			[builder positionAtEndOfBlock: subruleFoundBlock]; {
				// length = NSMaxRange(subrange) - initial;
				[builder set: length, [builder subtract: [builder add: [builder getElement: subrange atIndex: 0], [builder getElement: subrange atIndex: 1]], [lengthOfMatch parameterAtIndex: 0]]];
			}
			
			i++;
		}
		
		[builder jumpToBlock: returnLengthBlock];
		
		[builder positionAtEndOfBlock: notFoundBlock]; {
			[builder set: length, [context constantUnsignedInteger: NSNotFound]];
			[builder jumpToBlock: returnLengthBlock];
		}
		
		[builder positionAtEndOfBlock: returnLengthBlock]; {
			[builder call: popMatchContext, [lengthOfMatch parameterAtIndex: 1], [builder notEqual: [builder get: length], [context constantUnsignedInteger: NSNotFound]], nil];
			[builder return: [builder get: length]];
		}
	}
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveLiteralConcatenationRule:(HammerLiteralConcatenationRuleRef)rule withVisitedSubrule:(HammerBuiltRuleFunctions *)subrule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction
		*getAttemptsIgnorableRule = [module declareExternalFunctionWithName: @"HammerParserGetAttemptsIgnorableRule" type: [LLVMType functionType: context.int1Type, context.untypedPointerType, nil]],
		*setAttemptsIgnorableRule = [module declareExternalFunctionWithName: @"HammerParserSetAttemptsIgnorableRule" type: [LLVMType functionType: context.voidType, context.untypedPointerType, context.int1Type, nil]];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfBlock: lengthOfMatch.entryBlock];
		
		LLVMValue
			*attemptsIgnorableRule = [builder allocateLocal: @"attemptsIgnorableRule" type: context.int1Type],
			*length = [builder allocateLocal: @"length" type: context.integerType];
		
		[builder set: attemptsIgnorableRule, [builder call: getAttemptsIgnorableRule, [lengthOfMatch parameterAtIndex: 1], nil]];
		
		[builder call: setAttemptsIgnorableRule, [lengthOfMatch parameterAtIndex: 1], [context constantNullOfType: context.int1Type], nil];
		
		[builder set: length, [builder call: subrule.lengthOfMatch, [lengthOfMatch parameterAtIndex: 0], [lengthOfMatch parameterAtIndex: 1], nil]];
		
		[builder call: setAttemptsIgnorableRule, [lengthOfMatch parameterAtIndex: 1], [builder get: attemptsIgnorableRule], nil];
		
		[builder return: [builder get: length]];
	}
	
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveLiteralRule:(HammerLiteralRuleRef)rule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction *stringContainsStringAtIndexFunction = [module declareExternalFunctionWithName: @"HammerLiteralRuleStringContainsStringAtIndex" type: [LLVMType functionType: context.int1Type, context.untypedPointerType, context.untypedPointerType, context.integerType, nil]];
	LLVMFunction *parserGetInputLengthFunction = [module declareExternalFunctionWithName: @"HammerParserGetInputLength" type: [LLVMType functionType: context.integerType, context.untypedPointerType, nil]];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfFunction: lengthOfMatch];
		
		[builder return: [builder condition: [builder and:
				[builder unsignedLessOrEqual: [builder add: [lengthOfMatch parameterAtIndex: 0], [context constantUnsignedInteger: HammerLiteralRuleGetLiteral(rule).length]], [builder call: parserGetInputLengthFunction, [lengthOfMatch parameterAtIndex: 1], nil]],
				[builder call: stringContainsStringAtIndexFunction,
					[builder call: [self parserGetInputStringFunction], [lengthOfMatch parameterAtIndex: 1], nil],
					[context constantUntypedPointer: HammerLiteralRuleGetLiteral(rule)],
					[lengthOfMatch parameterAtIndex: 0],
				nil]
			]
			then: [context constantUnsignedInteger: HammerLiteralRuleGetLiteral(rule).length]
			else: [context constantUnsignedInteger: NSNotFound]
		]];
	}
	
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveLookaheadRule:(HammerLookaheadRuleRef)rule withVisitedSubrule:(HammerBuiltRuleFunctions *)subrule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfFunction: lengthOfMatch];
		
		[builder return: [builder condition: [builder notEqual: [builder call: subrule.lengthOfMatch, [lengthOfMatch parameterAtIndex: 0], [lengthOfMatch parameterAtIndex: 1], nil], [context constantUnsignedInteger: NSNotFound]]
			then: [context constantUnsignedInteger: HammerLookaheadRuleGetNegative(rule)? NSNotFound : 0]
			else: [context constantUnsignedInteger: HammerLookaheadRuleGetNegative(rule)? 0 : NSNotFound]
		]];
	}
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveNamedRule:(HammerNamedRuleRef)rule withVisitedSubrule:(HammerBuiltRuleFunctions *)subrule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction
		*pushMatchContext = [module declareExternalFunctionWithName: @"HammerParserPushMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], nil]],
		*popMatchContext = [module declareExternalFunctionWithName: @"HammerParserPopAndNestMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], context.int1Type, [module typeNamed: @"HammerRule"], [module typeNamed: @"NSString"], [module typeNamed: @"NSRange"], nil]];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfFunction: lengthOfMatch];
		
		[builder call: pushMatchContext, [lengthOfMatch parameterAtIndex: 1], nil];
		
		LLVMValue
			*length = [builder allocateLocal: @"length" type: [module typeNamed: @"NSUInteger"]],
			*range = [builder allocateLocal: @"range" type: [module typeNamed: @"NSRange"]];
		
		[builder set: length, [builder call: subrule.lengthOfMatch, [lengthOfMatch parameterAtIndex: 0], [lengthOfMatch parameterAtIndex: 1], nil]];
		[builder setElements: range, [lengthOfMatch parameterAtIndex: 0], [builder get: length], nil];
		
		[builder call: popMatchContext,
			[lengthOfMatch parameterAtIndex: 1],
			[builder notEqual: [builder get: length], [context constantUnsignedInteger: NSNotFound]],
			[context constantUntypedPointer: rule],
			[context constantUntypedPointer: HammerNamedRuleGetName(rule)],
			[builder get: range],
		nil];
		
		[builder return: [builder get: length]];
	}
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveReferenceRule:(HammerReferenceRuleRef)rule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction
		*lengthOfMatchFunctionForReference = [module declareExternalFunctionWithName: @"HammerCompiledRuleLengthOfMatchFunctionForReference" type: [LLVMType functionType: [LLVMType pointerTypeToType: [module typeNamed: @"HammerRuleLengthOfMatchFunction"]], [module typeNamed: @"HammerParser"], [module typeNamed: @"NSString"], nil]],
		*pushMatchContext = [module declareExternalFunctionWithName: @"HammerParserPushMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], nil]],
		*popMatchContext = [module declareExternalFunctionWithName: @"HammerParserPopAndNestMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], context.int1Type, [module typeNamed: @"HammerRule"], [module typeNamed: @"NSString"], [module typeNamed: @"NSRange"], nil]];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfFunction: lengthOfMatch];
		
		[builder call: pushMatchContext, [lengthOfMatch parameterAtIndex: 1], nil];
		
		LLVMFunction *subruleLengthOfMatch = (LLVMFunction *)[builder call: lengthOfMatchFunctionForReference, [lengthOfMatch parameterAtIndex: 1], [context constantUntypedPointer: HammerReferenceRuleGetReference(rule)], nil];
		
		LLVMValue
			*length = [builder allocateLocal: @"length" type: [module typeNamed: @"NSUInteger"]],
			*range = [builder allocateLocal: @"range" type: [module typeNamed: @"NSRange"]];
			
		[builder set: length, [builder call: subruleLengthOfMatch, [lengthOfMatch parameterAtIndex: 0], [lengthOfMatch parameterAtIndex: 1], nil]];
		[builder setElements: range, [lengthOfMatch parameterAtIndex: 0], [builder get: length], nil];
		
		[builder call: popMatchContext,
			[lengthOfMatch parameterAtIndex: 1],
			[builder notEqual: [builder get: length], [context constantUnsignedInteger: NSNotFound]],
			[context constantUntypedPointer: rule],
			[context constantUntypedPointer: HammerReferenceRuleGetReference(rule)],
			[builder get: range],
		nil];
		
		[builder return: [builder get: length]];
	}
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}


-(void)leaveRepetitionRule:(HammerRepetitionRuleRef)rule withVisitedSubrule:(HammerBuiltRuleFunctions *)subrule {
	NSString *name = [self nameForRule: rule];
	
	LLVMFunction
		*pushMatchContext = [module declareExternalFunctionWithName: @"HammerParserPushMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], nil]],
		*popMatchContext = [module declareExternalFunctionWithName: @"HammerParserPopAndPassUpMatchContext" type: [LLVMType functionType: context.voidType, [module typeNamed: @"HammerParser"], context.int1Type, nil]];
	
	LLVMFunction *lengthOfMatch = [module functionWithName: name];
	if(!lengthOfMatch) {
		lengthOfMatch = [module functionWithName: name typeName: @"HammerRuleLengthOfMatchFunction"];
		[builder positionAtEndOfFunction: lengthOfMatch];
		
		[builder call: pushMatchContext, [lengthOfMatch parameterAtIndex: 1], nil];
		
		LLVMValue
			*length = [builder allocateLocal: @"length" type: [module typeNamed: @"NSUInteger"]],
			*count = [builder allocateLocal: @"count" type: context.int64Type],
			*subrange = [builder allocateLocal: @"subrange" type: [module typeNamed: @"NSRange"]];
		
		[builder set: length, [context constantUnsignedInteger: 0]];
		[builder set: count, [context constantUnsignedInt64: 0]];
		
		LLVMBlock
			*loopBlock = [lengthOfMatch appendBlockWithName: @"loop"],
			*subruleTestBlock = [lengthOfMatch appendBlockWithName: @"subrule test"],
			*subruleMatchedBlock = [lengthOfMatch appendBlockWithName: @"subrule matched"],
			*returnBlock = [lengthOfMatch appendBlockWithName: @"return"];
		
		LLVMValue
			*unbounded = [context constantUnsignedInt64: HammerRepetitionRuleUnboundedMaximum],
			*maximum = [context constantUnsignedInt64: HammerRepetitionRuleGetMaximum(rule)],
			*minimum = [context constantUnsignedInt64: HammerRepetitionRuleGetMinimum(rule)];
		
		[builder jumpToBlock: loopBlock];
		
		[builder positionAtEndOfBlock: loopBlock]; {
			[builder if: [builder or: [builder equal: maximum, unbounded], [builder unsignedLessThan: [builder get: count], maximum]] then: subruleTestBlock else: returnBlock];
		}
		
		[builder positionAtEndOfBlock: subruleTestBlock]; {
			[builder set: count, [builder add: [builder get: count], [context constantUnsignedInt64: 1]]];
			
			[builder if: [builder call: subrule.rangeOfMatch, subrange, [builder add: [lengthOfMatch parameterAtIndex: 0], [builder get: length]], [lengthOfMatch parameterAtIndex: 1], nil] then: subruleMatchedBlock else: returnBlock];
		}
		
		[builder positionAtEndOfBlock: subruleMatchedBlock]; {
			[builder set: length, [builder subtract: [builder add: [builder getElement: subrange atIndex: 0], [builder getElement: subrange atIndex: 1]], [lengthOfMatch parameterAtIndex: 0]]];
			
			[builder jumpToBlock: loopBlock];
		}
		
		[builder positionAtEndOfBlock: returnBlock]; {
			[builder set: length, [builder condition: (
					(HammerRepetitionRuleGetMaximum(rule) == HammerRepetitionRuleUnboundedMaximum)
					?	[builder unsignedLessThan: minimum, [builder get: count]]
					:	[builder and: [builder unsignedLessThan: minimum, [builder get: count]], [builder unsignedLessOrEqual: [builder get: count], maximum]]
				)
				then: [builder get: length]
				else: [context constantUnsignedInteger: NSNotFound]
			]];
			
			[builder call: popMatchContext, [lengthOfMatch parameterAtIndex: 1], [builder notEqual: [builder get: length], [context constantUnsignedInteger: NSNotFound]], nil];
			
			[builder return: [builder get: length]];
		}
	}
	
	[self addBuiltFunctions: [self defaultFunctionsForRule: rule withLengthOfMatchFunction: lengthOfMatch]];
}

@end
