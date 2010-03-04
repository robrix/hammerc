// HammerCompiledLiteralRuleTests.m
// Created by Rob Rix on 2009-12-29
// Copyright 2009 Monochrome Industries

#import "HammerLiteralRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledLiteralRuleTests : HammerLiteralRuleTests
@end

@implementation HammerCompiledLiteralRuleTests

-(HammerRule *)rule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.rule];
}

@end