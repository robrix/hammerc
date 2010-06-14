// HammerCompiledRule.h
// Created by Rob Rix on 2009-12-23
// Copyright 2009 Monochrome Industries

#import <Hammer/Hammer.h>

@class ARXCompiler, ARXFunction;

@interface HammerBuiltRuleFunctions : NSObject {
	ARXFunction *lengthOfMatch;
	ARXFunction *rangeOfMatch;
}

@property (nonatomic, retain) ARXFunction *lengthOfMatch;
@property (nonatomic, retain) ARXFunction *rangeOfMatch;

@end

typedef HammerIndex(*HammerCompiledRuleLengthOfMatchFunction)(HammerIndex, HammerParserState *);
typedef BOOL(*HammerCompiledRuleRangeOfMatchFunction)(NSRange *, HammerIndex, HammerParserState *);

typedef struct HammerCompiledRule * HammerCompiledRuleRef;

HammerCompiledRuleRef HammerCompiledRuleCreate(HammerRuleRef source, HammerCompiledRuleLengthOfMatchFunction lengthOfMatch, HammerCompiledRuleRangeOfMatchFunction rangeOfMatch);

HammerRuleRef HammerCompiledRuleGetSourceRule(HammerCompiledRuleRef self);

HammerCompiledRuleLengthOfMatchFunction HammerCompiledRuleGetLengthOfMatchFunction(HammerCompiledRuleRef self);
HammerCompiledRuleRangeOfMatchFunction HammerCompiledRuleGetRangeOfMatchFunction(HammerCompiledRuleRef self);
