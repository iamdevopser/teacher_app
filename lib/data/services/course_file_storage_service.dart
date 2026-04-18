import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CourseFileStorageService {
  static Future<String> copyToTopicFiles({
    required String sourcePath,
    required String courseName,
    required String unitName,
    required String topicName,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }

    final baseDir = await getApplicationSupportDirectory();
    final targetDir = Directory(
      _join(
        baseDir.path,
        [
          'courses',
          _safeSegment(courseName),
          _safeSegment(unitName),
          _safeSegment(topicName),
          'files',
        ],
      ),
    );
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final fileName = _fileName(sourcePath);
    final dot = fileName.lastIndexOf('.');
    final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
    final ext = dot > 0 ? fileName.substring(dot) : '';

    var targetPath = _join(targetDir.path, [fileName]);
    if (await File(targetPath).exists()) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      targetPath = _join(targetDir.path, ['${stem}_$stamp$ext']);
    }

    await source.copy(targetPath);
    return _toRelative(baseDir.path, targetPath);
  }

  static Future<String> resolvePath(String storedPath) async {
    if (storedPath.startsWith('http://') || storedPath.startsWith('https://')) {
      return storedPath;
    }
    if (_isAbsolute(storedPath)) {
      return storedPath;
    }
    final baseDir = await getApplicationSupportDirectory();
    final normalized = storedPath.replaceAll('/', Platform.pathSeparator);
    return _join(baseDir.path, [normalized]);
  }

  static Future<String> downloadLinkToTopicFiles({
    required String url,
    required String courseName,
    required String unitName,
    required String topicName,
  }) async {
    final uri = Uri.parse(url);
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException('Only http/https links are supported.');
    }

    final baseDir = await getApplicationSupportDirectory();
    final targetDir = await _topicFilesDir(
      baseDir.path,
      courseName: courseName,
      unitName: unitName,
      topicName: topicName,
    );
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final linkKey = _linkKey(url);
    final suggested = _safeUrlFileName(uri);
    final dot = suggested.lastIndexOf('.');
    final stem = dot > 0 ? suggested.substring(0, dot) : suggested;
    final ext = dot > 0 ? suggested.substring(dot) : '.bin';

    var finalName = '${stem}_$linkKey$ext';
    var targetPath = _join(targetDir.path, [finalName]);
    if (await File(targetPath).exists()) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      finalName = '${stem}_${linkKey}_$ts$ext';
      targetPath = _join(targetDir.path, [finalName]);
    }

    final client = HttpClient();
    File? outFile;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with status ${response.statusCode}',
          uri: uri,
        );
      }

      outFile = File(targetPath);
      final sink = outFile.openWrite();
      await response.pipe(sink);
      await sink.flush();
      await sink.close();
      return _toRelative(baseDir.path, targetPath);
    } catch (_) {
      if (outFile != null && await outFile.exists()) {
        await outFile.delete();
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  static Future<bool> hasDownloadedLink({
    required String url,
    required String courseName,
    required String unitName,
    required String topicName,
  }) async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = await _topicFilesDir(
      baseDir.path,
      courseName: courseName,
      unitName: unitName,
      topicName: topicName,
    );
    if (!await dir.exists()) return false;

    final key = '_${_linkKey(url)}';
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = _fileName(entity.path);
      if (name.contains(key)) {
        return true;
      }
    }
    return false;
  }

  static bool _isAbsolute(String path) {
    if (path.startsWith('/') || path.startsWith('\\')) return true;
    return path.length > 2 && path[1] == ':' && (path[2] == '\\' || path[2] == '/');
  }

  static String _safeSegment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'unnamed';
    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static Future<Directory> _topicFilesDir(
    String basePath, {
    required String courseName,
    required String unitName,
    required String topicName,
  }) async {
    return Directory(
      _join(
        basePath,
        [
          'courses',
          _safeSegment(courseName),
          _safeSegment(unitName),
          _safeSegment(topicName),
          'files',
        ],
      ),
    );
  }

  static String _safeUrlFileName(Uri uri) {
    final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    final decoded = Uri.decodeComponent(seg);
    final safe = decoded
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    if (safe.isNotEmpty) return safe;
    return 'download.bin';
  }

  static String _linkKey(String url) {
    final code = url.hashCode.abs();
    return code.toString();
  }

  static String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  static String _toRelative(String base, String fullPath) {
    var baseNorm = base.replaceAll('\\', '/');
    final fullNorm = fullPath.replaceAll('\\', '/');
    if (!baseNorm.endsWith('/')) {
      baseNorm = '$baseNorm/';
    }
    if (fullNorm.startsWith(baseNorm)) {
      return fullNorm.substring(baseNorm.length);
    }
    return fullNorm;
  }

  static String _join(String base, List<String> parts) {
    var out = base;
    for (final part in parts) {
      if (part.isEmpty) continue;
      if (out.endsWith('\\') || out.endsWith('/')) {
        out = '$out${part.replaceAll('/', Platform.pathSeparator)}';
      } else {
        out = '$out${Platform.pathSeparator}${part.replaceAll('/', Platform.pathSeparator)}';
      }
    }
    return out;
  }
}
