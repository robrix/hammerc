// HammerCompiledReferenceRuleTests.m
// Created by Rob Rix on 2010-01-30
// Copyright 2010 Monochrome Industries

#import "HammerCharacterRule.h"
#import "HammerConcatenationRule.h"
#import "HammerReferenceRule.h"
#import "HammerReferenceRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledReferenceRuleTests : HammerReferenceRuleTests
@end

@implementation HammerCompiledReferenceRuleTests

-(HammerRuleRef)rule {
	return [[HammerRuleCompiler compiler] compileRule: super.rule];
}

-(void)setUp {
	[super setUp];
	HammerRuleCompiler *compiler = [[HammerRuleCompiler alloc] init];
	state.ruleGraph = (HammerRuleGraphRef)RXDictionary(
		[compiler compileRule: HammerCharacterRuleCreate()], @"any",
		[compiler compileRule: HammerConcatenationRuleCreate(RXArray(HammerReferenceRuleCreate(@"any"), HammerReferenceRuleCreate(@"any"), NULL))], @"anyTwo",
	NULL);
}

@end