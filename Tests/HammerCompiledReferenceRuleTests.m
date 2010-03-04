// HammerCompiledReferenceRuleTests.m
// Created by Rob Rix on 2010-01-30
// Copyright 2010 Monochrome Industries

#import "HammerCharacterRule.h"
#import "HammerConcatenationRule.h"
#import "HammerReferenceRule.h"
#import "HammerReferenceRuleTests.h"
#import "HammerRuleCompiler.h"
#import "HammerTestParser.h"

@interface HammerCompiledReferenceRuleTests : HammerReferenceRuleTests
@end

@implementation HammerCompiledReferenceRuleTests

-(HammerRule *)rule {
	return [[[[HammerRuleCompiler alloc] init] autorelease] compileRule: super.rule];
}

-(void)setUp {
	[super setUp];
	HammerRuleCompiler *compiler = [[HammerRuleCompiler alloc] init];
	parser.rules = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[compiler compileRule: [HammerCharacterRule rule]], @"any",
		[compiler compileRule: [HammerConcatenationRule ruleWithSubrules: [NSArray arrayWithObjects: [HammerReferenceRule ruleWithReference: @"any"], [HammerReferenceRule ruleWithReference: @"any"], nil]]], @"anyTwo",
	nil];
	[compiler release];
}

@end