import 'package:on_audio_query/on_audio_query.dart';

class SongModel{
  final int id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final String? albumArt;
  
  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    this.albumArt
  });

}