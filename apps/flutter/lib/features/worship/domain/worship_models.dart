class Song {
  final String id; final String title; final String? artist; final String? key; final int? bpm; final int? duration;
  final String? lyrics; final String? chords; final int? capo; final String? youtubeUrl; final String? thumbnail;
  final String? notes; final bool isActive; final DateTime createdAt; final DateTime updatedAt; final List<Tag>? tags; final int? favoritesCount;
  Song({required this.id, required this.title, this.artist, this.key, this.bpm, this.duration, this.lyrics, this.chords, this.capo, this.youtubeUrl, this.thumbnail, this.notes, this.isActive = true, required this.createdAt, required this.updatedAt, this.tags, this.favoritesCount});
  factory Song.fromJson(Map<String, dynamic> j) => Song(
    id: j['id'], title: j['title'], artist: j['artist'], key: j['key'], bpm: j['bpm'], duration: j['duration'],
    lyrics: j['lyrics'], chords: j['chords'], capo: j['capo'], youtubeUrl: j['youtubeUrl'], thumbnail: j['thumbnail'],
    notes: j['notes'], isActive: j['isActive'] ?? true, createdAt: DateTime.parse(j['createdAt']), updatedAt: DateTime.parse(j['updatedAt']),
    tags: (j['tags'] as List?)?.map((t) => Tag.fromJson(t['tag'] as Map<String, dynamic>)).toList()?.cast<Tag>(),
    favoritesCount: (j['_count'] as Map?)?['favorites'] as int?,
  );
}
class Tag {
  final String id; final String name; final String color;
  Tag({required this.id, required this.name, this.color = '#008CFF'});
  factory Tag.fromJson(Map<String, dynamic> j) => Tag(id: j['id'], name: j['name'], color: j['color'] ?? '#008CFF');
}
class Playlist {
  final String id; final String name; final String? description; final String createdBy; final bool isPublic;
  final DateTime createdAt; final DateTime updatedAt; final List<PlaylistSong>? songs;
  Playlist({required this.id, required this.name, this.description, required this.createdBy, this.isPublic = false, required this.createdAt, required this.updatedAt, this.songs});
  int get totalDuration => songs?.fold<int>(0, (s, p) => s + (p.song.duration ?? 0)) ?? 0;
  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(id: j['id'], name: j['name'], description: j['description'], createdBy: j['createdBy'], isPublic: j['isPublic'] ?? false, createdAt: DateTime.parse(j['createdAt']), updatedAt: DateTime.parse(j['updatedAt']), songs: (j['songs'] as List?)?.map((s) => PlaylistSong.fromJson(s)).toList());
}
class PlaylistSong {
  final String id; final Song song; final int order; final String? notes; final int transpose;
  PlaylistSong({required this.id, required this.song, required this.order, this.notes, this.transpose = 0});
  factory PlaylistSong.fromJson(Map<String, dynamic> j) => PlaylistSong(id: j['id'], song: Song.fromJson(j['song']), order: j['order'], notes: j['notes'], transpose: j['transpose'] ?? 0);
}
class WorshipEvent {
  final String id;
  final String eventId;
  final String? playlistId;
  final String? ministerMemberId;
  final String? notes;
  final int? estimatedTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorshipEventSong>? songs;
  final List<WorshipEventMusician>? musicians;
  final Playlist? playlist;

  WorshipEvent({
    required this.id,
    required this.eventId,
    this.playlistId,
    this.ministerMemberId,
    this.notes,
    this.estimatedTime,
    required this.createdAt,
    required this.updatedAt,
    this.songs,
    this.musicians,
    this.playlist,
  });

  factory WorshipEvent.fromJson(Map<String, dynamic> j) => WorshipEvent(
        id: j['id'],
        eventId: j['eventId'],
        playlistId: j['playlistId'],
        ministerMemberId: j['ministerMemberId'] as String?,
        notes: j['notes'],
        estimatedTime: j['estimatedTime'],
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
        songs: (j['songs'] as List?)?.map((s) => WorshipEventSong.fromJson(s)).toList(),
        musicians: (j['musicians'] as List?)?.map((m) => WorshipEventMusician.fromJson(m)).toList(),
        playlist: j['playlist'] != null ? Playlist.fromJson(j['playlist']) : null,
      );
}
class WorshipEventSong {
  final String id; final Song song; final int order; final int transpose; final String? notes;
  WorshipEventSong({required this.id, required this.song, required this.order, this.transpose = 0, this.notes});
  factory WorshipEventSong.fromJson(Map<String, dynamic> j) => WorshipEventSong(id: j['id'], song: Song.fromJson(j['song']), order: j['order'], transpose: j['transpose'] ?? 0, notes: j['notes']);
}
class WorshipEventMusician {
  final String id; final String memberId; final String? instrument; final String? role; final bool isConfirmed; final bool isSubstituted;
  WorshipEventMusician({required this.id, required this.memberId, this.instrument, this.role, this.isConfirmed = false, this.isSubstituted = false});
  factory WorshipEventMusician.fromJson(Map<String, dynamic> j) => WorshipEventMusician(
    id: j['id'], memberId: j['memberId'], instrument: j['instrument'], role: j['role'],
    isConfirmed: j['isConfirmed'] ?? false, isSubstituted: j['isSubstituted'] ?? false,
  );
}
class TransposeResult {
  final String transposedChords; final String? originalKey; final String? newKey;
  TransposeResult({required this.transposedChords, this.originalKey, this.newKey});
  factory TransposeResult.fromJson(Map<String, dynamic> j) => TransposeResult(transposedChords: j['transposedChords'], originalKey: j['originalKey'], newKey: j['newKey']);
}
