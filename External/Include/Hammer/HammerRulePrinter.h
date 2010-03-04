// HammerRulePrinter.h
// Created by Rob Rix on 2009-12-10
// Copyright 2009 Monochrome Industries

#import <Foundation/Foundation.h>

@protocol HammerRule;

@interface HammerRulePrinter : NSObject {
	NSMutableArray *ruleStringStack;
}

-(NSString *)printRule:(HammerRule *)rule;

@end