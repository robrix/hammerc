// HammerCompiledRepetitionRuleTests.m
// Created by Rob Rix on 2010-02-01
// Copyright 2010 Monochrome Industries

#import "HammerRepetitionRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledRepetitionRuleTests : HammerRepetitionRuleTests
@end

@implementation HammerCompiledRepetitionRuleTests

-(HammerRule *)optionalRule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.optionalRule];
}

-(HammerRule *)optionallyRepeatedRule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.optionallyRepeatedRule];
}

-(HammerRule *)repeatedRule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.repeatedRule];
}

@end
