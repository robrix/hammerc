// HammerLiteralConcatenationRule.h
// Created by Rob Rix on 2009-10-08
// Copyright 2009 Monochrome Industries

#import <Hammer/HammerContainerRule.h>

/*
Does not attempt ignorable rules while matching its subrules. Does attempt ignorable rules before starting, if necessary.
*/

@interface HammerLiteralConcatenationRule : HammerContainerRule
@end
