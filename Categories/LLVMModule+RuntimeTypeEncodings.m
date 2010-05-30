// LLVMModule+RuntimeTypeEncodings.m
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import "LLVMModule+RuntimeTypeEncodings.h"
#import "LLVMType+RuntimeTypeEncodings.h"

@implementation LLVMModule (LLVMModuleRuntimeTypeEncodings)

-(void)setObjCType:(const char *)type forName:(NSString *)name {
	[self setType: [LLVMType typeForObjCType: type] forName: name];
}

@end