//
//  GDPParser.m
//
//  Created by Vladimir Ionita on 13/09/2012.
//

#import "GDPParser.h"

#pragma mark - Private Interface

@interface GDPParser()
@property (nonatomic, assign) BOOL isFirstPacket;
@property (nonatomic, assign) BOOL holdsPayloadData;
@property (nonatomic, assign) int payloadSize;
@property (nonatomic, retain) NSMutableData *header;
@property (nonatomic, retain) NSMutableData *payload;
@end


#pragma mark - Implementation

@implementation GDPParser
@synthesize isFirstPacket = _isFirstPacket;
@synthesize holdsPayloadData = _holdsPayloadData;
@synthesize payloadSize = _payloadSize;
@synthesize header = _header;
@synthesize payload = _payload;


#pragma mark - Initializer

- (id)init {
    self = [super init];
    if (self != nil) {
        _isFirstPacket = TRUE;
    }
    
    return self;
}


#pragma mark - Memory Management

- (void) dealloc {
    [_header release];
    [_payload release];
    
    [super dealloc];
}


#pragma mark - Methods

- (NSData *)framePayloadFromData:(NSData *)rawData {
    // Stores the data that needs to be parsed.
    NSData *rawPacket;
    
    // Stores temporary informational raw data.
    unsigned char *buffer;
    
    // Stores the size that the buffer will have.
    unsigned buffer_size;
    
    // If the header still has some data from the last time, append the `rawData` to it.
    if (self.header != nil) {
        [self.header appendData:rawData];
        
        rawPacket = [NSData dataWithData:self.header];
        
        [self.header release];
        self.header = nil;
    } else {
        rawPacket = [NSData dataWithData:rawData];
    }
    
    // If this is the first packet, we're dealing with the header.
    // We know the header ends with '\r\n\r\n'.
    // At the end we remove the header from the 'rawPacket'.
    if ([self isFirstPacket]) {
        NSString *httpContent = [[[NSString alloc] initWithBytes:[rawPacket bytes] length:[rawPacket length] encoding:NSASCIIStringEncoding] autorelease];
        NSRange headerEndLocation = [httpContent rangeOfString:@"\r\n\r\n"];
        
        if (headerEndLocation.length != 0) {
            self.isFirstPacket = FALSE;
#ifdef DEBUG
            NSString *httpHeader = [[[NSString alloc] initWithString:[httpContent substringWithRange:NSMakeRange(0, headerEndLocation.location)]] autorelease];
            NSLog(@"HTTP Header: %@", httpHeader);
#endif
            
            rawPacket = [rawPacket subdataWithRange:NSMakeRange(headerEndLocation.location + headerEndLocation.length, [rawPacket length]-(headerEndLocation.location + headerEndLocation.length))];
        }
    }
    
    // The actual parsing begins here.
    // The block is divided in 2 parts: the header parsing and the payload parsing.
    while ([rawPacket length] > 0) {
        //-- GDP Parsing
        if (![self holdsPayloadData]) {
            //-- Header Parsing
            int headerLength = 62;
            int position = 0;
            int payloadType;
            
            //-- Try to get the GDP Header
            if (self.header == nil)
                self.header = [[NSMutableData alloc] init];

            int payloadRequiredSize = ([rawPacket length] > headerLength) ? headerLength : [rawPacket length];
            [self.header appendData:[rawPacket subdataWithRange:NSMakeRange(0, payloadRequiredSize)]];
            rawPacket = [rawPacket subdataWithRange:NSMakeRange(payloadRequiredSize, [rawPacket length] - payloadRequiredSize)];
            
            //-- Check GDP Header integrity
            if (headerLength == [self.header length]) {
                // Read the first 6 bytes of header (major version, minor version, flags, padding, payloadtype(2 bytes))
                buffer_size = 6;                   
                buffer = malloc(buffer_size);
                
                [self.header getBytes:buffer range:NSMakeRange(position, buffer_size)];
#ifdef DEBUG
                for (int i = 0 ; i < buffer_size; i++)
                    NSLog(@"data: %i", buffer[i]);
#endif
                
                payloadType = buffer[5];
                
                free(buffer);
                position += buffer_size;
                
                
                // Read the payload length (4 bytes)
                buffer_size = 4;
                buffer = malloc(buffer_size);
            
                [self.header getBytes:buffer range:NSMakeRange(position, buffer_size)];
#ifdef DEBUG
                for (int i =0 ; i < buffer_size; i++)
                    NSLog(@"payload: %i", buffer[i]);
#endif
                
                unsigned char *bufferAux;
                bufferAux = malloc(buffer_size);
                
                for (int i=0; i<buffer_size; i++)
                    bufferAux[(buffer_size-1)-i] = buffer[i];
                
                self.payloadSize = (int) *((int*)bufferAux);
                free(bufferAux);
                
                free(buffer);
                if (payloadType == 1)
                    self.holdsPayloadData = TRUE;

                if (self.payload != nil) {
                    [self.payload release];
                    self.payload = nil;
                }
                    
                [self.header release];
                self.header = nil;
            }
        }
        
        if ([self holdsPayloadData]) {
            //-- Payload Parsing
            if (self.payload == nil)
                self.payload = [[NSMutableData alloc] init];

            //-- Try to get the Payload
            int payloadRequiredSize = ([rawPacket length] > (self.payloadSize-[self.payload length])) ? self.payloadSize-[self.payload length] : [rawPacket length];
            [self.payload appendData:[rawPacket subdataWithRange:NSMakeRange(0, payloadRequiredSize)]];
            rawPacket = [rawPacket subdataWithRange:NSMakeRange(payloadRequiredSize,
                                                                    [rawPacket length] - payloadRequiredSize)];
            
            //-- Check for the GDP Payload integrity
            if (self.payloadSize == [self.payload length]) {
                self.holdsPayloadData = FALSE;
                if ([rawPacket length] != 0)
                    self.header = [[NSMutableData alloc] initWithData:rawPacket];

                return [self payload];
            } else {
                self.holdsPayloadData = TRUE;
            }
        } else {
            int payloadRequiredSize = ([rawPacket length] > (self.payloadSize-[self.payload length])) ? self.payloadSize-[self.payload length] : [rawPacket length];
            rawPacket = [rawPacket subdataWithRange:NSMakeRange(payloadRequiredSize,
                                                                    [rawPacket length] - payloadRequiredSize)];
        }
    }
    
    return nil;
}

@end
