//
//  FrameDecoder.h
//
//  Created by Vladimir Ionita on 12/09/2012.
//

#import <AVFoundation/AVFoundation.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"


@interface FrameDecoder : NSObject {
  @private
    AVCodecContext      *_videoCodecContext;
    AVFrame             *_videoFrame;
    AVPicture           _picture;
    struct SwsContext   *_imageConvertContext;
    
    int _outputHeight;
    int _outputWidth;
}

@property (nonatomic, assign) int outputHeight;
@property (nonatomic, assign) int outputWidth;

/*
 * Convert raw data to UIImage.
 */
- (UIImage *)decodeFrame:(NSData *)rawData;

@end
