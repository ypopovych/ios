//
//  EVStreamURLWriter.m
//  EvaKit
//
//  Created by Yegor Popovych on 8/5/15.
//  Copyright (c) 2015 Evature. All rights reserved.
//

#import "EVStreamURLWriter.h"
#import "EVLogger.h"

@interface NSStream (BoundPairAdditions)
+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize;
@end

@implementation NSStream (BoundPairAdditions)

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize
{
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    if ((inputStreamPtr == NULL) || (outputStreamPtr == NULL)) {
        EV_LOG_ERROR(@"Binding streams are null");
        return;
    }
    
    readStream = NULL;
    writeStream = NULL;
    
    CFStreamCreateBoundPair(
                            NULL,
                            ((inputStreamPtr  != nil) ? &readStream : NULL),
                            ((outputStreamPtr != nil) ? &writeStream : NULL),
                            (CFIndex) bufferSize
                            );
    
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
}

@end


@interface EVStreamURLWriter () <NSURLConnectionDataDelegate> {
    BOOL _streamOpened;
    BOOL _connectionError;
}

@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSOutputStream* dataStream;

@end

@implementation EVStreamURLWriter

- (instancetype)initWithURL:(NSURL*)anURL
                    headers:(NSDictionary*)headers
                 bufferSize:(NSUInteger)bufferSize
          connectionTimeout:(NSTimeInterval)timeout
                   delegate:(id<EVStreamURLWriterDelegate>)delegate {
    self = [super init];
    if (self != nil) {
        self.delegate = delegate;
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:anURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeout];
        [request setHTTPMethod:@"POST"];
        
        for (NSString* header in headers) {
            [request addValue:headers[header] forHTTPHeaderField:header];
        }
        
        NSInputStream* consStream;
        NSOutputStream* prodStream;
        [NSStream createBoundInputStream:&consStream outputStream:&prodStream bufferSize:bufferSize];
        if (consStream == nil) {
            EV_LOG_ERROR(@"Stream Writer nil consumer stream");
            return nil;
        }
        
        if (prodStream == nil) {
            EV_LOG_ERROR(@"Stream Writer nil producer stream");
            return nil;
        }
        
        _streamOpened = NO;
        self.dataStream = prodStream;
        _connectionError = NO;
        
        [request setHTTPBodyStream:consStream];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        });
    }
    return self;
}


- (void)dealloc {
    self.connection = nil;
    self.dataStream = nil;
    [super dealloc];
}

- (void)provider:(id<EVDataProvider>)provider hasNewData:(NSData*)data {
    if (!_streamOpened && !_connectionError) {
        [_dataStream open];
        _streamOpened = YES;
    }
    size_t writed = 0;
    size_t length = [data length];
    const uint8_t* bytes = [data bytes];
    while (!_connectionError && writed < length) {
        //Wait for space in stream
        while(!_connectionError && !_dataStream.hasSpaceAvailable) usleep(100);
        //Write so many how we can. Save how many we writed
        if (!_connectionError) {
            writed += [_dataStream write:(bytes+writed) maxLength:(length-writed)];
        }
    }
}

- (void)provider:(id<EVDataProvider>)provider gotAnError:(NSError*)error {
    [self.connection cancel];
    if (_streamOpened) {
        [_dataStream close];
        _streamOpened = NO;
    }
    self.dataStream = nil;
    self.connection = nil;
}

- (void)providerStarted:(id<EVDataProvider>)provider {
    // Do nothing.
}

- (void)providerFinished:(id<EVDataProvider>)provider {
    if (_streamOpened) {
        _streamOpened = NO;
        [_dataStream close];
    }
}


#pragma mark === NSURLCconnectionDelegate methods ===
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _connectionError = YES;
    self.connection = nil;
    [self.delegate streamWriter:self gotAnError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.delegate streamWriter:self gotResponseData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.connection = nil;
    [self.delegate streamWriterFinished:self];
}

@end
