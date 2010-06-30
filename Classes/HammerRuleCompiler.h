// HammerRuleCompiler.h
// Created by Rob Rix on 2009-12-06
// Copyright 2009 Monochrome Industries

#import <Foundation/Foundation.h>
#import "Hammer.h"

#import "ARXModule.h"

@class ARXContext, ARXFunction;

@interface HammerRuleCompiler : HammerRuleVisitor {
	ARXContext *context;
	ARXModule *module;
	HammerRulePrinter *printer;
}

+(id)compiler;

@property (nonatomic, readonly) ARXModule *module;

-(NSString *)nameForRule:(HammerRuleRef)rule;

-(ARXModuleFunctionDefinitionBlock)rangeOfMatchSkippingIgnorableCharactersDefinitionForRule:(HammerRuleRef)rule withLengthOfMatchFunction:(ARXFunction *)lengthOfMatch;

-(HammerRuleRef)compileRule:(HammerRuleRef)rule;

@end
