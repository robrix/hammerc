// HammerRuleCompilerVisitor.m
// Created by Rob Rix on 2010-06-12
// Copyright 2010 Monochrome Industries

#import "HammerCompiledRule.h"
#import "HammerRuleCompiler.h"
#import "HammerRuleCompilerVisitor.h"

@implementation HammerRuleCompilerVisitor

-(id)initWithCompiler:(HammerRuleCompiler *)_compiler {
	if(self = [super init]) {
		compiler = _compiler;
	}
	return self;
}


-(void)visitRule:(HammerRuleRef)rule {}


-(NSString *)nameForFunction:(NSString *)function forRule:(HammerRuleRef)rule {
	return [NSString stringWithFormat: @"%@ %@", [compiler nameForRule: rule], function];
}


-(id)lengthOfMatchFunctionForRule:(HammerRuleRef)rule withDefinition:(ARXModuleFunctionDefinitionBlock)definition {
	return [compiler.module functionWithName: [self nameForFunction: @"lengthOfMatch" forRule: rule] type: [compiler.module typeNamed: @"lengthOfMatch"] definition: definition];
}

-(id)rangeOfMatchFunctionForRule:(HammerRuleRef)rule withDefinition:(ARXModuleFunctionDefinitionBlock)definition {
	return [compiler.module functionWithName: [self nameForFunction: @"rangeOfMatch" forRule: rule] type: [compiler.module typeNamed: @"rangeOfMatch"] definition: definition];
}


-(id)leaveRule:(HammerRuleRef)rule {
	SEL selector = NSSelectorFromString([NSString stringWithFormat: @"rangeOfMatchDefinitionFor%@:", (NSString *)HammerRuleGetShortTypeName(rule)]);
	HammerBuiltRuleFunctions *functions = [[HammerBuiltRuleFunctions alloc] init];
	functions.lengthOfMatch = [self lengthOfMatchFunctionForRule: rule withDefinition: [compiler lengthOfMatchDefinitionForRule: rule]];
	functions.rangeOfMatch = [self rangeOfMatchFunctionForRule: rule withDefinition: [compiler respondsToSelector: selector]
	?	[compiler performSelector: selector withObject: rule]
	:	[compiler rangeOfMatchSkippingIgnorableCharactersDefinitionForRule: rule withLengthOfMatchFunction: functions.lengthOfMatch]];
	return functions;
}

-(id)leaveRule:(HammerRuleRef)rule withVisitedSubrule:(id)subrule {
	SEL selector = NSSelectorFromString([NSString stringWithFormat: @"rangeOfMatchDefinitionFor%@:withVisitedSubrule:", (NSString *)HammerRuleGetShortTypeName(rule)]);
	HammerBuiltRuleFunctions *functions = [[HammerBuiltRuleFunctions alloc] init];
	functions.lengthOfMatch = [self lengthOfMatchFunctionForRule: rule withDefinition: [compiler lengthOfMatchDefinitionForRule: rule withVisitedSubrule: subrule]];
	functions.rangeOfMatch = [self rangeOfMatchFunctionForRule: rule withDefinition: [compiler respondsToSelector: selector]
	?	[compiler performSelector: selector withObject: rule withObject: subrule]
	:	[compiler rangeOfMatchSkippingIgnorableCharactersDefinitionForRule: rule withLengthOfMatchFunction: functions.lengthOfMatch]];
	return functions;
}

-(id)leaveRule:(HammerRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	SEL selector = NSSelectorFromString([NSString stringWithFormat: @"rangeOfMatchDefinitionFor%@:withVisitedSubrules:", (NSString *)HammerRuleGetShortTypeName(rule)]);
	HammerBuiltRuleFunctions *functions = [[HammerBuiltRuleFunctions alloc] init];
	functions.lengthOfMatch = [self lengthOfMatchFunctionForRule: rule withDefinition: [compiler lengthOfMatchDefinitionForRule: rule withVisitedSubrules: subrules]];
	functions.rangeOfMatch = [self rangeOfMatchFunctionForRule: rule withDefinition: [compiler respondsToSelector: selector]
	?	[compiler performSelector: selector withObject: rule withObject: subrules]
	:	[compiler rangeOfMatchSkippingIgnorableCharactersDefinitionForRule: rule withLengthOfMatchFunction: functions.lengthOfMatch]];
	return functions;
}

@end
