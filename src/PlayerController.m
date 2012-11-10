//
//  PlayerController.m
//
//  Created by Vladimir Ionita on 12/09/2012.
//

#import "PlayerController.h"
#import "GDPParser.h"
#import "FrameDecoder.h"


#pragma mark - Private Interface

@interface PlayerController()
@property (nonatomic, assign) GDPParser *gdpParser;
@property (nonatomic, assign) FrameDecoder *frameDecoder;
@property (nonatomic, retain) UIImageView *player;
@end


#pragma mark - Implementation

@implementation PlayerController
@synthesize gdpParser = _gdpParser;
@synthesize frameDecoder = _frameDecoder;
@synthesize player = _player;


#pragma mark - Initializer

- (id)init {
    self = [super init];
    if (self != nil) {
        _gdpParser = [[GDPParser alloc] init];
        _frameDecoder = [[FrameDecoder alloc] init];
    }
    
    return self;
}


#pragma mark - Memory Management

- (void) dealloc {
    [_frameDecoder release];
    [_gdpParser release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [self.view setBackgroundColor:[UIColor brownColor]];
    self.player = [[UIImageView alloc] initWithFrame:[self.view bounds]];
    [self.view addSubview:self.player];
    
    // TODO: start streaming
    [super viewDidLoad];
}


- (void)viewDidUnload {
    // TODO: stop streaming
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Methods

/*
 * Sets the frame of the streaming view.
 */
- (void)setFrame:(CGRect)frame {
    self.view.frame = frame;
    self.player.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

/*
 * Handles the received data. It parses the data, decodes the parsed data and sets the image for the player.
*/
- (void)streamingDataReceived:(NSData *)serverData {
    NSData *encodedData = [[NSData alloc] initWithData:[self.gdpParser framePayloadFromData:serverData]];
    
    if ([encodedData length] != 0) {
        self.player.image = [self.frameDecoder decodeFrame:encodedData];
    }
    
    [encodedData release];
}

@end
