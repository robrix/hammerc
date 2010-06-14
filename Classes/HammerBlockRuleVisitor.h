// HammerBlockRuleVisitor.h
// Created by Rob Rix on 2010-06-14
// Copyright 2010 Monochrome Industries

#import <Foundation/Foundation.h>

typedef void (^HammerBlockRuleVisitorVisitBlock)(HammerRuleRef rule, NSString *shortName);
typedef id (^HammerBlockRuleVisitorNullaryLeaveBlock)(HammerRuleRef rule, NSString *shortName);
typedef id (^HammerBlockRuleVisitorUnaryLeaveBlock)(HammerRuleRef rule, id subrule, NSString *shortName);
typedef id (^HammerBlockRuleVisitorNAryLeaveBlock)(HammerRuleRef rule, NSArray *subrules, NSString *shortName);

@interface HammerBlockRuleVisitor : NSObject {
	HammerBlockRuleVisitorVisitBlock visit;
	HammerBlockRuleVisitorNullaryLeaveBlock leave;
	HammerBlockRuleVisitorUnaryLeaveBlock leaveUnary;
	HammerBlockRuleVisitorNAryLeaveBlock leaveNAry;
}

-(void)visitRule:(HammerRuleRef)rule withVisitBlock:(HammerBlockRuleVisitorVisitBlock)block;

@end
