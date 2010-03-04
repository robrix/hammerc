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

-(void)tearDown {
	[compiler release];
}

// rule functionality is tested in HammerCompiled*RuleTests suites

-(void)testCompilesCharacterRules {
	HammerRule *compiledRule = [compiler compileRule: [HammerCharacterRule rule]];
	RXAssertNotNil(compiledRule);
}

-(void)testCompilesLiteralRules {
	HammerRule *compiledRule = [compiler compileRule: [HammerLiteralRule ruleWithLiteral: @"literal"]];
	RXAssertNotNil(compiledRule);
}

@end