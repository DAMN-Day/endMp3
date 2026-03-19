import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/models/song_model.dart';
import 'library_provider.dart'; // <--- Importante para playNext/Previous

part 'player_provider.g.dart';

@riverpod
class Player extends _$Player {
  // 1. Definimos el reproductor
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 2. STREAMS para la UI (MiniPlayer y NowPlaying)
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;
  Stream<PlayerState> get stateStream => _audioPlayer.onPlayerStateChanged;

  @override
  SongModel? build() {
    // Escucha automática al terminar una canción
    _audioPlayer.onPlayerComplete.listen((event) {
      playNext();
    });
    return null;
  }

  // MÉTODO: REPRODUCIR
  Future<void> playSong(SongModel song) async {
    try {
      state = song;
      await _audioPlayer.play(DeviceFileSource(song.path));
    } catch (e) {
      // Manejo de errores (opcional)
      print("Error al reproducir la canción: $e");
    }
  }

  // MÉTODO: PAUSA / REANUDAR
  void togglePlay() async {
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  // MÉTODO: ADELANTAR/ATRASAR
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // MÉTODO: SIGUIENTE
  void playNext() {
    final allSongs = ref.read(libraryProvider);
    if (state == null || allSongs.isEmpty) return;

    final currentIndex = allSongs.indexWhere((s) => s.id == state!.id);

    if (currentIndex < allSongs.length - 1) {
      playSong(allSongs[currentIndex + 1]);
    } else {
      playSong(allSongs.first);
    }
  }

  // MÉTODO: ANTERIOR
  void playPrevious() {
    final allSongs = ref.read(libraryProvider);
    if (state == null || allSongs.isEmpty) return;

    final currentIndex = allSongs.indexWhere((s) => s.id == state!.id);

    if (currentIndex > 0) {
      playSong(allSongs[currentIndex - 1]);
    } else {
      playSong(allSongs.last);
    }
  }
}