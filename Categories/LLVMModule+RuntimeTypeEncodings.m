// LLVMModule+RuntimeTypeEncodings.m
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import "LLVMModule+RuntimeTypeEncodings.h"
#import "LLVMType+RuntimeTypeEncodings.h"

@implementation LLVMModule (LLVMModuleRuntimeTypeEncodings)

-(LLVMType *)setObjCType:(const char *)type forName:(NSString *)name {
	LLVMType *result = [LLVMType typeForObjCType: type inModule: self];
	[self setType: result forName: name];
	return result;
}

@end
