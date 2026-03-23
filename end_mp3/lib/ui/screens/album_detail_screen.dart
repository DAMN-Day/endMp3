import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import '../../data/models/song_model.dart'; // TU MODELO
import '../../core/app_colors.dart';
import '../../providers/player_provider.dart';
import '../widgets/mini_player.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final String albumName;
  final List<SongModel> albumSongs;

  const AlbumDetailScreen({
    super.key, 
    required this.albumName, 
    required this.albumSongs
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 1. Cabecera con Imagen del Álbum
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(albumName, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  audio.QueryArtworkWidget(
                    id: albumSongs.first.id,
                    type: audio.ArtworkType.AUDIO,
                    format: audio.ArtworkFormat.JPEG,
                    size: 800,   // Tamaño grande para la cabecera
                    quality: 100,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(color: AppColors.surface),
                  ),
                  // Degradado para que el nombre se lea bien
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.background],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Botón de Play Principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text("${albumSongs.length} canciones", 
                    style: const TextStyle(color: AppColors.textSecondary)),
                  const Spacer(),
                  FloatingActionButton(
                    backgroundColor: AppColors.primary,
                    onPressed: () => ref.read(playerProvider.notifier).playSong(albumSongs.first),
                    child: const Icon(Icons.play_arrow, color: Colors.black, size: 30),
                  ),
                ],
              ),
            ),
          ),

          // 3. Lista de canciones
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = albumSongs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 45,
                      height: 45,
                      child: audio.QueryArtworkWidget(
                        id: song.id, // ID de la canción específica
                        type: audio.ArtworkType.AUDIO,
                        format: audio.ArtworkFormat.JPEG,
                        size: 200, // Para miniaturas, 200 está bien y ahorra RAM
                        quality: 100,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.music_note, color: AppColors.primary, size: 20),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.more_vert, color: AppColors.textSecondary), // Tres puntitos para opciones
                  onTap: () {
                    ref.read(playerProvider.notifier).playSong(
                      song, 
                      playlist: albumSongs, // <--- ESTO ES LA CLAVE
                    );
                  },
                );
              },
              childCount: albumSongs.length,
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}