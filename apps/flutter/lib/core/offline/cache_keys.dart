class CacheKeys {
  CacheKeys._();

  static const schedulesList = 'cache:schedules:list';
  static String scheduleDetail(String id) => 'cache:schedules:detail:$id';

  static const eventsList = 'cache:events:list';
  static String eventDetail(String id) => 'cache:events:detail:$id';

  static const membersList = 'cache:members:list';
  static String memberDetail(String id) => 'cache:members:detail:$id';

  static const worshipSongsList = 'cache:worship:songs:list';
  static String worshipSongDetail(String id) => 'cache:worship:songs:detail:$id';

  static const worshipEventsList = 'cache:worship:events:list';
  static String worshipEventDetail(String id) => 'cache:worship:events:detail:$id';

  static const worshipPlaylistsList = 'cache:worship:playlists:list';
  static const worshipFavoritesList = 'cache:worship:favorites:list';
}
