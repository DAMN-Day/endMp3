import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import 'package:palette_generator/palette_generator.dart';
import 'package:audioplayers/audioplayers.dart'; // Asegura este import
import '../../core/app_colors.dart';
import '../../providers/player_provider.dart';

// Provider para el color (con cache para evitar parpadeo)
final albumColorProvider = FutureProvider.family<Color, int>((ref, songId) async {
  final artwork = await audio.OnAudioQuery().queryArtwork(songId, audio.ArtworkType.AUDIO);
  if (artwork == null) return AppColors.background;
  final palette = await PaletteGenerator.fromImageProvider(MemoryImage(artwork));
  return palette.dominantColor?.color.withOpacity(0.3) ?? AppColors.background;
});

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    
    // Solo pedimos el color si hay una canción
    final dynamicColor = currentSong != null 
        ? ref.watch(albumColorProvider(currentSong.id)).value ?? AppColors.background
        : AppColors.background;

    if (currentSong == null) return const Scaffold();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [dynamicColor, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                _buildHeader(context),
                const Spacer(),
                
                // PORTADA (Widget separado para evitar parpadeo)
                _AlbumArtwork(songId: currentSong.id),
                
                const Spacer(),
                _buildSongInfo(currentSong),
                const SizedBox(height: 30),

                // SLIDER Y TIEMPOS
                _PlayerSlider(playerNotifier: playerNotifier),

                const SizedBox(height: 30),
                _buildControls(playerNotifier),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS INTERNOS ---
  Widget _buildHeader(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, size: 35, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      const Text("REPRODUCIENDO", style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white70)),
      const SizedBox(width: 48),
    ],
  );

  Widget _buildSongInfo(dynamic song) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(song.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(song.artist, style: const TextStyle(fontSize: 18, color: Colors.white70)),
          ],
        ),
      ),
      const Icon(Icons.favorite_border, color: AppColors.primary, size: 28),
    ],
  );

  // --- BOTONES DE CONTROL CORREGIDOS ---
  Widget _buildControls(dynamic notifier) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      const Icon(Icons.shuffle, color: Colors.white54),
      IconButton(
        icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
        onPressed: () => notifier.playPrevious(),
      ),
      
      // USAMOS UN CONSUMER PARA EL BOTÓN DE PLAY (Más confiable)
      Consumer(
        builder: (context, ref, child) {
          // Escuchamos el stream de estado del audioplayer directamente
          return StreamBuilder<PlayerState>(
            stream: notifier.stateStream,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data == PlayerState.playing;
              return GestureDetector(
                onTap: () => notifier.togglePlay(),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow, 
                    size: 40, 
                    color: Colors.black
                  ),
                ),
              );
            },
          );
        },
      ),
      
      IconButton(
        icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
        onPressed: () => notifier.playNext(),
      ),
      const Icon(Icons.repeat, color: Colors.white54),
    ],
  );
}

// --- PORTADA INDEPENDIENTE (EVITA PARPADEO) ---
class _AlbumArtwork extends StatelessWidget {
  final int songId;
  const _AlbumArtwork({required this.songId});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: audio.QueryArtworkWidget(
            id: songId,
            type: audio.ArtworkType.AUDIO,
            size: 800,
            quality: 100,
            artworkFit: BoxFit.cover,
            nullArtworkWidget: Container(color: AppColors.surface, child: const Icon(Icons.music_note, size: 80, color: Colors.white24)),
          ),
        ),
      ),
    );
  }
}

// --- SLIDER CORREGIDO ---
class _PlayerSlider extends ConsumerWidget {
  final dynamic playerNotifier;
  const _PlayerSlider({super.key, required this.playerNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // <--- 'ref' se define aquí
    return StreamBuilder<Duration>(
      stream: playerNotifier.durationStream,
      builder: (context, snapshotDur) {
        final duration = snapshotDur.data ?? Duration.zero;
        
        return StreamBuilder<Duration>(
          stream: playerNotifier.positionStream,
          builder: (context, snapshotPos) {
            final position = snapshotPos.data ?? Duration.zero;
            
            double maxVal = duration.inMilliseconds.toDouble();
            double currentVal = position.inMilliseconds.toDouble();
            
            if (maxVal <= 0) maxVal = 1.0; 
            if (currentVal > maxVal) currentVal = maxVal;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxVal,
                    value: currentVal.clamp(0.0, maxVal),
                    onChanged: (value) {
                      playerNotifier.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_format(position), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(_format(duration), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _format(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }
}