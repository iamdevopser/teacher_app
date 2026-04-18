import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/lesson_planner_models.dart';
import 'lesson_document_dialog.dart';
import 'planner_split_view.dart';

class LessonDocumentsTab extends StatefulWidget {
  const LessonDocumentsTab({super.key});

  @override
  State<LessonDocumentsTab> createState() => _LessonDocumentsTabState();
}

class _LessonDocumentsTabState extends State<LessonDocumentsTab> {
  String? _filterClass;
  List<LessonDocument> _docs = [];
  LessonDocument? _selectedDoc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<AppProvider>().repo;
    _docs = _filterClass != null
        ? repo.getLessonDocumentsByClass(_filterClass!)
        : repo.getLessonDocuments();
    if (_selectedDoc != null) {
      final selectedId = _selectedDoc!.id;
      try {
        _selectedDoc = _docs.firstWhere((doc) => doc.id == selectedId);
      } catch (_) {
        _selectedDoc = _docs.isNotEmpty ? _docs.first : null;
      }
    } else if (_docs.length == 1) {
      _selectedDoc = _docs.first;
    }
    setState(() {});
  }

  Future<void> _addDocument() async {
    final doc = await showDialog<LessonDocument>(
      context: context,
      builder: (_) => const LessonDocumentDialog(),
    );
    if (doc != null && mounted) {
      await context.read<AppProvider>().repo.addLessonDocument(doc);
      _load();
    }
  }

  Future<void> _previewDocument(LessonDocument d) async {
    final pathOrUrl = d.pathOrUrl;
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('noFileOrUrl'))),
        );
      }
      return;
    }
    final isUrl = pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');
    final uri = isUrl ? Uri.parse(pathOrUrl) : Uri.file(pathOrUrl);

    if (!isUrl) {
      final file = File(pathOrUrl);
      if (file.existsSync() && _isTextFile(pathOrUrl)) {
        try {
          final content = await file.readAsString();
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(d.name),
              content: SizedBox(
                width: 500,
                height: 400,
                child: SelectableText(content),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Text(context.tr('openInApp')),
                ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('close'))),
              ],
            ),
          );
        } catch (_) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isTextFile(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    final name = parts.isNotEmpty ? parts.last : path;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return ['txt', 'md', 'json', 'xml', 'csv', 'html'].contains(ext);
  }

  void _copyLink(LessonDocument d) {
    final pathOrUrl = d.pathOrUrl;
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('noFileOrUrl'))),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: pathOrUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('copiedToClipboard'))),
    );
  }

  Future<void> _shareDocument(LessonDocument d) async {
    final pathOrUrl = d.pathOrUrl;
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('noFileOrUrl'))),
        );
      }
      return;
    }
    final isUrl = pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');
    if (isUrl) {
      await Share.share(pathOrUrl, subject: d.name);
    } else {
      final file = File(pathOrUrl);
      if (file.existsSync()) {
        await Share.shareXFiles([XFile(pathOrUrl)], text: d.name);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('noFileOrUrl'))),
        );
      }
    }
  }

  Future<void> _deleteDocument(LessonDocument d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deleteDocument')),
        content: Text('${d.name} - ${context.tr('deleteDocumentConfirm')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().repo.deleteLessonDocument(d.id);
      _load();
    }
  }

  void _showMobileDocumentDetails(LessonDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        doc.name,
                        style: Theme.of(ctx).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildDocumentPanel(doc, showHeader: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classes = _buildClassList();
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(context.tr('lessonDocuments')),
              DropdownButton<String>(
                value: _filterClass,
                hint: Text(context.tr('allClasses')),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.tr('all'))),
                  ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: (v) {
                  setState(() {
                    _filterClass = v;
                    _selectedDoc = null;
                    _load();
                  });
                },
              ),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: _addDocument,
                tooltip: context.tr('addDocument'),
              ),
            ],
          ),
        ),
        Expanded(
          child: PlannerSplitView(
            emptyState: _docs.isNotEmpty ? _buildPlaceholder() : null,
            onClosePanel: _selectedDoc != null ? () => setState(() => _selectedDoc = null) : null,
            sidePanel: _selectedDoc != null ? _buildDocumentPanel(_selectedDoc!) : null,
            content: _docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(context.tr('noDocuments'), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _addDocument,
                          child: Text(context.tr('addDocument')),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _docs.length,
                    itemBuilder: (_, i) {
                      final d = _docs[i];
                      final isSelected = _selectedDoc?.id == d.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
                        child: ListTile(
                          leading: Icon(_iconForFormat(d.format)),
                          title: Text(d.name),
                          subtitle: Text('${d.classId} • ${d.format}'),
                          trailing: isWide ? const Icon(Icons.chevron_right) : null,
                          onTap: () {
                            if (isWide) {
                              setState(() => _selectedDoc = d);
                            } else {
                              _showMobileDocumentDetails(d);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.tr('selectItemToOpenSidebar'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDocumentPanel(LessonDocument doc, {bool showHeader = true}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Text(doc.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${doc.classId} • ${doc.format}'),
            const SizedBox(height: 16),
          ],
          _detailRow(context.tr('classLabel'), doc.classId),
          _detailRow(context.tr('format'), doc.format),
          _detailRow(context.tr('filePathOrUrl'), doc.pathOrUrl ?? ''),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _previewDocument(doc),
                icon: const Icon(Icons.preview),
                label: Text(context.tr('preview')),
              ),
              FilledButton.icon(
                onPressed: () => _copyLink(doc),
                icon: const Icon(Icons.link),
                label: Text(context.tr('copyLink')),
              ),
              FilledButton.icon(
                onPressed: () => _shareDocument(doc),
                icon: const Icon(Icons.share),
                label: Text(context.tr('shareDocument')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _deleteDocument(doc),
                icon: const Icon(Icons.delete),
                label: Text(context.tr('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  IconData _iconForFormat(String format) {
    switch (format) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'Word': return Icons.description;
      case 'Excel': return Icons.table_chart;
      case 'PPT': return Icons.slideshow;
      case 'Audio': return Icons.audiotrack;
      case 'Video': return Icons.video_file;
      case 'Link': return Icons.link;
      default: return Icons.insert_drive_file;
    }
  }

  List<String> _buildClassList() {
    final list = <String>[];
    for (final g in AppConstants.grades) {
      for (final b in AppConstants.branches) {
        list.add('$g$b');
      }
    }
    return list;
  }
}
