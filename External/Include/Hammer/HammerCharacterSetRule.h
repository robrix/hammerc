// HammerCharacterSetRule.h
// Created by Rob Rix on 2007-12-15
// Copyright 2007 Monochrome Industries

#import <Hammer/HammerRule.h>

@interface HammerCharacterSetRule : HammerRule {
	NSCharacterSet *characterSet;
}

+(id)ruleWithCharacterSet:(NSCharacterSet *)set;
-(id)initWithCharacterSet:(NSCharacterSet *)set;

@property (nonatomic, readonly) NSCharacterSet *characterSet;

@end
