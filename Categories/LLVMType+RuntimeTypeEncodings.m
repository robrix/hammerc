// LLVMType+RuntimeTypeEncodings.m
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import "LLVMType+RuntimeTypeEncodings.h"

static NSString * const HammerCObjCTypeEncodingGrammar =
	@"char				= [cC];\n"
	@"short 			= [sS];\n"
	@"int				= [iI];\n"
	@"long				= [lL];\n"
	@"longLong			= [qQ];\n"
	@"float				= 'f';\n"
	@"double			= 'd';\n"
	@"bool				= 'B';\n"
	@"void				= 'v';\n"
	@"string			= '*';\n"
	@"object			= '@';\n"
	@"class				= '#';\n"
	@"selector			= ':';\n"
	@"array				= '[' (count = [\\d]+) type ']';\n"
	@"struct			= '{' (name = [\\w]+) ('=' type*)? '}';\n"
	@"union				= '(' (name = [\\w]+) ('=' type*)? ')';\n"
	@"bitfield			= 'b' (width = [\\d]+);\n"
	@"pointer			= '^' type;\n"
	@"unknown			= '?';\n"
	@"type				= char | short | int | long | longLong | float | double | bool | void | string | object | class | selector | array | struct | union | bitfield | pointer | unknown;\n"
	@"main				= type+;\n"
;

@interface HammerCTypeBuilder : NSObject <HammerBuilder> {
	LLVMType *resultType;
	LLVMModule *module;
	LLVMContext *context;
}

-(LLVMType *)typeForObjCType:(const char *)type inModule:(LLVMModule *)module;

@end

@implementation LLVMType (LLVMTypeRuntimeTypeEncodings)

+(LLVMType *)typeForObjCType:(const char *)type inModule:(LLVMModule *)module {
	return [[[[HammerCTypeBuilder alloc] init] autorelease] typeForObjCType: type inModule: module];
}

@end


@implementation HammerCTypeBuilder

-(LLVMType *)typeForObjCType:(const char *)type inModule:(LLVMModule *)_module {
	module = [_module retain];
	context = module.context;
	HammerRuleGraphRef ruleGraph = HammerRuleGraphCreateWithGrammar(HammerCObjCTypeEncodingGrammar, nil, NULL);
	NSError *error = nil;
	if(!HammerRuleGraphParseString(ruleGraph, [NSString stringWithUTF8String: type], self, &error)) {
		NSLog(@"Error parsing ObjC type '%s': %@ %@", type, error.localizedDescription, error.userInfo);
	}
	[module release];
	return resultType;
}


-(LLVMType *)charRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType int8TypeInContext: context];
}

-(LLVMType *)shortRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType int16TypeInContext: context];
}

-(LLVMType *)intRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType int32TypeInContext: context];
}

-(LLVMType *)longRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType int32TypeInContext: context];
}

-(LLVMType *)longLongRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType int64TypeInContext: context];
}

-(LLVMType *)floatRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType floatTypeInContext: context];
}

-(LLVMType *)doubleRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType doubleTypeInContext: context];
}

-(LLVMType *)boolRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType int1TypeInContext: context];
}

-(LLVMType *)voidRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType voidTypeInContext: context];
}

-(LLVMType *)stringRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType pointerTypeToType: [LLVMType int8TypeInContext: context]];
}

-(LLVMType *)objectRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType pointerTypeToType: [LLVMType int8TypeInContext: context]];
}

-(LLVMType *)classRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType pointerTypeToType: [LLVMType int8TypeInContext: context]];
}

-(LLVMType *)selectorRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType pointerTypeToType: [LLVMType int8TypeInContext: context]];
}

-(LLVMType *)arrayRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [LLVMType arrayTypeWithCount: [[[submatches objectForKey: @"count"] lastObject] integerValue] type: [[submatches objectForKey: @"type"] lastObject]];
}

-(LLVMType *)structRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return ([[submatches objectForKey: @"type"] count] > 0)
	?	[LLVMType structureTypeWithTypes: [submatches objectForKey: @"type"]]
	:	[module typeNamed: [[submatches objectForKey: @"name"] lastObject]] ?: [LLVMType int8TypeInContext: context];
}

-(LLVMType *)unionRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return ([[submatches objectForKey: @"type"] count] > 0)
	?	[LLVMType unionTypeWithTypes: [submatches objectForKey: @"type"]]
	:	[module typeNamed: [[submatches objectForKey: @"name"] lastObject]] ?: [LLVMType int8TypeInContext: context];
}

-(LLVMType *)bitfieldRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return NULL;
}

-(LLVMType *)pointerRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	LLVMType *referencedType = [[submatches objectForKey: @"type"] lastObject];
	if([referencedType isEqual: context.voidType]) {
		referencedType = [LLVMType int8TypeInContext: context];
	}
	return [LLVMType pointerTypeToType: referencedType];
}

-(LLVMType *)unknownRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return NULL;
}

-(LLVMType *)typeRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [[submatches objectForKey: [submatches allKeys].lastObject] lastObject];
}

-(LLVMType *)mainRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	resultType = [[submatches objectForKey: @"type"] lastObject];
	return resultType;
}

@end