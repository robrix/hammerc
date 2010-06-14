// ARXModule+RuntimeTypeEncodings.m
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import "ARXModule+RuntimeTypeEncodings.h"
#import "ARXType+RuntimeTypeEncodings.h"

@implementation ARXModule (ARXModuleRuntimeTypeEncodings)

-(ARXType *)setObjCType:(const char *)type forName:(NSString *)name {
	ARXType *result = [ARXType typeForObjCType: type inModule: self];
	[self setType: result forName: name];
	return result;
}

@end
