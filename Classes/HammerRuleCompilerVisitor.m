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


-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForRule:(HammerRuleRef)rule {
	return [compiler performSelector: NSSelectorFromString([NSString stringWithFormat: @"lengthOfMatchDefinitionFor%@:", (NSString *)HammerRuleGetShortTypeName(rule)]) withObject: rule];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForRule:(HammerRuleRef)rule withVisitedSubrule:(ARXFunction *)subrule {
	return [compiler performSelector: NSSelectorFromString([NSString stringWithFormat: @"lengthOfMatchDefinitionFor%@:withVisitedSubrule:", (NSString *)HammerRuleGetShortTypeName(rule), subrule]) withObject: rule withObject: subrule];
}

-(ARXModuleFunctionDefinitionBlock)lengthOfMatchDefinitionForRule:(HammerRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	return [compiler performSelector: NSSelectorFromString([NSString stringWithFormat: @"lengthOfMatchDefinitionFor%@:withVisitedSubrules:", (NSString *)HammerRuleGetShortTypeName(rule), subrules]) withObject: rule withObject: subrules];
}


-(ARXModuleFunctionDefinitionBlock)rangeOfMatchDefinitionForRule:(HammerRuleRef)rule withLengthOfMatchFunction:(ARXFunction *)lengthOfMatch {
	SEL selector = NSSelectorFromString([NSString stringWithFormat: @"rangeOfMatchDefinitionFor%@:withLengthOfMatchFunction:", (NSString *)HammerRuleGetShortTypeName(rule)]);
	return [compiler respondsToSelector: selector]
	?	(ARXModuleFunctionDefinitionBlock)[compiler performSelector: selector withObject: rule withObject: lengthOfMatch]
	:	[compiler rangeOfMatchSkippingIgnorableCharactersDefinitionForRule: rule withLengthOfMatchFunction: lengthOfMatch];
}


-(id)leaveRule:(HammerRuleRef)rule {
	HammerBuiltRuleFunctions *functions = [[HammerBuiltRuleFunctions alloc] init];
	functions.lengthOfMatch = [self lengthOfMatchFunctionForRule: rule withDefinition: [self lengthOfMatchDefinitionForRule: rule]];
	functions.rangeOfMatch = [self rangeOfMatchFunctionForRule: rule withDefinition: [self rangeOfMatchDefinitionForRule: rule withLengthOfMatchFunction: functions.lengthOfMatch]];
	return functions;
}

-(id)leaveRule:(HammerRuleRef)rule withVisitedSubrule:(id)subrule {
	HammerBuiltRuleFunctions *functions = [[HammerBuiltRuleFunctions alloc] init];
	functions.lengthOfMatch = [self lengthOfMatchFunctionForRule: rule withDefinition: [self lengthOfMatchDefinitionForRule: rule withVisitedSubrule: subrule]];
	functions.rangeOfMatch = [self rangeOfMatchFunctionForRule: rule withDefinition: [self rangeOfMatchDefinitionForRule: rule withLengthOfMatchFunction: functions.lengthOfMatch]];
	return functions;
}

-(id)leaveRule:(HammerRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	HammerBuiltRuleFunctions *functions = [[HammerBuiltRuleFunctions alloc] init];
	functions.lengthOfMatch = [self lengthOfMatchFunctionForRule: rule withDefinition: [self lengthOfMatchDefinitionForRule: rule withVisitedSubrules: subrules]];
	functions.rangeOfMatch = [self rangeOfMatchFunctionForRule: rule withDefinition: [self rangeOfMatchDefinitionForRule: rule withLengthOfMatchFunction: functions.lengthOfMatch]];
	return functions;
}

@end
