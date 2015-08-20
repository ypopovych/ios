//
//  EVPNRAttributes.h
//  EvaKit
//
//  Created by Yegor Popovych on 8/12/15.
//  Copyright (c) 2015 Evature. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EVPNRAttributes : NSObject

@property (nonatomic, assign, readwrite) BOOL requested;

- (instancetype)initWithResponse:(NSDictionary *)response;

@end
