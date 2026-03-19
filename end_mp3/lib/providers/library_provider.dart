import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:file_picker/file_picker.dart';
// 1. Le ponemos el alias 'audio' a la librería externa
import 'package:on_audio_query/on_audio_query.dart' as audio; 
import '../data/models/song_model.dart';

part 'library_provider.g.dart';

@riverpod
class Library extends _$Library {
  // 2. Usamos el alias para la instancia
  final audio.OnAudioQuery _audioQuery = audio.OnAudioQuery();

  @override
  List<SongModel> build() => [];

  Future<void> pickMusicDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      bool hasPermission = await _audioQuery.permissionsStatus();
      if (!hasPermission) {
        hasPermission = await _audioQuery.permissionsRequest();
      }

      if (hasPermission) {
        // 3. Aquí especificamos que el resultado es la lista de la librería 'audio'
        List<audio.SongModel> deviceSongs = await _audioQuery.querySongs(
          sortType: audio.SongSortType.TITLE,
          orderType: audio.OrderType.ASC_OR_SMALLER,
          uriType: audio.UriType.EXTERNAL,
        );

        // 4. Filtramos y convertimos a TU SongModel (el de tu archivo local)
        final List<SongModel> filteredSongs = deviceSongs
            .where((s) => s.data.startsWith(selectedDirectory))
            .map((s) => SongModel(
                  id: s.id,
                  title: s.title,
                  artist: s.artist ?? "Artista Desconocido",
                  album: s.album ?? "Álbum Desconocido",
                  path: s.data,
                  albumArt: s.id.toString(),
                ))
            .toList();

        state = filteredSongs;
      }
    }
  }
}

// Estos providers se mantienen igual, usando TU SongModel
final albumsProvider = Provider<List<String>>((ref) {
  final songs = ref.watch(libraryProvider);
  return songs.map((s) => s.album).toSet().toList();
});