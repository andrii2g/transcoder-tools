# References

This page collects external references that helped shape `vtx` behavior and future planning around `ffmpeg`, multi-output transcoding, HLS, CORS, and playback validation.

## FFmpeg fundamentals

- [FFmpeg filters: split and asplit](https://ffmpeg.org/ffmpeg-filters.html#split_002c-asplit)
- [Creating multiple outputs with FFmpeg](https://trac.ffmpeg.org/wiki/Creating%20multiple%20outputs)
- [Encode videos with FFmpeg](https://digitalfortress.tech/tricks/encode-videos-with-ffmpeg/)
- [How to use FFmpeg to encode video in H.264](https://stackoverflow.com/questions/37066553/how-to-use-ffmpeg-to-encode-video-in-h-264)
- [Converting video from 1080p to 720p with smallest quality loss](https://superuser.com/questions/714804/converting-video-from-1080p-to-720p-with-smallest-quality-loss-using-ffmpeg)

## Multi-output and HLS

- [Using FFmpeg as a HLS streaming server, part 3: multiple bitrates](https://www.martin-riedl.de/2018/08/25/using-ffmpeg-as-a-hls-streaming-server-part-3/)
- [Using FFmpeg as a HLS streaming server, part 4: multiple video resolutions](https://www.martin-riedl.de/2018/08/26/using-ffmpeg-as-a-hls-streaming-server-part-4-multiple-video-resolutions/)
- [Using FFmpeg as a HLS streaming server, part 5: folder structure](https://www.martin-riedl.de/2018/08/30/using-ffmpeg-as-a-hls-streaming-server-part-5-folder-structure/)
- [Using FFmpeg as a HLS streaming server, part 6: independent segments](https://www.martin-riedl.de/2018/09/13/using-ffmpeg-as-a-hls-streaming-server-part-6-independent-segments/)
- [An FFmpeg script to render and package a complete HLS presentation](https://streaminglearningcenter.com/blogs/an-ffmpeg-script-to-render-and-package-a-complete-hls-presentation.html)
- [How to encode one input file to multiple HLS streams with FFmpeg](https://superuser.com/questions/1296836/how-to-encode-one-input-file-to-multiple-hls-streams-with-ffmpeg-including-the-m)
- [FFmpeg tee muxer fails on multiple outputs, HLS and MP4](https://superuser.com/questions/1453004/ffmpeg-tee-muxer-fails-on-multiple-outputs-hls-and-mp4)
- [Creating HLS variants with FFmpeg](https://stackoverflow.com/questions/33225026/creating-hls-variants-with-ffmpeg)
- [Add PNG overlay to multi-output HLS m3u8 with FFmpeg](https://stackoverflow.com/questions/51088697/add-png-overlay-to-multi-output-hls-m3u8-with-ffmpeg?rq=1)
- [FFmpeg user mailing list thread on multi-output/HLS behavior](http://mplayerhq.hu/pipermail/ffmpeg-user/2019-July/044917.html)
- [Creating a master playlist with FFmpeg](https://hlsbook.net/creating-a-master-playlist-with-ffmpeg/)
- [Master playlist points to only one resolution among multiple](https://superuser.com/questions/1429555/master-playlist-generate-points-to-only-one-resolution-among-multiple)
- [Manipulating one video into multi outputs results in no audio in output](https://stackoverflow.com/questions/33343795/manipulating-one-video-into-multi-outputs-with-ffmpeg-results-in-no-audio-in-the)

## Filter graphs, stream mapping, and concat troubleshooting

- [FFmpeg optional audio stream mapping](https://superuser.com/questions/753703/ffmpeg-map-optional-audio-stream)
- [FFmpeg ignores yadif filter when using filter on command line](https://video.stackexchange.com/questions/25662/ffmpeg-exe-ignores-yadif-filter-when-using-1-filter-on-the-command-line)
- [Merging several videos with and without audio channels](https://superuser.com/questions/1044988/merging-several-videos-with-audio-channel-and-without-audio)
- [Concat two audio files via FFmpeg filter_complex](https://superuser.com/questions/841062/concat-two-audio-files-via-ffmpeg-filter-complex)
- [FFmpeg filter_complex chaining: watermark, trim, and join](https://superuser.com/questions/1072486/ffmpeg-filter-complex-chaining-video-streams-watermark-then-trim-and-join)
- [Join multiple video files with and without audio](https://superuser.com/questions/729991/join-multiple-video-files-two-witout-audio-and-three-with-audio)
- [Creating GIF with FFmpeg produces unplayable GIF](https://superuser.com/questions/1138178/cant-make-a-gif-using-ffmpeg-produces-a-gif-but-it-isnt-playable)
- [Correctly combine FFmpeg file pattern and complex filter](https://stackoverflow.com/questions/32936421/how-to-correctly-combine-ffmpeg-file-pattern-and-complex-filter)
- [Stream specifier in filtergraph description matches errors](https://stackoverflow.com/questions/45068155/stream-specifier-v0-in-filtergraph-description-1v0-1a0-2v0-2a)
- [FFmpeg stream specifier in filtergraph description matches no streams](https://stackoverflow.com/questions/48577309/ffmpeg-version-2-6-8-stream-specifier-a-in-filtergraph-description-matches)
- [FFmpeg concatenation filter stream specifier matches no streams](https://stackoverflow.com/questions/19417412/ffmpeg-concatenation-filters-stream-specifier-0-in-filtergraph-matches-no-st)
- [Invalid file index in filtergraph description](https://stackoverflow.com/questions/55725431/i-have-a-problem-withinvalid-file-index-1-in-filtergraph-description)

## CORS and HLS hosting

- [MDN CORS documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [AWS Elastic Encoder HLS streaming CloudFront crossdomain issue](https://stackoverflow.com/questions/55502725/aws-elastic-encoder-hls-streaming-cloudfront-crossdomain-issue)
- [CORS configuration for S3-hosted HLS video in JW Player](https://stackoverflow.com/questions/53800705/cors-configuration-for-s3-hosted-hls-video-in-jw-player)

## HLS players and validators

- [hls.js](https://github.com/dailymotion/hls.js)
- [Akamai stream validator](https://players.akamai.com/stream-validator)
- [Akamai players](https://players.akamai.com/players)
