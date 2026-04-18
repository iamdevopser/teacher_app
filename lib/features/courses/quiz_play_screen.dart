import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/repositories/app_repository.dart';

/// Yerel kurs verisinde [quizShareId] ile quiz etkinliğini bulur.
Map<String, dynamic>? findQuizByShareId(AppRepository repo, String shareId) {
  if (shareId.isEmpty) return null;
  for (final course in repo.getCourses()) {
    for (final raw in course.postLessonActivities) {
      if (raw['type'] != 'quiz') continue;
      if (raw['quizShareId']?.toString() == shareId) {
        return Map<String, dynamic>.from(raw);
      }
    }
  }
  return null;
}

/// Kurs etkinliği haritasından oynatılabilir sorular (en az 2 şık).
List<Map<String, dynamic>> parseQuizQuestionsForPlay(
  Map<String, dynamic> quiz,
) {
  final raw = quiz['questions'];
  if (raw is! List) return [];
  final out = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final opts = m['options'];
    if (opts is! List || opts.length < 2) continue;
    final options = opts.map((o) => o.toString()).toList();
    final ci = (m['correctIndex'] as int?) ?? 0;
    if (options.isEmpty) continue;
    out.add({
      'question': m['question']?.toString() ?? '',
      'options': options,
      'correctIndex': ci.clamp(0, options.length - 1),
    });
  }
  return out;
}

/// Yerleşik (manuel) quiz için [QuizPlayScreen] açılabilir mi?
bool canPlayEmbeddedCourseQuiz(Map<String, dynamic> item) {
  if (item['type']?.toString() != 'quiz') return false;
  if ((item['quizMode'] as String? ?? 'manual') != 'manual') return false;
  final qt = item['quizType'] as String? ?? 'multipleChoice';
  if (qt != 'multipleChoice' && qt != 'trueFalse') return false;
  return parseQuizQuestionsForPlay(item).isNotEmpty;
}

/// Paylaşım veya doğrudan [quizData] ile açılan çoktan seçmeli quiz oynatıcısı.
class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({
    super.key,
    required this.quizData,
    this.courseTitle,
  });

  final Map<String, dynamic> quizData;
  final String? courseTitle;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late List<Map<String, dynamic>> _questions;
  late int _timePerQuestionSec;
  int _index = 0;
  final List<int?> _answers = [];
  DateTime? _startedAt;
  Timer? _timer;
  int? _secondsLeft;
  bool _finished = false;
  int _correct = 0;
  int _wrong = 0;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _questions = _parseQuestions(widget.quizData);
    _timePerQuestionSec = (widget.quizData['timePerQuestion'] as int?) ?? 0;
    for (var i = 0; i < _questions.length; i++) {
      _answers.add(null);
    }
    if (_questions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('quizNeedOneQuestion'))),
          );
          Navigator.pop(context);
        }
      });
      return;
    }
    final qt = widget.quizData['quizType'] as String? ?? 'multipleChoice';
    if (qt != 'multipleChoice' && qt != 'trueFalse') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('quizUnsupportedType'))),
          );
          Navigator.pop(context);
        }
      });
      return;
    }
    if (_timePerQuestionSec > 0) {
      _startCountdown();
    }
  }

  List<Map<String, dynamic>> _parseQuestions(Map<String, dynamic> quiz) =>
      parseQuizQuestionsForPlay(quiz);

  void _startCountdown() {
    _timer?.cancel();
    if (_finished || _index >= _questions.length) return;
    if (_timePerQuestionSec <= 0) {
      setState(() => _secondsLeft = null);
      return;
    }
    setState(() => _secondsLeft = _timePerQuestionSec);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft == null) {
          t.cancel();
          return;
        }
        if (_secondsLeft! <= 1) {
          t.cancel();
          _secondsLeft = 0;
          _onTimeUp();
        } else {
          _secondsLeft = _secondsLeft! - 1;
        }
      });
    });
  }

  void _onTimeUp() {
    if (_finished || _index >= _questions.length) return;
    if (_answers[_index] == null) {
      setState(() => _answers[_index] = null);
    }
    _goNext();
  }

  void _selectOption(int optionIndex) {
    if (_finished || _index >= _questions.length) return;
    _timer?.cancel();
    setState(() => _answers[_index] = optionIndex);
    _goNext();
  }

  void _goNext() {
    _timer?.cancel();
    final q = _questions[_index];
    final chosen = _answers[_index];
    final correct = q['correctIndex'] as int;
    if (chosen != null) {
      if (chosen == correct) {
        _correct++;
      } else {
        _wrong++;
      }
    } else {
      _wrong++;
    }
    if (_index >= _questions.length - 1) {
      _timer?.cancel();
      setState(() {
        _finished = true;
        _elapsed = DateTime.now().difference(_startedAt ?? DateTime.now());
      });
      return;
    }
    setState(() {
      _index++;
    });
    if (_timePerQuestionSec > 0) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (_finished) {
      final total = _questions.length;
      final pct = total == 0 ? 0 : ((_correct * 100) / total).round();
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(context.tr('quizResultTitle')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.courseTitle != null &&
                  widget.courseTitle!.isNotEmpty) ...[
                Text(
                  widget.courseTitle!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                widget.quizData['title']?.toString() ?? context.tr('quizTitle'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text('${context.tr('quizTotalQuestions')}: $total'),
              Text('${context.tr('quizCorrect')}: $_correct'),
              Text('${context.tr('quizWrong')}: $_wrong'),
              Text('${context.tr('quizScorePercent')}: %$pct'),
              Text(
                '${context.tr('quizTimeTaken')}: ${_elapsed.inMinutes}:'
                '${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('close')),
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_index];
    final qText = q['question'] as String? ?? '';
    final options = q['options'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.quizData['title']?.toString() ?? context.tr('quizTitle')),
        actions: [
          if (_secondsLeft != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_secondsLeft}s',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${context.tr('questionText')} ${_index + 1} / ${_questions.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(qText, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ...options.asMap().entries.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(e.value),
                    onTap: () => _selectOption(e.key),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// [MaterialApp.onGenerateRoute] için: `/quiz/<shareId>`
class QuizByShareIdScreen extends StatelessWidget {
  const QuizByShareIdScreen({super.key, required this.shareId});

  final String shareId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    final data = findQuizByShareId(repo, shareId);
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('quizPlay'))),
        body: Center(child: Text(context.tr('quizNotFound'))),
      );
    }
    return QuizPlayScreen(quizData: data);
  }
}
