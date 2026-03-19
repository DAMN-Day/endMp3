
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio; 
import '../data/models/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'library_provider.g.dart';

@riverpod
class Library extends _$Library {
  final audio.OnAudioQuery _audioQuery = audio.OnAudioQuery();
  static const String _dirKey = 'selected_directory'; // Llave para la memoria

  @override
  List<SongModel> build() {
    // Al iniciar, intentamos cargar automáticamente
    _autoLoadLibrary();
    return [];
  }

  Future<void> _autoLoadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDir = prefs.getString(_dirKey);
    
    if (savedDir != null) {
      // Si hay una ruta guardada, escaneamos sin preguntar al usuario
      await _scanDirectory(savedDir);
    }
  }

  Future<void> pickMusicDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      // Guardamos la ruta en la memoria del teléfono
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dirKey, selectedDirectory);
      
      await _scanDirectory(selectedDirectory);
    }
  }

  // Movimos la lógica de escaneo a una función aparte para reutilizarla
  Future<void> _scanDirectory(String directory) async {
    bool hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      hasPermission = await _audioQuery.permissionsRequest();
    }

    if (hasPermission) {
      List<audio.SongModel> deviceSongs = await _audioQuery.querySongs(
        sortType: audio.SongSortType.TITLE,
        orderType: audio.OrderType.ASC_OR_SMALLER,
        uriType: audio.UriType.EXTERNAL,
      );

      final List<SongModel> filteredSongs = deviceSongs
          .where((s) => s.data.contains(directory))
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
// Estos providers se mantienen igual, usando TU SongModel
final albumsProvider = Provider<List<String>>((ref) {
  final songs = ref.watch(libraryProvider);
  return songs.map((s) => s.album).toSet().toList();
});