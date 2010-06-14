// ARXType+RuntimeTypeEncodings.h
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import <Auspicion/Auspicion.h>

@interface ARXType (ARXTypeRuntimeTypeEncodings)

+(ARXType *)typeForObjCType:(const char *)type inModule:(ARXModule *)module;

@end
