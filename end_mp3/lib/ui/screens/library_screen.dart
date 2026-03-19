import 'package:end_mp3/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/library_provider.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import 'package:end_mp3/providers/player_provider.dart';
import 'package:end_mp3/ui/widgets/mini_player.dart';
import 'package:end_mp3/data/models/song_model.dart';
import 'package:end_mp3/ui/screens/album_detail_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(libraryProvider);
    final albums = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            pinned: false,
            elevation: 0,
            title: const Text('Tu biblioteca', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            actions: [
              IconButton(icon: const Icon(Icons.search, color: AppColors.textPrimary), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textPrimary), 
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            ],
          ),

          // 2. Sección de Cuadros Rápidos (Me gusta, etc.)
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
                itemCount: 1, // Simplificado a 2 por ahora para no saturar
                itemBuilder: (context, index) {
                  return _quickActionCard("Tus me gusta", Icons.favorite, Colors.deepPurple);
                },
              ),
            ),
          ),

          // 3. Pestañas de Filtro
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: ['Playlists', 'Artistas', 'Álbumes'].map((label) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    backgroundColor: AppColors.surface,
                    label: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                )).toList(),
              ),
            ),
          ),

          // 4. CUADRÍCULA DE ÁLBUMES (3 POR ANCHO)
          songs.isEmpty 
          ? const SliverFillRemaining(
              child: Center(child: Text("No hay canciones. Escanea tu música.", 
                style: TextStyle(color: AppColors.textSecondary))),
            )
            
          : SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.7, // Mantenemos 0.7 para que el cuadro sea cuadrado + espacio para texto
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final albumName = albums[index];
                  final firstSongInAlbum = songs.firstWhere((s) => s.album == albumName);
              
                  return GestureDetector(
                    onTap: () {
                      // NAVEGACIÓN AL ÁLBUM
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlbumDetailScreen(
                            albumName: albumName,
                            albumSongs: songs.where((s) => s.album == albumName).toList(),
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.0, // Fuerza a que sea un cuadrado
                          child: audio.QueryArtworkWidget(
                            id: firstSongInAlbum.id,
                            type: audio.ArtworkType.AUDIO,
                            // --- AQUÍ ESTÁ EL TRUCO DE LA CALIDAD ---
                            format: audio.ArtworkFormat.JPEG, // JPEG suele tener mejor compatibilidad
                            quality: 100,                     // Subimos la calidad al máximo (0-100)
                            size: 500,                        // Pedimos un tamaño mayor (por defecto es 200)
                            // ----------------------------------------
                            nullArtworkWidget: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4), // Un radio muy pequeño o 0 para que sea cuadrado
                              ),
                              child: const Icon(Icons.album, color: AppColors.primary, size: 50),
                            ),
                            // Forzamos que la imagen use todo el espacio sin bordes redondeados
                            artworkBorder: BorderRadius.circular(4), 
                            artworkFit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(albumName, 
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(firstSongInAlbum.artist, 
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
                childCount: albums.length,
              ),
            ),
          ),
            
            // Espacio para que el miniplayer no tape el último álbum
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: songs.isEmpty 
        ? FloatingActionButton.extended(
            onPressed: () => ref.read(libraryProvider.notifier).pickMusicDirectory(),
            label: const Text("Escanear", style: TextStyle(color: Colors.black)),
            icon: const Icon(Icons.folder_open, color: Colors.black),
            backgroundColor: AppColors.primary,
          )
        : null,
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  // --- Mismos Widgets de apoyo ---

  Widget _quickActionCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, 
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 10),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Nueva Playlist", style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        content: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: "Nombre de la playlist",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CREAR", style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }
}