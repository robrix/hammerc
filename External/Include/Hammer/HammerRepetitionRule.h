// HammerRepetitionRule.h
// Created by Rob Rix on 2007-12-15
// Copyright 2007 Monochrome Industries

#import <Hammer/HammerContainerRule.h>

#define HammerRepetitionRuleUnboundedMaximum ((uint64_t)UINT64_MAX)

@interface HammerRepetitionRule : HammerContainerRule {
	uint64_t minimum, maximum;
}

+(id)ruleWithOptionalSubrule:(HammerRule *)_subrule;
+(id)ruleWithOptionallyRepeatedSubrule:(HammerRule *)_subrule;
+(id)ruleWithRepeatedSubrule:(HammerRule *)_subrule;

// a maximum of HammerRepetitionRuleUnboundedMaximum means no upper bound
+(id)ruleWithSubrule:(HammerRule *)sub minimum:(uint64_t)min maximum:(uint64_t)max;
+(id)ruleWithSubrule:(HammerRule *)sub minimum:(uint64_t)min;
-(id)initWithSubrule:(HammerRule *)sub minimum:(uint64_t)min maximum:(uint64_t)max;
-(id)initWithSubrule:(HammerRule *)sub minimum:(uint64_t)min;

@property (nonatomic, readonly) uint64_t minimum;
@property (nonatomic, readonly) uint64_t maximum;

@end
