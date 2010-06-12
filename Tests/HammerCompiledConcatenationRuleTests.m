// HammerCompiledConcatenationRuleTests.m
// Created by Rob Rix on 2010-01-04
// Copyright 2010 Monochrome Industries

#import "HammerConcatenationRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledConcatenationRuleTests : HammerConcatenationRuleTests
@end

@implementation HammerCompiledConcatenationRuleTests

-(HammerRuleRef)rule {
	return [[HammerRuleCompiler compiler] compileRule: super.rule];
}

@end