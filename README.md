# About
This project was born with the need of an iOS player that would have support for Gstreamer, and would bypass the undocumented iOS 5 hardware limitation of 4 concurrent video streams.

## Intro
There are lots of times when our SDKs are limited and can't satisfy our needs. Sometimes this stops us from implementing great ideas, other times it makes us go to a certain length and implement solutions that are out of the box.

This was the case with one of the projects I've been recently involved in.

## The Task
The task for this project was to build an iOS application that would show up to 6 live cameras on the same screen, streaming through Gstreamer Data Protocol (GDP from here on). In simpler words, a video surveillance application.

## Task Analysis
The iOS SDK offers two solutions for managing the playback of a video, be it from a file or from a network stream.
1. The first and the most straightforward solution is the MPMoviePlayerController. This is a great player, but it has some drawbacks:
- you can't customize its frame size for iPhone;
- only one stream can be played at a time;
- it doesn't have support for Gstreamer.
2. The second solution is the AVPlayer. It is more advanced, a bit more complex and requires more effort to use. From Apple documentation, it can be noted that, indeed, this player can have multiple instances playing different sources at the same time, and every instance can have its custom size. It seems the only problem would be the support for GDP.

###  AVPlayer
Testing the AVPlayer went quite good, at the beginning. It worked perfectly with 2, 3 and 4 streams, the device could handle it with no big troubles and no significant increase in CPU and RAM usage. The tests were performed on an iPhone 3GS, an iPhone 4 and an iPad.

But there was no way I could make it work with 5 or 6 streams. Only 4 of them would start, randomly. Two streams kept missing every time.

### Hardware limitation
After days and days of trying, and searching for a solution, I stumbled upon something I was not expecting at all: an undocumented limitation. It turns out Apple limits the maximum concurrent streams on iOS to 4 streams. The limit is due to the available number of render pipelines which are limited by the hardware. There is no way to have 6 parallel streams.

### Deep dive
This didn't stop me, of course. I still had one more problem, called "Gstreamer". Even without this undocumented limitation, the default players we have on iOS don't have support for this type of video streaming.

### Gstreamer
Gstreamer uses Gstreamer Data Protocol for serialization. One GDP packet would look like this:

![Gstreamer Data Protocol packet](https://developer.gnome.org/gstreamer-libs/0.10/gdp-header.png)

This image might scare some people. Working with low-level protocols is not something everybody enjoys. Fortunately, I'm not of them. I did play with some low-level protocols like TCP/IP and I've created my own serialization protocols just for fun.

## The light at the end of the tunnel
While trying to parse the GDP streaming, a crazy idea popped into my head. Let's imagine each of these GDP packets contains one frame/image of the streaming video (which is almost the case). What would happen if we deserialize each frame and we update the content of an UIImageView with the image it contains?

This sounds almost like a video. After all, a video, to put it simply, is a series of images shown at a particular speed in a particular order.

And this was the inspiration to build a custom iOS player. This player would support Gstreamer, and would not care about the undocumented hardware limitation.

## Code
The code located in the `src` folder contains the main parts to make this player work. I've split the code into 3 components:
- `GDPParser` - deserializes the streaming data and parses it. I've used C here for more memory control and better performance.
- `FrameDecoder` - decodes the data received from the GDPParser and builds an image from it. This part gave me some headaches, I had to use FFmpeg for decoding and image converting. 
- `PlayerController` - orchestrates the work of the above two componnets. It calls the `GDPParser` when data is received, decodes the received data using `FrameDecoder`, and updates the UIImage of the player.

There are two things to mention here:
- I skipped the networking part, but the main point here is to connect the streaming data handling to the `PlayersController`'s `streamingDataReceived` method.
- `FrameDecoder` makes use of the FFmpeg library.

### FFmpeg
The project depends on the FFmpeg libraries. You will need to build them and add them to the project.
You'll also need the FFmpeg libraries' headers and Xcode to know where to locate them. This you can specify in Build Settings, search for Header Paths.

To build the FFmpeg libraries, you'll need to download them first from https://github.com/FFmpeg/FFmpeg.
Then, use the following build script (you need to be in the FFmpeg folder):
```
./configure --extra-ldflags=-L/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.0.sdk/usr/lib/system --disable-bzlib --disable-doc  --enable-cross-compile --arch=arm --target-os=darwin --cc=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc --as='gas-preprocessor/gas-preprocessor.pl /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc' --sysroot=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.0.sdk --cpu=cortex-a8 --extra-cflags='-arch armv7' --extra-ldflags='-arch armv7' --enable-pic  --disable-zlib --disable-bzlib  --enable-decoder=h264 --enable-demuxer=h264 --enable-parser=h264
```
This is valid for the current version of FFmpeg, which is 0.5.x. For future versions this might change, most probably it will.

## Conclusion
Building an iOS custom player is deffinitely not an easy task. But with enough passion, inspiration, and patience, this is doable.
Of course there is a lot left to be done. You need to handle streaming errors, maybe handle each video stream in a different thread, and build a beautiful UI.