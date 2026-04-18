import 'package:flutter/foundation.dart';
import '../../data/local_db/hive_service.dart';
import '../../data/models/teacher_profile.dart';
import '../../data/repositories/app_repository.dart';

/// App-wide state: setup status, teacher profile
class AppProvider extends ChangeNotifier {
  final AppRepository _repo = AppRepository();

  bool _setupComplete = false;
  TeacherProfile? _profile;

  bool get setupComplete => _setupComplete;
  TeacherProfile? get profile => _profile;
  AppRepository get repo => _repo;

  void refresh() => notifyListeners();

  Future<void> init() async {
    try {
      await HiveService.init();
      _profile = _repo.getTeacherProfile();
      _setupComplete = _profile != null;
    } catch (e) {
      debugPrint('AppProvider init: $e');
      _setupComplete = false;
    }
    notifyListeners();
  }

  Future<void> completeSetup(TeacherProfile profile) async {
    _profile = profile;
    _setupComplete = true;
    notifyListeners();
    try {
      await _repo.saveTeacherProfile(profile);
    } catch (e) {
      debugPrint('Profil kaydedilemedi: $e');
    }
  }
}
