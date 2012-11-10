//
//  GDPParser.h
//
//  Created by Vladimir Ionita on 13/09/2012.
//

#import <Foundation/Foundation.h>

@interface GDPParser : NSObject {
  @private
    // Flag to indicate whether the packet to be parsed is the first packet.
    // Needed for header parsing.
    BOOL    _isFirstPacket;
    
    // Flag to indicate whether the parser holds a part of the frame from the previous parsing.
    BOOL    _holdsPayloadData;
    
    // Stores the payload size.
    int     _payloadSize;
    
    // Stores the GDP header. It contains useful information like payload length, payload type.
    NSMutableData   *_header;
    
    // Stores the actual payload.
    NSMutableData   *_payload;
}

// Parse a GDP packet and returns the payload (the frame) if any.
- (NSData *)framePayloadFromData:(NSData *)rawData;

@end
