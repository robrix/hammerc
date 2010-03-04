// HammerLookaheadRule.h
// Created by Rob Rix on 2008-03-31
// Copyright 2008 Monochrome Industries

#import <Hammer/HammerContainerRule.h>

@interface HammerLookaheadRule : HammerContainerRule {
	BOOL shouldNegate;
}

+(id)ruleWithSubrule:(HammerRule *)sub negate:(BOOL)neg;
-(id)initWithSubrule:(HammerRule *)sub negate:(BOOL)neg;

@property (nonatomic, readonly) BOOL shouldNegate;

@end
