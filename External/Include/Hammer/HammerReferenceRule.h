// HammerReferenceRule.h
// Created by Rob Rix on 2007-12-17
// Copyright 2007 Monochrome Industries

#import <Hammer/HammerRule.h>

@interface HammerReferenceRule : HammerRule {
	NSString *reference;
}

+(id)ruleWithReference:(NSString *)k;
-(id)initWithReference:(NSString *)k;

@property (nonatomic, readonly) NSString *reference;

// returns the referenced rule in the passed parser, throws an exception if it doesn’t exist
-(HammerRule *)ruleWithParser:(HammerParser *)parser;

@end
