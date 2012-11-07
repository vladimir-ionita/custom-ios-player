//
//  FrameDecoder.m
//
//  Created by Vladimir Ionita on 12/09/2012.
//

#import "FrameDecoder.h"

#pragma mark - Private Interface

@interface FrameDecoder()
@property (nonatomic, assign) AVCodecContext *videoCodecContext;
@property (nonatomic, assign) AVFrame *videoFrame;
@property (nonatomic, assign) AVPicture picture;
@property (nonatomic, assign) struct SwsContext *imageConvertContext;
@end

@interface FrameDecoder(private)
- (void)setupScaler;
- (void)pictureFromFrame;
- (UIImage *)imageFromAVPicture:(AVPicture)picture width:(int)width height:(int)height;
@end


#pragma mark - Implementation

@implementation FrameDecoder
@synthesize videoCodecContext = _videoCodecContext;
@synthesize videoFrame = _videoFrame;
@synthesize picture = _picture;
@synthesize imageConvertContext = _imageConvertContext;
@synthesize outputWidth = _outputWidth;
@synthesize outputHeight = _outputHeight;


#pragma mark - Initializer

/*
 *  Initialize the decoder and setup its properties.
 */
- (id)init {
    self = [super init];
    
    if (self != nil) {
        av_register_all();
        
        AVCodec *videoCodec;
        videoCodec = avcodec_find_decoder(AV_CODEC_ID_MPEG4);
        if (videoCodec == NULL) {
#ifdef DEBUG
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GlobalNotificationHandler"
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"CodecNotFound"]
                                                                                                   forKey:@"error"]];
#endif
            [self release];
            return nil;
        }
        
        //-- Initialize the codec context with the video codec
        self.videoCodecContext = avcodec_alloc_context3(videoCodec);
        self.videoCodecContext->width = 320;
        self.videoCodecContext->height = 240;
        
        // Open codec
        if(avcodec_open2(self.videoCodecContext, videoCodec, 0) < 0) {
#ifdef DEBUG
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GlobalNotificationHandler"
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"CodecNotOpen"]
                                                                                                   forKey:@"error"]];
#endif
            
            [self release];
            return nil;
        }
        
        // Allocate video frame
        self.videoFrame=avcodec_alloc_frame();
        
        self.outputWidth = self.videoCodecContext->width;
        self.outputHeight = self.videoCodecContext->height;
    }
    
    return self;
}


#pragma mark - Memory Management

- (void)dealloc {
    //-- Free Scaler
    sws_freeContext(_imageConvertContext);
    
    //-- Free AVPicture
    avpicture_free(&_picture);
    
    //-- Free YUV Frame
    av_free(_videoFrame);
    
    //-- Close the codec;
    if (_videoCodecContext)
        avcodec_close(_videoCodecContext);
    
    [super dealloc];
}


#pragma mark - Setters/Accessors

- (void)setOutputWidth:(int)outputWidth {
    if (_outputWidth == outputWidth)
        return;
    _outputWidth = outputWidth;
    [self setupScaler];
}

- (void)setOutputHeight:(int)outputHeight {
    if (_outputHeight == outputHeight)
        return;
    _outputHeight = outputHeight;
    [self setupScaler];
}


#pragma mark - Public Methods

/*
 * Convert raw data to UIImage.
 *
 * Algorithm:
 * 1. Decode the raw data video frame;
 * 2. Get the AVPicture;
 * 3. Convert AVPicture to UIImage.
 *
 * Might be a good idea to check first if the code is open.
 */
- (UIImage *)decodeFrame:(NSData*)rawData {   
    AVPacket packet;
    int frameFinished = 0;
    av_init_packet(&packet);
    uint8_t inbuf[[rawData length]+ FF_INPUT_BUFFER_PADDING_SIZE];
    
    [rawData getBytes:inbuf];
    packet.data = inbuf;
    packet.size = [rawData length];
    
    if (packet.size!=0) {        
        // Decode video frame
        avcodec_decode_video2(self.videoCodecContext, self.videoFrame, &frameFinished, &packet);
    }
    
    // Free the packet that was allocated by av_read_frame
    av_free_packet(&packet);
    
    if (frameFinished != 0) {
        if (!self.videoFrame->data[0])
            return nil;
        
        [self pictureFromFrame];
        return [self imageFromAVPicture:self.picture width:self.outputWidth height:self.outputHeight];
    }
    return nil;
}


#pragma mark - Private Methods

/*
 * Setup the scaler according to the picture.
 */
- (void)setupScaler {
    // Release old picture and scaler
    avpicture_free(&_picture);
	sws_freeContext(self.imageConvertContext);	
	
	// Allocate RGB picture
	avpicture_alloc(&_picture, PIX_FMT_RGB24, self.outputWidth, self.outputHeight);
	
	// Setup scaler
	static int sws_flags =  SWS_FAST_BILINEAR;
	self.imageConvertContext = sws_getContext(self.videoCodecContext->width, 
                                              self.videoCodecContext->height,
                                              self.videoCodecContext->pix_fmt,
                                              self.outputWidth, 
                                              self.outputHeight,
                                              PIX_FMT_RGB24,
                                              sws_flags, NULL, NULL, NULL);
}

/*
 * Get the image from the video frame.
 */
- (void)pictureFromFrame {
    sws_scale (self.imageConvertContext, self.videoFrame->data, self.videoFrame->linesize,
               0, self.videoCodecContext->height,
               self.picture.data, self.picture.linesize);
}

/*
 * Convert AVPicture image to UIImage.
 */
- (UIImage *)imageFromAVPicture:(AVPicture)picture width:(int)width height:(int)height {
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, picture.data[0], picture.linesize[0]*height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width, 
                                       height, 
                                       8, 
                                       24, 
                                       picture.linesize[0], 
                                       colorSpace, 
                                       bitmapInfo, 
                                       provider, 
                                       NULL, 
                                       NO, 
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}

@end
