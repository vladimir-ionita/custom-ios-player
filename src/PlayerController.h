//
//  PlayerController.h
//
//  Created by Vladimir Ionita on 12/09/2012.
//

#import <UIKit/UIKit.h>
@class GDPParser;
@class FrameDecoder;

@interface PlayerController : UIViewController {
    // Parses the data received from the streaming and returns a frame.
    GDPParser       *_gdpParser;
    
    // Decodes the received frame and converts it to an image.
    FrameDecoder    *_frameDecoder;
    
    // Represents the output UIImageView. It  will refresh its image each time a new image
    // is decoded with the `FrameDecoder`.
    UIImageView     *_player;
}

/*
 * Set the frame size of the streaming view.
 */
- (void)setFrame:(CGRect)frame;

@end
