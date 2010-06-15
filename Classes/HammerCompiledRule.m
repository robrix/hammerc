// HammerCompiledRule.m
// Created by Rob Rix on 2009-12-23
// Copyright 2009 Monochrome Industries

#import "HammerCompiledRule.h"
#import "HammerRuleCompiler.h"

#import <Auspicion/Auspicion.h>

@implementation HammerBuiltRuleFunctions
@synthesize lengthOfMatch, rangeOfMatch;
@end

static struct HammerRuleType HammerCompiledRuleType;

typedef struct HammerCompiledRule {
	RX_FIELDS_FROM(HammerRule, HammerRuleType);
	
	__strong HammerRuleRef sourceRule;
	HammerCompiledRuleLengthOfMatchFunction lengthOfMatch;
	HammerCompiledRuleRangeOfMatchFunction rangeOfMatch;
} HammerCompiledRule;

HammerCompiledRuleRef HammerCompiledRuleCreate(HammerRuleRef sourceRule, HammerCompiledRuleLengthOfMatchFunction lengthOfMatch, HammerCompiledRuleRangeOfMatchFunction rangeOfMatch) {
	HammerCompiledRuleRef self = RXCreate(sizeof(HammerCompiledRule), &HammerCompiledRuleType);
	self->sourceRule = HammerRuleRetain(sourceRule);
	self->lengthOfMatch = lengthOfMatch;
	self->rangeOfMatch = rangeOfMatch;
	return self;
}

void HammerCompiledRuleDeallocate(HammerCompiledRuleRef self) {
	HammerRuleRelease(self->sourceRule);
}


bool HammerCompiledRuleIsEqual(HammerCompiledRuleRef self, HammerCompiledRuleRef other) {
	return
		(RXGetType(self) == RXGetType(other))
	&&	RXEquals(self->sourceRule, other->sourceRule);
}


HammerRuleRef HammerCompiledRuleGetSourceRule(HammerCompiledRuleRef self) {
	return self->sourceRule;
}


HammerCompiledRuleLengthOfMatchFunction HammerCompiledRuleGetLengthOfMatchFunction(HammerCompiledRuleRef self) {
	return self->lengthOfMatch;
}

HammerCompiledRuleRangeOfMatchFunction HammerCompiledRuleGetRangeOfMatchFunction(HammerCompiledRuleRef self) {
	return self->rangeOfMatch;
}


HammerIndex HammerCompiledRuleLengthOfMatch(HammerCompiledRuleRef self, HammerIndex initial, HammerParserState *state) {
	return self->lengthOfMatch(initial, state);
}

HammerIndex HammerCompiledRuleRangeOfMatch(HammerCompiledRuleRef self, NSRange *outrange, HammerIndex initial, HammerParserState *state) {
	return self->rangeOfMatch(outrange, initial, state);
}


id HammerCompiledRuleAcceptVisitor(HammerCompiledRuleRef self, id<HammerRuleVisitor> visitor) {
	return HammerRuleAcceptVisitor(self->sourceRule, visitor);
}


static struct HammerRuleType HammerCompiledRuleType = {
	.name = "HammerCompiledRule",
	.deallocate = (RXDeallocateMethod)HammerCompiledRuleDeallocate,
	.isEqual = (RXIsEqualMethod)HammerCompiledRuleIsEqual,
	
	.lengthOfMatch = (HammerRuleLengthOfMatchMethod)HammerCompiledRuleLengthOfMatch,
	.rangeOfMatch = (HammerRuleRangeOfMatchMethod)HammerCompiledRuleRangeOfMatch,
	.acceptVisitor = (HammerRuleAcceptVisitorMethod)HammerCompiledRuleAcceptVisitor,
};
