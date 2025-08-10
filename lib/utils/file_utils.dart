import 'dart:io';

class FileUtils {
  /// Get file size in MB
  static Future<double> getFileSizeMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024); // Convert to MB
  }

  /// Estimate number of pages based on file size
  static int estimatePageCount(double fileSizeMb) {
    // Approximation: 1MB ~ 20 pages
    return (fileSizeMb * 20).ceil();
  }

  /// Check if file is under max size (e.g., 10MB)
  static Future<bool> isUnderSizeLimit(File file, {double maxMB = 10}) async {
    final size = await getFileSizeMB(file);
    return size <= maxMB;
  }

  /// Get file extension from file path
  static String getFileExtension(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// Validate allowed file types
  static bool isAllowedFileType(String extension) {
    const allowed = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];
    return allowed.contains(extension);
  }
}
