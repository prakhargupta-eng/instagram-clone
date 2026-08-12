import 'dart:io';

class FileHelper {
  FileHelper._();

  static String cleanPath(String path) {
    if (path.isEmpty) return '';
    
    // Remove query parameters if any (e.g. from editor URI returns)
    if (path.contains('?')) {
      path = path.split('?').first;
    }
    
    // Parse file:// scheme if present
    if (path.startsWith('file://')) {
      try {
        return Uri.parse(path).toFilePath();
      } catch (_) {}
    }
    
    return path;
  }

  static File getFile(String path) {
    return File(cleanPath(path));
  }
}
