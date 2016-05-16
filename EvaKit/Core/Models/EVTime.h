//
//  EVTime.h
//  EvaKit
//
//  Created by Yegor Popovych on 8/11/15.
//  Copyright (c) 2015 Evature. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EVBool.h"

@interface EVTime : NSObject

// Represent a specific date and time if given.
@property (nonatomic, strong, readwrite) NSString* date;

// Example: "fly to ny 3/4/2010 at 10am" results: "date": "2010-04-03", "time": "10:00:00".
@property (nonatomic, strong, readwrite) NSString* time;

// May represent:
// A range starting from Date/Time. Example: "next week" results: "date": "2010-10-25", "delta": "days=+6"
// A duration without an anchor date. Example: "hotel for a week" results: "delta": "days=+7"
//
@property (nonatomic, strong, readwrite) NSString* delta;

@property (nonatomic, strong, readwrite) NSString* maxDelta;
@property (nonatomic, strong, readwrite) NSString* minDelta;

// A restriction on the date/time requirement. Values can be: "no_earlier", "no_later", "no_more", "no_less",
// "latest", "earliest"
//
// Example: "depart NY no later than 10am" results: "restriction": "no_later", "time": "10:00:00"
@property (nonatomic, strong, readwrite) NSString* restriction;

// A boolean flag representing that a particular time has been calculated from other times, and not directly derived
// from the input text. In most cases if an arrival time to a location is specified, the departure time from the
// previous location is calculated.
@property (nonatomic, assign, readwrite) EVBool calculated;

- (NSInteger)daysDelta;
+ (NSInteger)daysDelta:(NSString*)deltaString;

- (instancetype)initWithResponse:(NSDictionary *)response;

@end
