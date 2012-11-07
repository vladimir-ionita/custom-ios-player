# About
This project showcases a limitation of iOS 5 regarding multiple parallel video streams and a solution for the problem.

## Intro
There are lots of times when our SDKs are limited and can't satisfy our needs. Sometimes this stops us from implementing great ideas, other times it makes us go to a certain length and implement solutions out of the box.


## The Task
The task for this project is to build an iOS application that would support displaying multiple (up to 6) live cameras on the same screen, streaming through Gstreamer Data Protocol (GDP from here on). In simpler words, a video surveillance application.


## Task Analysis
The iOS SDK offers two solutions for managing the playback of a video, be it from a file or from a network stream.
1. The first and the most straightforward one is the MPMoviePlayerController. This is a great player, but it has some drawbacks:
- you can't customize its size for iPhone;
- only one stream can be played at a time;
- it doesn't support Gstreamer Data Protocol.
2. The second solution is the AVPlayer. It is more advanced, a bit more complex and requires more effort to use. From  Apple  documentation,  it  can  be  noted  that,  indeed,  this  player  can  have  multiple  instances playing different sources at the same time, and every instance can have its custom size. It seems the only problem would be the support for GDP.

As there is no way to support GDP, we will have to change the streaming to RTSP. It might be a huge effort, but it's the backend guys' problem :) and there is no other way to do it.

## Testing AVPlayer
The testing for AVPlayer went quite good. At the beginning.
It worked perfectly with 2 streams, the device could handle it with no big troubles and no signifact increase in CPU and RAM usage, both in a normal range. It was tested on iPhone 3GS, iPhone 4 and iPad.
The same with 3 and 4 streams. But there was no way I can make it work with 5 or 6 streams. It started only 4 of them, randomly. Two streams kept be missing.
First, the code was checked multiple times, and rewritten. But the problem persisted. I kept thinking the problem is in the code, or at most, maybe in some configurations.

## The limitation
After days and days of trying, I stumbled upon an undocumented limitation. Thank you, Apple, for keeping this to you.
Apple limits the maximum concurrent streams on iOS to 4 streams. The limit is due to the available number of render pipelines which are limited by the hardware. So here it is the limitation, which, in this case, is more related to the hardware than the software. No way we can have 6 parallel streams. Or can we?

## Alternative solutions
It would be a pitty to cancel the project, but there are not a lot of options here.
One alternative solution would be to combine the videos of multiple cameras on the backend side and stream the combination. It would require the application to communicate with the backend on what cameras are in use, and there would be some mechanism to be build to synchronize and to know for the app when to change the size of a stream to fit two combined cameras. The zooming implementation would also be a bit problematic. For sure, there will be lots of things to be implemented. This is a huge change and implies a lot of additional complexity. For some, this would be a feasible solution, but in our case it was a no-go. The project dies if we can't find another solution.

One option could be to check the available third-party players. Although if you're limited by the hardware ability to render, it's not clear if other players would be able to stream more than 4 concurrent videos.

Oh, and one more thing: in the meantime it was decided we have another limitation for the project: we have to use GDP for streaming, there is no other way. Now, how many third-party players that can stream more than 4 concurrent videos will support GDP? Checkmate.

## What is Gstreamer Data Protocol?
The GDP Protocol is used for serialization of caps (lightweight refcounted objects describing media types), buffers and events. And a GDP segment looks like this:
https://developer.gnome.org/gstreamer-libs/0.10/gdp-header.png
