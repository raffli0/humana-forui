import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FilePickerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Pick a document file (PDF, DOC, DOCX)
  Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Check file size (max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('File size must be less than 5MB');
        }

        return file;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Upload document to Supabase Storage
  Future<String> uploadDocument({
    required File file,
    required String candidateId,
    required String jobId,
  }) async {
    try {
      final fileName =
          '${candidateId}_${jobId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = 'applications/$fileName';

      print('DEBUG - Uploading file: $filePath');

      await _supabase.storage
          .from('documents')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(filePath);

      print('DEBUG - File uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('ERROR - Failed to upload file: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Get file name from path
  String getFileName(String path) {
    return path.split('/').last;
  }
}
