import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import 'package:audioplayers/audioplayers.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos cuál es la canción actual
    final currentSong = ref.watch(playerProvider);

    // Si no hay nada seleccionado, no mostramos la barra
    if (currentSong == null) return const SizedBox.shrink();

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: audio.QueryArtworkWidget(
            // Asegúrate de usar el id real de la canción, no el del albumArt si este falla
            id: currentSong.id, 
            type: audio.ArtworkType.AUDIO,
            // Esto quita las líneas cruzadas y pone un icono bonito si no hay carátula
            nullArtworkWidget: Container(
              width: 50,
              height: 50,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Color(0xFF1DB954)),
            ),
            // Si hay error cargando la imagen, que no muestre el cuadro tachado
            errorBuilder: (context, exception, stackTrace) => Container(
              width: 50,
              height: 50,
              color: Colors.grey[800],
              child: const Icon(Icons.broken_image, color: Colors.red),
            ),
          ),
        ),
        title: Text(currentSong.title, 
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(currentSong.artist, 
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: StreamBuilder<PlayerState>(
          stream: ref.read(playerProvider.notifier).stateStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data == PlayerState.playing;
            return IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: () => ref.read(playerProvider.notifier).togglePlay(),
            );
          },
        ),
      ),
    );
  }
}