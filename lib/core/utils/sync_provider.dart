import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../data/local_db/hive_service.dart';
import '../../data/services/supabase_bootstrap.dart';
import '../../data/services/sync_metadata_service.dart';
import '../../data/services/sync_service.dart';
import 'app_provider.dart';

class SyncProvider extends ChangeNotifier with WidgetsBindingObserver {
  SyncProvider();

  final SyncService _syncService = SyncService();

  AppProvider? _appProvider;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool _initialized = false;
  bool _configured = false;
  bool _syncing = false;
  bool _online = true;
  int _dataRevision = 0;
  String? _lastError;
  DateTime? _lastSyncAt;
  SyncSummary? _lastSummary;
  List<ConnectivityResult> _lastConnectivity = const [ConnectivityResult.none];

  bool get configured => _configured;
  bool get syncing => _syncing;
  bool get online => _online;
  int get dataRevision => _dataRevision;
  String? get lastError => _lastError;
  DateTime? get lastSyncAt => _lastSyncAt;
  SyncSummary? get lastSummary => _lastSummary;
  bool get signedIn => _syncService.currentUser != null;
  String? get signedInEmail => _syncService.currentUser?.email;

  void attachAppProvider(AppProvider provider) {
    _appProvider = provider;
  }

  Future<void> init() async {
    if (_initialized) return;
    _configured = await SupabaseBootstrap.initialize();
    try {
      if (!Hive.isBoxOpen(AppConstants.hiveBoxName)) {
        await HiveService.init();
      }
      _lastSyncAt = SyncMetadataService.getLastSyncAt();
    } catch (e) {
      _lastError = e.toString();
    }

    final connectivity = Connectivity();
    _lastConnectivity = await connectivity.checkConnectivity();
    _online = _hasNetwork(_lastConnectivity);
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      _lastConnectivity = results;
      _online = _hasNetwork(results);
      notifyListeners();
      if (_online && signedIn && _allowsAutoSync(results)) {
        unawaited(syncNow(triggeredByUser: false));
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _configured &&
        _online &&
        signedIn) {
      unawaited(syncNow(triggeredByUser: false));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _lastError = null;
    await _syncService.signIn(email: email, password: password);
    notifyListeners();
    await syncNow(triggeredByUser: true);
  }

  Future<bool> signUp({required String email, required String password}) async {
    _lastError = null;
    final response = await _syncService.signUp(
      email: email,
      password: password,
    );
    notifyListeners();
    if (response.session != null) {
      await syncNow(triggeredByUser: true);
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    await _syncService.signOut();
    _lastError = null;
    notifyListeners();
  }

  Future<SyncSummary?> syncNow({bool triggeredByUser = true}) async {
    if (!_configured || !signedIn || _syncing) return null;
    if ((!_online || !_allowsAutoSync(_lastConnectivity)) && !triggeredByUser) {
      return null;
    }

    _syncing = true;
    _lastError = null;
    notifyListeners();
    try {
      final summary = await _syncService.synchronize();
      _lastSummary = summary;
      _lastSyncAt = SyncMetadataService.getLastSyncAt();
      _dataRevision++;
      await _appProvider?.init();
      _appProvider?.refresh();
      return summary;
    } on AuthException catch (e) {
      _lastError = e.message;
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);

  bool _allowsAutoSync(List<ConnectivityResult> results) {
    final wifiOnly = _appProvider?.repo.getSettingsSyncWifiOnly() ?? false;
    if (!wifiOnly) return true;
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    super.dispose();
  }
}
