class CacheKeys {
  CacheKeys._();

  static const schedulesList = 'cache:schedules:list';
  static String scheduleDetail(String id) => 'cache:schedules:detail:$id';

  static const eventsList = 'cache:events:list';
  static String eventDetail(String id) => 'cache:events:detail:$id';

  static const membersList = 'cache:members:list';
  static String memberDetail(String id) => 'cache:members:detail:$id';
}
