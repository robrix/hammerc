// HammerCompiledLookaheadRuleTests.m
// Created by Rob Rix on 2010-01-02
// Copyright 2010 Monochrome Industries

#import "HammerLookaheadRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledLookaheadRuleTests : HammerLookaheadRuleTests
@end

@implementation HammerCompiledLookaheadRuleTests

-(HammerLookaheadRuleRef)positiveRule {
	return [[HammerRuleCompiler compiler] compileRule: super.positiveRule];
}

-(HammerLookaheadRuleRef)negativeRule {
	return [[HammerRuleCompiler compiler] compileRule: super.negativeRule];
}

@end