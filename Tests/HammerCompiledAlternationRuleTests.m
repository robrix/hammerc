// HammerCompiledAlternationRuleTests.m
// Created by Rob Rix on 2010-01-05
// Copyright 2010 Monochrome Industries

#import "HammerAlternationRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledAlternationRuleTests : HammerAlternationRuleTests
@end

@implementation HammerCompiledAlternationRuleTests

-(HammerRuleRef)rule {
	return [[HammerRuleCompiler compiler] compileRule: super.rule];
}

@end