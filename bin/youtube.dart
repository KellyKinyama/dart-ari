import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoUrl = 'https://youtu.be/FMh8qNV3PHk';

  try {
    // 1. Get video metadata
    print('Fetching video metadata...');
    var video = await yt.videos.get(videoUrl);

    // 2. Get the stream manifest (available qualities and formats)
    var manifest = await yt.videos.streamsClient.getManifest(video.id);

    // 3. Select the best muxed stream (video + audio combined)
    var streamInfo = manifest.muxed.withHighestBitrate();

    if (streamInfo != null) {
      // 4. Create a file to save the video
      // Clean the title to remove characters that are illegal in filenames
      var fileName = '${video.title}.${streamInfo.container.name}'
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
      var file = File(fileName);
      var output = file.openWrite();

      // 5. Download the stream
      print('Downloading: ${video.title}');
      var stream = yt.videos.streamsClient.get(streamInfo);

      await for (final data in stream) {
        output.add(data);
      }

      await output.close();
      print('Download complete! Saved as $fileName');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    // Always close the YoutubeExplode client to clean up resources
    yt.close();
  }
}
