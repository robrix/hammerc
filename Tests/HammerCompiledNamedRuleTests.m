// HammerCompiledNamedRuleTests.m
// Created by Rob Rix on 2010-01-06
// Copyright 2010 Monochrome Industries

#import "HammerNamedRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledNamedRuleTests : HammerNamedRuleTests
@end

@implementation HammerCompiledNamedRuleTests

-(HammerRuleRef)rule {
	return [[HammerRuleCompiler compiler] compileRule: super.rule];
}

@end