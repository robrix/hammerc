// HammerCompiledCharacterSetRuleTests.m
// Created by Rob Rix on 2009-12-30
// Copyright 2009 Monochrome Industries

#import "HammerCharacterSetRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledCharacterSetRuleTests : HammerCharacterSetRuleTests
@end

@implementation HammerCompiledCharacterSetRuleTests

-(HammerRule *)rule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.rule];
}

@end