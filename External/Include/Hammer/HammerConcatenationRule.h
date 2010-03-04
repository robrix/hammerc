// HammerConcatenationRule.h
// Created by Rob Rix on 2007-12-14
// Copyright 2007 Monochrome Industries

#import <Hammer/HammerRule.h>

@interface HammerConcatenationRule : HammerRule {
	NSArray *subrules;
}

+(id)ruleWithSubrules:(NSArray *)sub;
-(id)initWithSubrules:(NSArray *)sub;

@property (nonatomic, readonly) NSArray *subrules;

@end
