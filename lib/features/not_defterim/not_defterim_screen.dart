import 'package:flutter/material.dart';

import 'not_defterim_module_screen.dart';

/// Sidebar'da "Not Defterim" menu olarak gosterilir.
/// Tamamen offline: Tüm veri Hive + yerel dosya uretimi ile calisir.
class NotDefterimScreen extends StatelessWidget {
  const NotDefterimScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onSyncedTabIndex,
  });

  /// Ana kabuk kenar çubuğu ile aynı sıra (0–6).
  final int initialTabIndex;

  /// TabBar seçimini kabuktaki alt menü ile eşitlemek için (opsiyonel).
  final void Function(int tabIndex)? onSyncedTabIndex;

  @override
  Widget build(BuildContext context) {
    return NotDefterimModuleScreen(
      initialTabIndex: initialTabIndex,
      onSyncedTabIndex: onSyncedTabIndex,
    );
  }
}

