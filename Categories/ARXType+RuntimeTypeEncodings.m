// ARXType+RuntimeTypeEncodings.m
// Created by Rob Rix on 2010-05-30
// Copyright 2010 Monochrome Industries

#import "ARXType+RuntimeTypeEncodings.h"

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
	@"typeQualifier		= 'r';\n"
	@"type				= typeQualifier? (char | short | int | long | longLong | float | double | bool | void | string | object | class | selector | array | struct | union | bitfield | pointer | unknown);\n"
	@"main				= type+;\n"
;

@interface HammerCTypeBuilder : NSObject <HammerBuilder> {
	ARXType *resultType;
	ARXModule *module;
	ARXContext *context;
}

-(ARXType *)typeForObjCType:(const char *)type inModule:(ARXModule *)module;

@end

@implementation ARXType (ARXTypeRuntimeTypeEncodings)

+(ARXType *)typeForObjCType:(const char *)type inModule:(ARXModule *)module {
	return [[[HammerCTypeBuilder alloc] init] typeForObjCType: type inModule: module];
}

@end


@implementation HammerCTypeBuilder

-(ARXType *)typeForObjCType:(const char *)type inModule:(ARXModule *)_module {
	module = _module;
	context = module.context;
	HammerRuleGraphRef ruleGraph = HammerRuleGraphCreateWithGrammar(HammerCObjCTypeEncodingGrammar, nil, NULL);
	NSError *error = nil;
	if(!HammerRuleGraphParseString(ruleGraph, [NSString stringWithUTF8String: type], self, &error)) {
		NSLog(@"Error parsing ObjC type '%s': %@ %@", type, error.localizedDescription, error.userInfo);
	}
	return resultType;
}


-(ARXType *)charRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType int8TypeInContext: context];
}

-(ARXType *)shortRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType int16TypeInContext: context];
}

-(ARXType *)intRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType int32TypeInContext: context];
}

-(ARXType *)longRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType int32TypeInContext: context];
}

-(ARXType *)longLongRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType int64TypeInContext: context];
}

-(ARXType *)floatRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType floatTypeInContext: context];
}

-(ARXType *)doubleRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType doubleTypeInContext: context];
}

-(ARXType *)boolRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType int1TypeInContext: context];
}

-(ARXType *)voidRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType voidTypeInContext: context];
}

-(ARXType *)stringRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType pointerTypeToType: [ARXType int8TypeInContext: context]];
}

-(ARXType *)objectRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType pointerTypeToType: [ARXType int8TypeInContext: context]];
}

-(ARXType *)classRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType pointerTypeToType: [ARXType int8TypeInContext: context]];
}

-(ARXType *)selectorRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType pointerTypeToType: [ARXType int8TypeInContext: context]];
}

-(ARXType *)arrayRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [ARXType arrayTypeWithCount: [[[submatches objectForKey: @"count"] lastObject] integerValue] type: [[submatches objectForKey: @"type"] lastObject]];
}

-(ARXType *)structRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return ([[submatches objectForKey: @"type"] count] > 0)
	?	[ARXType structureTypeWithTypes: [submatches objectForKey: @"type"] inContext: context]
	:	[module typeNamed: [[submatches objectForKey: @"name"] lastObject]] ?: [ARXType int8TypeInContext: context];
}

-(ARXType *)unionRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return ([[submatches objectForKey: @"type"] count] > 0)
	?	[ARXType unionTypeWithTypes: [submatches objectForKey: @"type"]]
	:	[module typeNamed: [[submatches objectForKey: @"name"] lastObject]] ?: [ARXType int8TypeInContext: context];
}

-(ARXType *)bitfieldRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return NULL;
}

-(ARXType *)pointerRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	ARXType *referencedType = [[submatches objectForKey: @"type"] lastObject];
	if([referencedType isEqual: context.voidType]) {
		referencedType = [ARXType int8TypeInContext: context];
	}
	return [ARXType pointerTypeToType: referencedType];
}

-(ARXType *)unknownRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return NULL;
}

-(ARXType *)typeRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	return [[submatches objectForKey: [submatches allKeys].lastObject] lastObject];
}

-(ARXType *)mainRuleDidMatchInRange:(NSRange)range withSubmatches:(NSDictionary *)submatches {
	resultType = [[submatches objectForKey: @"type"] lastObject];
	return resultType;
}

@end