// HammerCompiledCharacterSetRuleTests.m
// Created by Rob Rix on 2009-12-30
// Copyright 2009 Monochrome Industries

#import "HammerCharacterSetRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledCharacterSetRuleTests : HammerCharacterSetRuleTests
@end

@implementation HammerCompiledCharacterSetRuleTests

-(HammerRuleRef)rule {
	return [[HammerRuleCompiler compiler] compileRule: super.rule];
}

@end