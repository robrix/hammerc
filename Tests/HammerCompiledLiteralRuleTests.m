// HammerCompiledLiteralRuleTests.m
// Created by Rob Rix on 2009-12-29
// Copyright 2009 Monochrome Industries

#import "HammerLiteralRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledLiteralRuleTests : HammerLiteralRuleTests
@end

@implementation HammerCompiledLiteralRuleTests

-(HammerRuleRef)rule {
	return [[HammerRuleCompiler compiler] compileRule: super.rule];
}

@end