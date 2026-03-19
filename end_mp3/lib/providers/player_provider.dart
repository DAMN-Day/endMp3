import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/models/song_model.dart';

part 'player_provider.g.dart';

@riverpod
class Player extends _$Player {
  // Cambiamos AudioPlayer de just_audio por el de audioplayers
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Transmite la posición actual (segundo a segundo)
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  // Transmite la duración total de la canción
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;
  // Transmite si está reproduciendo, pausado o detenido
  Stream<PlayerState> get stateStream => _audioPlayer.onPlayerStateChanged;

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

}