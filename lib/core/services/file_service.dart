import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PickedResumeFile {
  const PickedResumeFile({
    required this.path,
    required this.fileName,
    required this.fileType,
  });

  final String path;
  final String fileName;
  final String fileType;
}

class FileService {
  Future<PickedResumeFile?> pickAndCopyResume(int userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'txt'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final source = File(result.files.single.path!);
    final documents = await getApplicationDocumentsDirectory();
    final resumesDir = Directory(p.join(documents.path, 'resumes'));
    if (!await resumesDir.exists()) {
      await resumesDir.create(recursive: true);
    }

    final extension = p
        .extension(source.path)
        .replaceFirst('.', '')
        .toLowerCase();
    final fileName =
        'resume_user_${userId}_${DateTime.now().millisecondsSinceEpoch}.${extension.isEmpty ? 'txt' : extension}';
    final destination = File(p.join(resumesDir.path, fileName));
    await source.copy(destination.path);

    return PickedResumeFile(
      path: destination.path,
      fileName: p.basename(source.path),
      fileType: extension.isEmpty ? 'unknown' : extension,
    );
  }

  Future<void> deleteStoredFile(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
