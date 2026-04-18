import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/course.dart';
import '../../data/models/course_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/services/course_wizard_draft_storage.dart';

/// Kurs sihirbazı: bellek içi durum + debounce ile yerel taslak kaydı (offline).
class CourseWizardController extends ChangeNotifier {
  CourseWizardController._({
    required this.draftKey,
    required this.isEditing,
    required Course course,
  })  : _course = course,
        _step = 0;

  factory CourseWizardController.newDraft({String? initialClassId}) {
    final course = Course(
      id: AppRepository.generateId(),
      name: '',
      subject: '',
      classId: initialClassId ?? '',
      weeklyHours: 0,
      totalWeeks: 0,
      status: CourseStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return CourseWizardController._(
      draftKey: 'new',
      isEditing: false,
      course: course,
    );
  }

  factory CourseWizardController.editing(Course course) {
    return CourseWizardController._(
      draftKey: 'edit_${course.id}',
      isEditing: true,
      course: course,
    );
  }

  final String draftKey;
  final bool isEditing;

  Course _course;
  int _step;
  Timer? _debounce;
  bool _draftLoadStarted = false;

  static const Duration _debounceDuration = Duration(milliseconds: 400);

  Course get course => _course;
  int get step => _step;

  /// İlk frame sonrası çağırın; diskteki taslak uygunsa geri yükler.
  Future<void> loadPersistedDraft() async {
    if (_draftLoadStarted) return;
    _draftLoadStarted = true;
    final snap = await CourseWizardDraftStorage.load(draftKey);
    if (snap == null) return;
    if (snap.isEditing != isEditing) return;
    if (isEditing && snap.course.id != _course.id) return;
    _course = snap.course;
    _step = snap.step;
    notifyListeners();
  }

  void setCourse(Course value) {
    _course = value.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    _schedulePersist();
  }

  void setStep(int value) {
    final s = value.clamp(0, 2);
    if (s == _step) return;
    _step = s;
    notifyListeners();
    _schedulePersist();
  }

  void _schedulePersist() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      unawaited(_persist());
    });
  }

  Future<void> _persist() async {
    await CourseWizardDraftStorage.save(
      draftKey: draftKey,
      isEditing: isEditing,
      step: _step,
      course: _course,
    );
  }

  /// Uygulama arka plana alınırken veya sayfa kapanırken anında yaz.
  void flushPersistNow() {
    _debounce?.cancel();
    unawaited(_persist());
  }

  Future<void> clearPersistedDraft() async {
    _debounce?.cancel();
    await CourseWizardDraftStorage.clear(draftKey);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    unawaited(_persist());
    super.dispose();
  }
}
