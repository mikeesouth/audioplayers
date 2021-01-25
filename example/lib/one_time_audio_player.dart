import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OneTimeAudioPlayer {
  static int _filenameCounter = 0;

  Duration _currentPosition = Duration.zero;
  final _audioPlayer = AudioPlayer();
  final _completer = Completer();
  File _file;

  OneTimeAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((s) async {
      if (s == AudioPlayerState.COMPLETED) {
        print('deleting _file.path = ${_file.path}');
        await _file.delete();
        _completer.complete();
      }
    });

    _audioPlayer.onPlayerError.listen((s) {
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
      print('ERROR!  $s');
      print('ERROR!! $s');
    });

    _audioPlayer.onAudioPositionChanged.listen((Duration p) {
      _currentPosition = p;
    });
  }

  Duration getCurrentPosition() {
    return _currentPosition;
  }

  Future<void> playAndWait() async {
    _currentPosition = Duration.zero;

    final ext = 'mp3';
    final data = await rootBundle.load('assets/B_sound.mp3');

    _file = await _writeTempFile(data, ext);

    try {
      print('playing _file.path = ${_file.path}');
      await _audioPlayer.play(_file.path, isLocal: true);
    } finally {}

    // await Future.delayed(Duration(milliseconds: 50));
    return _completer.future;
  }

  Future<void> stopAudio() async {
    // Forcefully stop playing
    await _audioPlayer.stop();
  }

  Future<File> _writeTempFile(ByteData data, String ext) async {
    final tempDir = await getTemporaryDirectory();
    final unique = _filenameCounter++;
    final file = File('${tempDir.path}/speech-$unique.$ext');
    // await file.writeAsBytes(data, flush: true);
    await writeToFile(file, data);

    return file;
  }

  void writeToFile(File file, ByteData data) {
    final buffer = data.buffer;
    file.writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<void> dispose() async {
    await _completer.future;
    await _audioPlayer.dispose();
  }
}
