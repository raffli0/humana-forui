import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application_model.dart';

class ApplicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit a job application
  Future<void> submitApplication({
    required String jobId,
    required String candidateId,
    String? documentUrl,
  }) async {
    try {
      print(
        'DEBUG - Submitting application: jobId=$jobId, candidateId=$candidateId',
      );

      final updateData = {
        'job_id': jobId,
        'status': 'Applied',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (documentUrl != null) {
        updateData['resume_url'] = documentUrl;
      }

      final response = await _supabase
          .from('candidates')
          .update(updateData)
          .eq('id', candidateId)
          .select();

      print('DEBUG - Application submitted successfully: $response');
    } catch (e) {
      print('ERROR - Failed to submit application: $e');
      throw Exception('Failed to submit application: $e');
    }
  }

  /// Check if candidate has already applied for a job
  Future<bool> hasApplied({
    required String jobId,
    required String candidateId,
  }) async {
    try {
      final response = await _supabase
          .from('candidates')
          .select('job_id')
          .eq('id', candidateId)
          .maybeSingle();

      if (response == null) return false;
      return response['job_id'] == jobId;
    } catch (e) {
      return false;
    }
  }

  /// Get application status for a specific job
  Future<String?> getApplicationStatus({
    required String jobId,
    required String candidateId,
  }) async {
    try {
      final response = await _supabase
          .from('candidates')
          .select('status, job_id')
          .eq('id', candidateId)
          .maybeSingle();

      if (response == null || response['job_id'] != jobId) {
        return null;
      }
      return response['status'];
    } catch (e) {
      return null;
    }
  }

  /// Get all applications for a candidate
  Future<ApplicationModel?> getMyApplication(String candidateId) async {
    try {
      final response = await _supabase
          .from('candidates')
          .select()
          .eq('id', candidateId)
          .maybeSingle();

      if (response == null || response['job_id'] == null) {
        return null;
      }
      return ApplicationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch application: $e');
    }
  }
}
