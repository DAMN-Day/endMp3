import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/models/song_model.dart';

part 'player_provider.g.dart';

@riverpod
class Player extends _$Player {
  // Cambiamos AudioPlayer de just_audio por el de audioplayers
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  SongModel? build() {
    return null;
  }

  Future<void> playSong(SongModel song) async {
    try {
      state = song;
      // En audioplayers se usa DeviceFileSource para archivos locales
      await _audioPlayer.play(DeviceFileSource(song.path));
    } catch (e) {
      print("Error: $e");
    }
  }

  void togglePlay() async {
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  // Stream simplificado para la UI
  Stream<PlayerState> get stateStream => _audioPlayer.onPlayerStateChanged;
}