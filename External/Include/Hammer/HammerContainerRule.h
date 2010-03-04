// HammerContainerRule.h
// Created by Rob Rix on 2009-12-04
// Copyright 2009 Monochrome Industries

/*
Exists to remove some duplication.
*/

#import <Hammer/HammerRule.h>

@interface HammerContainerRule : HammerRule {
	HammerRule *subrule;
}

+(id)ruleWithSubrule:(HammerRule *)_subrule;
-(id)initWithSubrule:(HammerRule *)_subrule;

@property (nonatomic, readonly) HammerRule *subrule;

@end