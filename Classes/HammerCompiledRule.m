// HammerCompiledRule.m
// Created by Rob Rix on 2009-12-23
// Copyright 2009 Monochrome Industries

#import "HammerCompiledRule.h"
#import "HammerRuleCompiler.h"

#import <Auspicion/Auspicion.h>
#import <Hammer/HammerParser.h>

@implementation HammerBuiltRuleFunctions
@synthesize lengthOfMatch, rangeOfMatch;
@end


@implementation HammerCompiledRule

+(id)ruleWithOriginalRule:(HammerRule *)_original compiler:(LLVMCompiler *)_compiler functions:(HammerBuiltRuleFunctions *)_functions {
	return [[[self alloc] initWithOriginalRule: _original compiler: _compiler functions: _functions] autorelease];
}

-(id)initWithOriginalRule:(HammerRule *)_original compiler:(LLVMCompiler *)compiler functions:(HammerBuiltRuleFunctions *)functions {
	if(self = [super init]) {
		original = [_original retain];
		NSParameterAssert(original != nil);
		NSParameterAssert(compiler != nil);
		NSParameterAssert(functions != nil);
		NSParameterAssert(functions.lengthOfMatch != nil);
		lengthOfMatchFunction = [compiler compiledFunction: functions.lengthOfMatch];
		NSParameterAssert(lengthOfMatchFunction != NULL);
		
		if(functions.rangeOfMatch) { // remove this if we compile HammerRule’s version too
			rangeOfMatchFunction = [compiler compiledFunction: functions.rangeOfMatch];
			NSParameterAssert(rangeOfMatchFunction != NULL);
		}
	}
	return self;
}

-(void)dealloc {
	[original release];
	[super dealloc];
}


@synthesize original;

@synthesize lengthOfMatchFunction;


-(NSUInteger)lengthOfMatchFromCursor:(NSUInteger)initial withParser:(HammerParser *)parser {
	return lengthOfMatchFunction(initial, parser);
}

-(BOOL)range:(NSRange *)outrange ofMatchFromCursor:(NSUInteger)initial withParser:(HammerParser *)parser {
	return rangeOfMatchFunction(outrange, initial, parser);
}


-(void)acceptVisitor:(id<HammerRuleVisitor>)visitor {
	[original acceptVisitor: visitor];
}


// 10.6-only
-(id)forwardingTargetForSelector:(SEL)selector {
	return original;
}


// 10.5
-(void)forwardInvocation:(NSInvocation *)invocation {
	if([original respondsToSelector: invocation.selector]) {
		[invocation invokeWithTarget: original];
	} else {
		[original doesNotRecognizeSelector: invocation.selector];
	}
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
	return [original methodSignatureForSelector: selector];
}

@end


HammerCompiledRuleLengthOfMatchFunction HammerCompiledRuleLengthOfMatchFunctionForReference(HammerParser *parser, NSString *reference) {
	HammerCompiledRule *compiledRule = (HammerCompiledRule *)[parser ruleForReference: reference];
	return compiledRule.lengthOfMatchFunction;
}

// HammerCompiledRuleRangeOfMatchFunction HammerCompiledRuleLengthOfMatchFunctionForReference(HammerParser *parser, NSString *reference) {
// 	
// }