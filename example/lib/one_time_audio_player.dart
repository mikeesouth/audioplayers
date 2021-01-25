import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OneTimeAudioPlayer {
  static int _filenameCounter = 0;

  final _audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
  final _completer = Completer();
  File _file;
  Duration _currentPosition = Duration.zero;

  OneTimeAudioPlayer() {
    if (Platform.isIOS) {
      // Not sure if this is needed but it is set in the example code
      _audioPlayer.startHeadlessService();
    }

    _audioPlayer.onPlayerStateChanged.listen((s) async {
      if (s == AudioPlayerState.COMPLETED) {
        print('Deleting _file.path = ${_file.path}');
        await _file.delete();
        _completer.complete();
      }
    });

    _audioPlayer.onPlayerError.listen((s) async {
      print('onPlayerError: $s');
      print('await _file.exists() = ${await _file.exists()}');
      await _file.delete();
      _completer.complete();
    });
  }

  Duration getCurrentPosition() {
    return _currentPosition;
  }

  Future<void> playAndWait() async {
    _currentPosition = Duration.zero;

    final data = await rootBundle.load('assets/test.mp3');
    _file = await _writeTempFile(data, 'mp3');

    print('Playing _file.path = ${_file.path}');
    if (!await _file.exists()) {
      // This does not happen on iOS when we get AVPlayerStatus.Item.Failed
      throw new Exception('File does not exist');
    }
    try {
      await _audioPlayer.play(_file.path, isLocal: true);
    } on PlatformException catch (e) {
      // This does not happen on iOS when we get AVPlayerStatus.Item.Failed
      print('Got PlatformException: $e');
    } catch (e) {
      // This does not happen on iOS when we get AVPlayerStatus.Item.Failed
      print('Got exception: $e');
    }

    // Return completer future instead of 50ms delay to play sound in sequence.
    // await Future.delayed(Duration(milliseconds: 50));
    return _completer.future;
  }

  Future<void> stopAudio() async {
    // Forcefully stop playing
    await _audioPlayer.stop();
  }

  Future<File> _writeTempFile(ByteData data, String ext) async {
    final tempDir = await getTemporaryDirectory();
    final unique = ++_filenameCounter;
    final file = File('${tempDir.path}/sound-$unique.$ext');
    await writeToFile(file, data);

    return file;
  }

  Future<void> writeToFile(File file, ByteData data) async {
    final buffer = data.buffer;
    await file.writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
