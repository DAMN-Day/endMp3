import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio;
import '../../core/app_colors.dart';
import '../../providers/player_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    if (currentSong == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("REPRODUCIENDO", style: TextStyle(fontSize: 12, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. CARÁTULA GIGANTE
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: audio.QueryArtworkWidget(
                    id: currentSong.id,
                    type: audio.ArtworkType.AUDIO,
                    size: 1000,
                    quality: 100,
                    nullArtworkWidget: Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.music_note, size: 100, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),

            // 2. INFO DE CANCIÓN
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentSong.title, 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(currentSong.artist, 
                        style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_border, color: AppColors.primary, size: 30),
              ],
            ),
            const SizedBox(height: 30),

            // 3. BARRA DE PROGRESO CON TIEMPOS
            _PlayerSlider(playerNotifier: playerNotifier),

            // 4. CONTROLES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.shuffle, color: AppColors.textSecondary),
                
                // Botón ANTERIOR
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 45, color: Colors.white),
                  onPressed: () => playerNotifier.playPrevious(), // Necesitas este método en tu provider
                ),

                // BOTÓN PLAY/PAUSE DINÁMICO
                StreamBuilder<PlayerState>(
                  stream: playerNotifier.stateStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data == PlayerState.playing;
                    return GestureDetector(
                      onTap: () => playerNotifier.togglePlay(),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow, 
                          size: 40, 
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),

                // Botón SIGUIENTE
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 45, color: Colors.white),
                  onPressed: () => playerNotifier.playNext(), // Necesitas este método en tu provider
                ),

                const Icon(Icons.repeat, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSlider extends ConsumerWidget {
  final dynamic playerNotifier; // Pasamos el notifier para usar sus streams y métodos

  const _PlayerSlider({required this.playerNotifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Duration>(
      stream: playerNotifier.positionStream,
      builder: (context, snapshotPos) {
        final position = snapshotPos.data ?? Duration.zero;
        
        return StreamBuilder<Duration>(
          stream: playerNotifier.durationStream,
          builder: (context, snapshotDur) {
            final duration = snapshotDur.data ?? Duration.zero;
            
            // Calculamos valores para el Slider
            double max = duration.inMilliseconds.toDouble();
            double current = position.inMilliseconds.toDouble();
            
            // Validación para evitar que 'current' sea mayor que 'max' por error de lag
            if (current > max) current = max;
            if (max <= 0) max = 1.0; 

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    trackHeight: 4,
                    overlayColor: AppColors.primary.withAlpha(32),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: max,
                    value: current,
                    onChanged: (value) {
                      // Movemos la canción al punto donde el usuario suelta el dedo
                      playerNotifier.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                ),
                // TIEMPOS DEBAJO DEL SLIDER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position), 
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Text(_formatDuration(duration), 
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

  // Función auxiliar para convertir milisegundos a formato 0:00
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}