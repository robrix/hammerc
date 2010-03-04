// HammerMatch.h
// Created by Rob Rix on 2008-03-21
// Copyright 2008 Monochrome Industries

#import <Foundation/Foundation.h>

@class HammerRule, HammerMatch;

@protocol HammerMatchVisitor <NSObject>
-(void)visitMatch:(HammerMatch *)match key:(NSString *)key parent:(HammerMatch *)parent;
-(void)leaveMatch:(HammerMatch *)match key:(NSString *)key parent:(HammerMatch *)parent;
@end

@interface HammerMatch : NSObject {
	HammerRule *rule;
	NSDictionary *submatches;
	NSString *string;
	NSRange range;
}

-(id)initWithRule:(HammerRule *)r submatches:(NSDictionary *)s inRange:(NSRange)rg ofString:(NSString *)str;

@property (nonatomic, readonly) HammerRule *rule;

@property (nonatomic, readonly) NSString *string;
@property (nonatomic, readonly) NSString *substring;
@property (nonatomic, readonly) NSRange range;

-(id)submatchForKey:(NSString *)key;
-(NSArray *)submatchesForKey:(NSString *)key;
@property (nonatomic, copy) NSDictionary *submatches; 

@property (nonatomic, readonly) NSUInteger count;

-(void)acceptVisitor:(id<HammerMatchVisitor>)visitor key:(NSString *)key parent:(HammerMatch *)parent;

@end
