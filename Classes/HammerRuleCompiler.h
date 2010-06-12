// HammerRuleCompiler.h
// Created by Rob Rix on 2009-12-06
// Copyright 2009 Monochrome Industries

#import <Foundation/Foundation.h>
#import <Hammer/Hammer.h>

@class LLVMBuilder, LLVMContext, LLVMModule, LLVMType;

@interface HammerRuleCompiler : HammerRuleVisitor {
	LLVMBuilder *builder;
	LLVMContext *context;
	
	LLVMModule *module;
	
	HammerRulePrinter *printer;
	
	NSMutableArray *builtFunctionsStack;
}

+(id)compiler;

-(HammerRuleRef)compileRule:(HammerRuleRef)rule;

@end
