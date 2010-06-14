// HammerBlockRuleVisitor.m
// Created by Rob Rix on 2010-06-14
// Copyright 2010 Monochrome Industries

#import "HammerBlockRuleVisitor.h"

@interface HammerBlockRuleVisitor () <HammerRuleVisitor>
@end


@implementation HammerBlockRuleVisitor

-(void)visitRule:(HammerRuleRef)rule withVisitBlock:(HammerBlockRuleVisitorVisitBlock)block {
	visit = block;
	HammerRuleAcceptVisitor(rule, self);
	visit = NULL;
}


-(void)visitRule:(HammerRuleRef)rule {
	if(visit) {
		visit(rule, (NSString *)HammerRuleGetShortTypeName(rule));
	}
}


-(id)leaveRule:(HammerRuleRef)rule {
	return leave
	?	leave(rule, (NSString *)HammerRuleGetShortTypeName(rule))
	:	rule;
}

-(id)leaveRule:(HammerRuleRef)rule withVisitedSubrule:(id)subrule {
	return leaveUnary
	?	leaveUnary(rule, subrule, (NSString *)HammerRuleGetShortTypeName(rule))
	:	rule;
}

-(id)leaveRule:(HammerRuleRef)rule withVisitedSubrules:(NSArray *)subrules {
	return leaveNAry
	?	leaveNAry(rule, subrules, (NSString *)HammerRuleGetShortTypeName(rule))
	:	rule;
}

@end
