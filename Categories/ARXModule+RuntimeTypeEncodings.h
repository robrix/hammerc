// ARXModule+RuntimeTypeEncodings.h
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import <Auspicion/Auspicion.h>

#define ARXModuleImportType(module, type) [module setObjCType: @encode(type) forName: @#type]

@interface ARXModule (ARXModuleRuntimeTypeEncodings)

-(ARXType *)setObjCType:(const char *)type forName:(NSString *)name;

@end
