// HammerLiteralRule.h
// Created by Rob Rix on 2007-12-15
// Copyright 2007 Monochrome Industries

#import <Hammer/HammerRule.h>

@interface HammerLiteralRule : HammerRule {
	NSString *literal;
}

+(id)ruleWithLiteral:(NSString *)l;
-(id)initWithLiteral:(NSString *)l;

@property (nonatomic, readonly) NSString *literal;

@end


BOOL HammerLiteralRuleStringContainsStringAtIndex(NSString *haystack, NSString *needle, NSUInteger cursor);
