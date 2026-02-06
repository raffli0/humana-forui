import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recruitment_model.dart';

class RecruitmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<RecruitmentModel>> fetchJobs({
    String? query,
    String? location,
    String? type,
  }) async {
    try {
      PostgrestFilterBuilder queryBuilder = _supabase
          .from('recruitments_with_company')
          .select()
          .eq('status', 'Open');

      if (query != null && query.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('title', '%$query%');
      }

      if (location != null && location.isNotEmpty) {
        queryBuilder = queryBuilder.eq('location', location);
      }

      if (type != null && type.isNotEmpty) {
        queryBuilder = queryBuilder.eq('type', type);
      }

      // Order by latest
      final response = await queryBuilder.order('created_at', ascending: false);

      // Debug: Print first item to see structure
      if (response is List && response.isNotEmpty) {
        print('DEBUG - First job data: ${response.first}');
      }

      return (response as List)
          .map((item) => RecruitmentModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  Future<RecruitmentModel> fetchJobDetail(String id) async {
    try {
      final response = await _supabase
          .from('recruitments_with_company')
          .select()
          .eq('id', id)
          .single();
      return RecruitmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch job detail: $e');
    }
  }
}
