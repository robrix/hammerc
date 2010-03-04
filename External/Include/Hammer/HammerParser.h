// HammerParser.h
// Created by Rob Rix on 2007-12-14
// Copyright 2007 Monochrome Industries

#import <Foundation/Foundation.h>

@class HammerAlternationRule, HammerMatch, HammerReferenceRule, HammerRule;
@protocol HammerParserDelegate;

@interface HammerParser : NSObject <NSCopying, NSCoding> {
	NSDictionary *rules;
	NSMutableArray *parentParsers;
	NSMutableArray *matchContextStack;
	NSError *tempError;
	NSUInteger errorDepth;
	NSMutableArray *_errors;
	NSString *string;
	id<HammerParserDelegate> delegate;
	NSUInteger cursor;
	BOOL isIgnoringMatches;
	BOOL isParsing;
	BOOL attemptsIgnorableRule;
}

+(HammerParser *)parserWithGrammar:(NSString *)grammar relativeToBaseURL:(NSURL *)baseURL error:(NSError **)error;
+(HammerParser *)parserWithGrammar:(NSString *)grammar error:(NSError **)error;
+(HammerParser *)parserWithContentsOfURL:(NSURL *)grammarURL error:(NSError **)error;

@property (nonatomic, copy) NSDictionary *rules;
-(HammerRule *)ruleForReference:(NSString *)reference;

// imports are done via differential inheritance
-(void)importRulesFromParser:(HammerParser *)parser;
-(BOOL)importRulesFromGrammarAtURL:(NSURL *)grammarURL error:(NSError **)error;

@property (nonatomic, readonly) HammerRule *mainRule;
@property (nonatomic, readonly) HammerRule *ignorableRule;

-(NSUInteger)ignorableCharactersFromCursor:(NSUInteger)initial;
@property (nonatomic, readonly) BOOL isIgnoringMatches;
@property (nonatomic) BOOL attemptsIgnorableRule;

@property (nonatomic, readonly, copy) NSString *string;

@property (nonatomic, assign) id<HammerParserDelegate> delegate;

@property (nonatomic) NSUInteger cursor;
@property (nonatomic, readonly) BOOL isAtEnd;
-(BOOL)cursorIsAtEnd:(NSUInteger)initial;

-(BOOL)parse:(NSString *)str;

@property (nonatomic, readonly) BOOL isParsing;

-(NSString *)toGrammar;

@end


@interface HammerParser () // feedback from matches

@property (nonatomic, readonly) NSMutableDictionary *currentMatchContext;

-(void)pushMatchContext;
-(void)popAndDiscardMatchContext;
-(void)popAndPassUpMatchContext;
-(void)popAndPassUpMatchContext:(BOOL)shouldPassUp;
-(void)popAndNestMatchContext:(BOOL)shouldPassUp inRule:(HammerRule *)rule forKey:(NSString *)key inRange:(NSRange)range;

@end


@interface HammerParser () // error handling

@property (nonatomic, readonly) NSError *currentErrorContext;

-(void)addError:(NSError *)error;

-(void)pushErrorContext;
-(NSError *)popErrorContext;

@property (nonatomic, copy, readonly) NSArray *errors;

@end


@protocol HammerParserDelegate <NSObject>

@optional

// fixme: return an error by reference
// if, for a given rule name <name>, the document responds to the slightly different selector “parser:<name>Rule:didMatch:”, that message will be sent instead of this
-(id)parser:(HammerParser *)parser rule:(HammerReferenceRule *)rule didMatch:(HammerMatch *)match error:(NSError **)error; // so implement this when developing and you can watch what comes in that you weren’t expecting yet.

-(void)parser:(HammerParser *)parser rule:(HammerAlternationRule *)rule parseErrorOccurred:(NSError *)error;

@end


// C API
BOOL HammerParserCursorIsAtEnd(HammerParser *parser, NSUInteger cursor);

NSUInteger HammerParserGetInputLength(HammerParser *parser);
NSString *HammerParserGetInputString(HammerParser *parser);

NSUInteger HammerParserIgnorableCharactersFromCursor(HammerParser *parser, NSUInteger cursor);

BOOL HammerParserGetAttemptsIgnorableRule(HammerParser *parser);
void HammerParserSetAttemptsIgnorableRule(HammerParser *parser, BOOL _attemptsIgnorableRule);

void HammerParserPushMatchContext(HammerParser *parser);
void HammerParserPopAndPassUpMatchContext(HammerParser *parser, BOOL shouldPassUp);
void HammerParserPopAndNestMatchContext(HammerParser *parser, BOOL shouldPassUp, HammerRule *rule, NSString *key, NSRange range);
