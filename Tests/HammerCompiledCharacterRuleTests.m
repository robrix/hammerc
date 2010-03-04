// HammerCompiledCharacterRuleTests.m
// Created by Rob Rix on 2009-12-28
// Copyright 2009 Monochrome Industries

#import "HammerCharacterRuleTests.h"
#import "HammerRuleCompiler.h"

@interface HammerCompiledCharacterRuleTests : HammerCharacterRuleTests
@end

@implementation HammerCompiledCharacterRuleTests

-(HammerRule *)rule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.rule];
}

@end