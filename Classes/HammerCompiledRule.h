// HammerCompiledRule.h
// Created by Rob Rix on 2009-12-23
// Copyright 2009 Monochrome Industries

#import <Hammer/HammerRule.h>

@class LLVMCompiler, LLVMFunction;

@interface HammerBuiltRuleFunctions : NSObject {
	LLVMFunction *lengthOfMatch;
	LLVMFunction *rangeOfMatch;
}

@property (nonatomic, retain) LLVMFunction *lengthOfMatch;
@property (nonatomic, retain) LLVMFunction *rangeOfMatch;

@end

typedef NSUInteger(*HammerCompiledRuleLengthOfMatchFunction)(NSUInteger, HammerParser *);
typedef BOOL(*HammerCompiledRuleRangeOfMatchFunction)(NSRange *, NSUInteger, HammerParser *);

@interface HammerCompiledRule : HammerRule {
	HammerRule *original;
	HammerCompiledRuleLengthOfMatchFunction lengthOfMatchFunction;
	HammerCompiledRuleRangeOfMatchFunction rangeOfMatchFunction;
}

+(id)ruleWithOriginalRule:(HammerRule *)_original compiler:(LLVMCompiler *)_compiler functions:(HammerBuiltRuleFunctions *)_functions;
-(id)initWithOriginalRule:(HammerRule *)_original compiler:(LLVMCompiler *)_compiler functions:(HammerBuiltRuleFunctions *)_functions;

@property (nonatomic, readonly) HammerRule *original;

@property (nonatomic, readonly) HammerCompiledRuleLengthOfMatchFunction lengthOfMatchFunction;
// @property (nonatomic, readonly) HammerCompiledRuleRangeOfMatchFunction rangeOfMatchFunction;

@end


HammerCompiledRuleLengthOfMatchFunction HammerCompiledRuleLengthOfMatchFunctionForReference(HammerParser *parser, NSString *reference);
// HammerCompiledRuleRangeOfMatchFunction HammerCompiledRuleLengthOfMatchFunctionForReference(HammerParser *parser, NSString *reference);
