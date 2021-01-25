import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OneTimeAudioPlayer2 {
  static const POOL_SIZE = 20;
  // These player pools will never be disposed, they will (intentionally) live
  // for the entire application lifetime.
  static List<AudioPlayer> _playerPool;
  static int _poolIndex = 0;
  static int _filenameCounter = 0;

  final _completer = Completer();
  File _file;
  Duration _currentPosition = Duration.zero;
  int _currentPoolIndex;

  StreamSubscription<AudioPlayerState> _subStateChange;
  StreamSubscription<String> _subPlayerError;

  AudioPlayer get _currentPlayer => _playerPool[_currentPoolIndex];

  OneTimeAudioPlayer2() {
    if (_playerPool == null) {
      _playerPool = List.generate(
        POOL_SIZE,
        (idx) {
          final ap = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
          if (Platform.isIOS) {
            // Not sure if this is needed but it is set in the example code
            ap.startHeadlessService();
          }

          return ap;
        },
      );
    }
    _currentPoolIndex = _poolIndex++;
    if (_poolIndex >= POOL_SIZE) _poolIndex = 0;
    print('Using pool index = $_currentPoolIndex');

    _subStateChange =
        _currentPlayer.onPlayerStateChanged.listen(_handleStateChange);
    _subPlayerError = _currentPlayer.onPlayerError.listen(_handlePlayerError);
  }

  Future<void> _handleStateChange(AudioPlayerState s) async {
    if (s == AudioPlayerState.COMPLETED || s == AudioPlayerState.STOPPED) {
      await _handleSoundCompleted();
    }
  }

  Future<void> _handlePlayerError(String s) async {
    print('onPlayerError: $s');
    // await _handleSoundCompleted();
  }

  Duration getCurrentPosition() {
    return _currentPosition;
  }

  Future _handleSoundCompleted() async {
    _subPlayerError.cancel();
    _subStateChange.cancel();
    print('Deleting _file.path = ${_file.path}');
    await _file.delete();
    _completer.complete();
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
      await _currentPlayer.play(_file.path, isLocal: true);
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
    await _currentPlayer.stop();
  }

  Future<File> _writeTempFile(ByteData data, String ext) async {
    final tempDir = await getTemporaryDirectory();
    final unique = ++_filenameCounter;
    final file = File('${tempDir.path}/sound2-$unique.$ext');
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
}
