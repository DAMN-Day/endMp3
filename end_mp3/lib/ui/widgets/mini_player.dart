import 'package:end_mp3/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import 'package:audioplayers/audioplayers.dart';
import '../screens/now_playing_screen.dart'; // Asegúrate de importar tu nueva pantalla

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    if (currentSong == null) return const SizedBox.shrink();

    return Container(
      height: 72, // Ajustado para la barra más ancha
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Detecta el toque en toda el área
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // Para que la barra no se salga de las esquinas
          child: Column(
            children: [
              // 1. BARRA DE PROGRESO REAL (ANCHA)
              StreamBuilder<Duration>(
                stream: playerNotifier.positionStream,
                builder: (context, snapshotPos) {
                  final position = snapshotPos.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: playerNotifier.durationStream,
                    builder: (context, snapshotDur) {
                      final duration = snapshotDur.data ?? Duration.zero;
                      
                      double progress = 0.0;
                      if (duration.inMilliseconds > 0) {
                        progress = position.inMilliseconds / duration.inMilliseconds;
                      }

                      return LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 4, // Ancha como pediste
                      );
                    },
                  );
                },
              ),

              // 2. CONTENIDO (Info y Controles)
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  leading: _AlbumArt(songId: currentSong.id),
                  title: Text(
                    currentSong.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    currentSong.artist,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _PlayPauseButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS DE APOYO ---

class _AlbumArt extends StatelessWidget {
  final int songId;
  const _AlbumArt({required this.songId});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 48,
        height: 48,
        child: audio.QueryArtworkWidget(
          id: songId,
          type: audio.ArtworkType.AUDIO,
          format: audio.ArtworkFormat.JPEG,
          size: 200,
          quality: 100,
          nullArtworkWidget: Container(
            color: Colors.white10,
            child: const Icon(Icons.music_note, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<PlayerState>(
      stream: ref.read(playerProvider.notifier).stateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data == PlayerState.playing;
        return IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: AppColors.textPrimary,
            size: 36,
          ),
          onPressed: () => ref.read(playerProvider.notifier).togglePlay(),
        );
      },
    );
  }
}