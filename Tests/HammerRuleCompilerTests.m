// HammerRuleCompilerTests.m
// Created by Rob Rix on 2009-12-11
// Copyright 2009 Monochrome Industries

#import "Hammer.h"
#import "HammerRuleCompiler.h"
#import "RXAssertions.h"

@interface HammerRuleCompilerTests : SenTestCase {
	HammerRuleCompiler *compiler;
}
@end

@implementation HammerRuleCompilerTests

-(void)setUp {
	compiler = [[HammerRuleCompiler alloc] init];
}

// rule functionality is tested in HammerCompiled*RuleTests suites

-(void)testCompilesCharacterRules {
	HammerRuleRef compiledRule = [compiler compileRule: HammerCharacterRuleCreate()];
	RXAssertNotNil(compiledRule);
}

-(void)testCompilesLiteralRules {
	HammerRuleRef compiledRule = [compiler compileRule: HammerLiteralRuleCreate(@"literal")];
	RXAssertNotNil(compiledRule);
}

@end