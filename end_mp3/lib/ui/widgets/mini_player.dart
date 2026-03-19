import 'package:end_mp3/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import 'package:audioplayers/audioplayers.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerProvider);

    if (currentSong == null) return const SizedBox.shrink();

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ]
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: audio.QueryArtworkWidget(
            id: currentSong.id, 
            type: audio.ArtworkType.AUDIO,
            nullArtworkWidget: Container(
              width: 50,
              height: 50,
              color: AppColors.cardGrey, // Si definiste cardGrey, si no usa AppColors.surface
              child: const Icon(Icons.music_note, color: AppColors.primary),
            ),
            errorBuilder: (context, exception, stackTrace) => Container(
              width: 50,
              height: 50,
              color: AppColors.surface,
              child: const Icon(Icons.broken_image, color: AppColors.error),
            ),
          ),
        ),
        title: Text(currentSong.title, 
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(currentSong.artist, 
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: StreamBuilder<PlayerState>(
          stream: ref.read(playerProvider.notifier).stateStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data == PlayerState.playing;
            return IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                color: AppColors.textPrimary,
                size: 32,
              ),
              onPressed: () => ref.read(playerProvider.notifier).togglePlay(),
            );
          },
        ),
      ),
    );
  }
}