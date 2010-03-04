// HammerBuilder.h
// Created by Rob Rix on 2007-12-18
// Copyright 2007 Monochrome Industries

@class HammerParser, NSMutableArray, NSString;

@interface HammerBuilder : NSObject {
	HammerParser *grammarParser;
	HammerParser *resultParser;
	NSMutableDictionary *rules;
	NSURL *baseURL;
	NSString *grammar;
}

+(id)grammarParser;

-(id)initWithGrammar:(NSString *)aGrammar relativeToBaseURL:(NSURL *)baseURL;

@property (nonatomic, readonly) NSString *grammar;
@property (nonatomic, readonly) NSURL *baseURL;

-(HammerParser *)buildParserWithError:(NSError **)error;

@end
