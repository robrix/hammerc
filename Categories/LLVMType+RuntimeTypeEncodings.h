// LLVMType+RuntimeTypeEncodings.h
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import <Auspicion/Auspicion.h>

@interface LLVMType (LLVMTypeRuntimeTypeEncodings)

+(LLVMType *)typeForObjCType:(const char *)type;

@end