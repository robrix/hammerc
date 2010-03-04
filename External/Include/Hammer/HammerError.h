// HammerError.h
// Created by Rob Rix on 2009-09-27
// Copyright 2009 Monochrome Industries

#import <Foundation/Foundation.h>

extern NSString * const HammerErrorDomain;

enum {
	HammerParserParseFailedError = -1,
	HammerAlternationRuleNoAlternativeErrorCode = -2
};
typedef NSInteger HammerErrorCode;

@class HammerAlternationRule, HammerParser;

@interface HammerError : NSError

+(id)parseFailedErrorInRange:(NSRange)range ofGrammar:(NSString *)grammar resultingParser:(HammerParser *)parser;
+(id)noMatchingAlternativeErrorAtIndex:(NSUInteger)index withAlternationRule:(HammerAlternationRule *)rule;

@end