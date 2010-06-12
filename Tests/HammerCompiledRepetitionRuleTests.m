// HammerCompiledRepetitionRuleTests.m
// Created by Rob Rix on 2010-02-01
// Copyright 2010 Monochrome Industries

#import "HammerRepetitionRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledRepetitionRuleTests : HammerRepetitionRuleTests
@end

@implementation HammerCompiledRepetitionRuleTests

-(HammerRepetitionRuleRef)optionalRule {
	return [[HammerRuleCompiler compiler] compileRule: super.optionalRule];
}

-(HammerRepetitionRuleRef)optionallyRepeatedRule {
	return [[HammerRuleCompiler compiler] compileRule: super.optionallyRepeatedRule];
}

-(HammerRepetitionRuleRef)repeatedRule {
	return [[HammerRuleCompiler compiler] compileRule: super.repeatedRule];
}

@end
