// HammerRule.h
// Created by Rob Rix on 2007-12-14
// Copyright 2007 Monochrome Industries

#import <Foundation/Foundation.h>

@class HammerParser, HammerRule;

@protocol HammerRuleVisitor

-(void)visitRule:(HammerRule *)rule;
-(void)leaveRule:(HammerRule *)rule;

@end


@interface HammerRule : NSObject <NSCopying, NSCoding> // NSCoding is a subclass responsibility

-(BOOL)parseWithParser:(HammerParser *)parser;

-(NSUInteger)lengthOfMatchFromCursor:(NSUInteger)initial withParser:(HammerParser *)parser; // subclass responsibility
-(BOOL)range:(NSRange *)outrange ofMatchFromCursor:(NSUInteger)initial withParser:(HammerParser *)parser;

// calls -visitRule: and -leaveRule: on the visitor, passing self as the argument. Subclasses also call -acceptVisitor: on their subrules as appropriate.
-(void)acceptVisitor:(id<HammerRuleVisitor>)visitor;

@end
