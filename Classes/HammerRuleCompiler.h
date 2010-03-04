// HammerRuleCompiler.h
// Created by Rob Rix on 2009-12-06
// Copyright 2009 Monochrome Industries

#import <Foundation/Foundation.h>

@class HammerParser, HammerRulePrinter;
@class LLVMBuilder, LLVMContext, LLVMModule, LLVMType;
@protocol HammerRuleVisitor;

@interface HammerRuleCompiler : NSObject {
	HammerParser *parser;
	
	LLVMBuilder *builder;
	LLVMContext *context;
	
	LLVMModule *module;
	
	HammerRulePrinter *printer;
	
	NSMutableArray *builtFunctionsStack;
}

@property (nonatomic, retain) HammerParser *parser;

-(HammerRule *)compileRule:(HammerRule *)rule;

@end
