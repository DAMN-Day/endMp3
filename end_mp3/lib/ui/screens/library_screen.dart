import 'package:end_mp3/core/app_colors.dart';
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
    final songs = ref.watch(libraryProvider);
    final albums = ref.watch(albumsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
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

          songs.isEmpty 
          ? const SliverFillRemaining(
              child: Center(child: Text("No hay canciones. Toca el botón para escanear.", 
                style: TextStyle(color: AppColors.textSecondary))),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: audio.QueryArtworkWidget(
                        id: song.id,
                        type: audio.ArtworkType.AUDIO,
                        format: audio.ArtworkFormat.JPEG,
                        nullArtworkWidget: Container(
                          width: 50,
                          height: 50,
                          color: AppColors.surface,
                          child: const Icon(Icons.music_note, color: AppColors.primary),
                        ),
                      ),
                    ),
                    title: Text(song.title, 
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("${song.artist} • ${song.album}", 
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => ref.read(playerProvider.notifier).playSong(song),
                  );
                },
                childCount: songs.length,
              ),
            ),
        ],
      ),
      floatingActionButton: songs.isEmpty 
        ? FloatingActionButton.extended(
            onPressed: () => ref.read(libraryProvider.notifier).pickMusicDirectory(),
            label: const Text("Escanear Música", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.folder_open, color: Colors.black),
            backgroundColor: AppColors.primary,
          )
        : null,
      bottomNavigationBar: const MiniPlayer(),
    );
  }

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
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, 
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
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
        title: const Text("Ponle nombre a tu playlist", style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
        content: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          cursorColor: AppColors.primary,
          decoration: const InputDecoration(
            hintText: "Mi playlist #1",
            hintStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textSecondary)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CREAR", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}