// HammerCompiledLookaheadRuleTests.m
// Created by Rob Rix on 2010-01-02
// Copyright 2010 Monochrome Industries

#import "HammerLookaheadRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledLookaheadRuleTests : HammerLookaheadRuleTests
@end

@implementation HammerCompiledLookaheadRuleTests

-(HammerRule *)positiveRule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.positiveRule];
}

-(HammerRule *)negativeRule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.negativeRule];
}

@end