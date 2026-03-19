import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/library_provider.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import 'package:end_mp3/providers/player_provider.dart';
import 'package:end_mp3/ui/widgets/mini_player.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos los dos providers: la lista completa y los álbumes únicos
    final songs = ref.watch(libraryProvider);
    final albums = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // 1. App Bar Estilo Spotify
          SliverAppBar(
            backgroundColor: const Color(0xFF121212),
            floating: true,
            pinned: false,
            elevation: 0,
            title: const Text('Tu biblioteca', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            actions: [
              IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white), 
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            ],
          ),

          // 2. Sección de Cuadros (Álbumes / Me Gusta)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                // Mostramos "Mis Me Gusta" + los primeros 5 álbumes encontrados
                itemCount: (albums.length > 5 ? 6 : albums.length + 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _quickActionCard("Tus me gusta", Icons.favorite, Colors.deepPurple);
                  }
                  final albumName = albums[index - 1];
                  return _quickActionCard(albumName, Icons.album, Colors.blueGrey);
                },
              ),
            ),
          ),

          // 3. Pestañas de Filtro Rápidas
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: ['Playlists', 'Artistas', 'Álbumes'].map((label) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    backgroundColor: const Color(0xFF282828),
                    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                )).toList(),
              ),
            ),
          ),

          // 4. Lista de Canciones Reales
          songs.isEmpty 
          ? const SliverFillRemaining(
              child: Center(child: Text("No hay canciones. Toca el botón para escanear.", 
                style: TextStyle(color: Colors.grey))),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4), // Bordes redondeados estilo Spotify
                              child: audio.QueryArtworkWidget(
                                id: song.id, // El ID que sacamos en el provider
                                type: audio.ArtworkType.AUDIO,       // Le decimos que busque en el audio
                                format: audio.ArtworkFormat.JPEG,
                                nullArtworkWidget: Container(           // Si la canción no tiene foto, sale esto:
                                  width: 50,
                                  height: 50,
                                  color: const Color(0xFF282828),
                                  child: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                                ),
                              ),
                            ),
                    title: Text(song.title, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("${song.artist} • ${song.album}", 
                      style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      // Aquí irá la lógica para reproducir
                      ref.read(playerProvider.notifier).playSong(song);
                    },
                  );
                },
                childCount: songs.length,
              ),
            ),
        ],
      ),
      
      
      // Botón flotante para escanear si la lista está vacía
      floatingActionButton: songs.isEmpty 
        ? FloatingActionButton.extended(
            onPressed: () => ref.read(libraryProvider.notifier).pickMusicDirectory(),
            label: const Text("Escanear Música", style: TextStyle(color: Colors.black)),
            icon: const Icon(Icons.folder_open, color: Colors.black),
            backgroundColor: const Color(0xFF1DB954),
          )
        : null,
        bottomNavigationBar: const MiniPlayer(),
    );
  }

  // Componente para los cuadros pequeños de arriba
  Widget _quickActionCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4))
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // Diálogo para crear Playlist (Botón +)
  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ponle nombre a tu playlist", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFF1DB954),
          decoration: const InputDecoration(
            hintText: "Mi playlist #1",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1DB954))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CREAR", style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}