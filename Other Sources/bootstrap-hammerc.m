// bootstrap-hammerc.m
// Created by Rob Rix on 2010-03-03
// Copyright 2010 Monochrome Industries

#import <Foundation/Foundation.h>

#import <Hammer/Hammer.h>

#import "HammerRuleCompiler.h"

int main(int argc, const char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	HammerRuleGraphRef grammar = [HammerBuilder grammarRuleGraph];
	HammerRuleCompiler *compiler = [[HammerRuleCompiler alloc] init];
	
	for(NSString *ruleName in grammar) {
		HammerRuleRef rule = HammerRuleGraphGetRuleForName(grammar, ruleName);
		HammerRuleRef compiledRule = [compiler compileRule: rule];
	}
	// the rules shouldn’t be JITed, they should just be output—how?
	// then they should actually be assembled via llc?
	// where does optimization come in?
	
	[pool drain];
	return 0;
}
