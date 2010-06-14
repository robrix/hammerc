// HammerRuleCompilerVisitor.h
// Created by Rob Rix on 2010-06-12
// Copyright 2010 Monochrome Industries

#import <Foundation/Foundation.h>

@class HammerRuleCompiler;

@interface HammerRuleCompilerVisitor : NSObject <HammerRuleVisitor> {
	HammerRuleCompiler *compiler;
}

-(id)initWithCompiler:(HammerRuleCompiler *)_compiler;

@end
