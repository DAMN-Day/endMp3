import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/models/song_model.dart';
import 'library_provider.dart'; 

part 'player_provider.g.dart';

@riverpod
class Player extends _$Player {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _currentPlaylist = [];

  // Getters para la UI
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;
  Stream<PlayerState> get stateStream => _audioPlayer.onPlayerStateChanged;

  @override
  SongModel? build() {
    _audioPlayer.onPlayerComplete.listen((event) {
      playNext();
    });
    return null;
  }

  // MÉTODO: REPRODUCIR
  Future<void> playSong(SongModel song, {List<SongModel>? playlist}) async {
    try {
      await _audioPlayer.stop(); 
      state = song;

      // ORDENAMIENTO POR TRACK
      if (playlist != null) {
        List<SongModel> sortedPlaylist = List.from(playlist);
        sortedPlaylist.sort((a, b) {
          // Si tu SongModel usa otro nombre, cámbialo aquí (ej. a.trackNumber)
          final int trackA = a.track ?? 0;
          final int trackB = b.track ?? 0;
          return trackA.compareTo(trackB);
        });
        _currentPlaylist = sortedPlaylist;
      } else if (_currentPlaylist.isEmpty) {
        _currentPlaylist = ref.read(libraryProvider);
      }

      await _audioPlayer.setSource(DeviceFileSource(song.path));
      await _audioPlayer.resume();

      // Despertador de metadatos
      Future.delayed(const Duration(milliseconds: 600), () async {
         await _audioPlayer.getDuration();
      });
      
    } catch (e) {
      debugPrint("Error al reproducir: $e");
    }
  }

  // MÉTODO: SIGUIENTE
  void playNext() {
    if (state == null || _currentPlaylist.isEmpty) return;

    final currentIndex = _currentPlaylist.indexWhere((s) => s.id == state!.id);

    if (currentIndex != -1 && currentIndex < _currentPlaylist.length - 1) {
      playSong(_currentPlaylist[currentIndex + 1]);
    } else {
      playSong(_currentPlaylist.first); 
    }
  }

  // MÉTODO: ANTERIOR
  void playPrevious() {
    if (state == null || _currentPlaylist.isEmpty) return;

    final currentIndex = _currentPlaylist.indexWhere((s) => s.id == state!.id);

    if (currentIndex > 0) {
      playSong(_currentPlaylist[currentIndex - 1]);
    } else {
      playSong(_currentPlaylist.last); 
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

  // MÉTODO: BUSCAR (SEEK)
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }
}