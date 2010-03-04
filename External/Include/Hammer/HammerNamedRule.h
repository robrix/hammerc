// HammerNamedRule.h
// Created by Rob Rix on 2008-03-31
// Copyright 2008 Monochrome Industries

#import <Hammer/HammerContainerRule.h>

@interface HammerNamedRule : HammerContainerRule {
	NSString *name;
}

+(id)ruleWithSubrule:(HammerRule *)sub name:(NSString *)name;
-(id)initWithSubrule:(HammerRule *)sub name:(NSString *)name;

@property (nonatomic, readonly) NSString *name;

@end
