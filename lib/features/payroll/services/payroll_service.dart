import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payslip_model.dart';

class PayrollService {
  final _supabase = Supabase.instance.client;

  Future<List<PayslipModel>> getPayslips() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('payslips')
          .select()
          .eq('employee_id', user.id)
          .order('payment_date', ascending: false);

      return (response as List<dynamic>)
          .map((data) => PayslipModel.fromJson(data, data['id']))
          .toList();
    } catch (e) {
      // Return empty list or rethrow depending on error handling strategy preference
      // For now, returning empty list to avoid crashing UI, but logging might be good
      return [];
    }
  }

  Future<void> updatePayslipStatus(String id, String status) async {
    try {
      await _supabase.from('payslips').update({'status': status}).eq('id', id);
    } catch (e) {
      throw Exception("Failed to update payslip status: $e");
    }
  }

  Future<PayslipModel?> getLatestPayslip() async {
    final history = await getPayslips();
    if (history.isNotEmpty) return history.first;
    return null;
  }
}
