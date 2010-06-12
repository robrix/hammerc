// HammerCompiledLiteralConcatenationRuleTests.m
// Created by Rob Rix on 2010-01-01
// Copyright 2010 Monochrome Industries

#import "HammerLiteralConcatenationRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledLiteralConcatenationRuleTests : HammerLiteralConcatenationRuleTests
@end

@implementation HammerCompiledLiteralConcatenationRuleTests

-(HammerRuleRef)rule {
	return [[HammerRuleCompiler compiler] compileRule: super.rule];
}

@end