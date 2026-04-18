import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'not_defterim_models.dart';
import 'not_defterim_repository.dart';

/// Not Defterim günlük puanları tek Hive kutusunda saklanır: [NotDefterimRepository] ↔
/// `Hive.box(AppConstants.hiveBoxName)` içindeki `nd_daily_entries` JSON anahtarı.
/// Uygulama genelinde `teacher_planner` kutusu tek örnektir.
final notDefterimRepositoryProvider = Provider<NotDefterimRepository>((ref) {
  ref.keepAlive();
  return NotDefterimRepository();
});

/// Hive’a günlük puan yazıldığında `bump()` çağır; [notDefterimDailyEntriesProvider] yeniden okur.
final notDefterimDailyRevisionProvider =
    NotifierProvider<NotDefterimDailyRevision, int>(NotDefterimDailyRevision.new);

class NotDefterimDailyRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Her zaman aynı kutudan okur; `revision` ile invalidation.
final notDefterimDailyEntriesProvider = Provider<List<NotDefterimDailyEntry>>((ref) {
  ref.watch(notDefterimDailyRevisionProvider);
  return ref.read(notDefterimRepositoryProvider).getDailyEntries();
});
