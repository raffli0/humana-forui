import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfigService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _table = 'settings';

  // Default fallback values
  static const double _defaultLat = -6.93586;
  static const double _defaultLng = 107.63932;
  static const double _defaultRadius = 50.0;

  Future<Map<String, dynamic>> getOfficeConfig(String companyId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('company_id', companyId)
          .maybeSingle();

      if (response != null) {
        return {
          'latitude': (response['latitude'] as num?)?.toDouble() ?? _defaultLat,
          'longitude':
              (response['longitude'] as num?)?.toDouble() ?? _defaultLng,
          'radius': (response['radius'] as num?)?.toDouble() ?? _defaultRadius,
          'start_time': response['start_time'], // If exists, else null
          'end_time': response['end_time'],
          'tolerance_time': response['tolerance_time'],
        };
      }
      return {
        'latitude': _defaultLat,
        'longitude': _defaultLng,
        'radius': _defaultRadius,
      };
    } catch (e) {
      // In case of error (offline, permission), return defaults
      return {
        'latitude': _defaultLat,
        'longitude': _defaultLng,
        'radius': _defaultRadius,
      };
    }
  }

  Future<void> updateOfficeConfig(
    String companyId,
    double lat,
    double lng,
    double radius,
  ) async {
    // Upsert mechanism
    await _supabase.from(_table).upsert({
      'company_id': companyId,
      'latitude': lat,
      'longitude': lng,
      'radius': radius.toInt(),
    });
  }

  // Helper to get LatLng object directly
  Future<LatLng> getOfficeLocation(String companyId) async {
    final data = await getOfficeConfig(companyId);
    return LatLng(
      (data['latitude'] as num).toDouble(),
      (data['longitude'] as num).toDouble(),
    );
  }

  // Helper to get radius directly
  Future<double> getOfficeRadius(String companyId) async {
    final data = await getOfficeConfig(companyId);
    return (data['radius'] as num).toDouble();
  }

  // Shift Configuration
  Future<Map<String, dynamic>> getShiftConfig(String companyId) async {
    final data = await getOfficeConfig(companyId);
    return {
      'start_time': data['start_time'] as String?,
      'end_time': data['end_time'] as String?,
      'tolerance_time': data['tolerance_time'] as int? ?? 0,
    };
  }

  Future<void> updateShiftConfig(
    String companyId,
    String startTime,
    String endTime,
    int toleranceTime,
  ) async {
    // Upsert
    await _supabase.from(_table).upsert({
      'company_id': companyId,
      'start_time': startTime,
      'end_time': endTime,
      'tolerance_time': toleranceTime,
    });
  }

  // --- Multiple Shifts Implementation ---
  // Using a separate 'shifts' table instead of subcollection

  Stream<List<Map<String, dynamic>>> streamShifts(String companyId) {
    return _supabase
        .from('shifts')
        .stream(primaryKey: ['id'])
        .eq('company_id', companyId)
        .map((List<Map<String, dynamic>> data) {
          return data;
        });
  }

  Future<void> addShift(
    String companyId,
    Map<String, dynamic> shiftData,
  ) async {
    shiftData['company_id'] = companyId;
    // Remove 'id' if present to let DB generate it, or handle UUID generation here
    if (shiftData.containsKey('id')) {
      shiftData.remove('id');
    }
    await _supabase.from('shifts').insert(shiftData);
  }

  Future<void> updateShift(
    String companyId,
    String shiftId,
    Map<String, dynamic> shiftData,
  ) async {
    await _supabase
        .from('shifts')
        .update(shiftData)
        .eq('id', shiftId)
        .eq('company_id', companyId); // Safety check
  }

  Future<void> deleteShift(String companyId, String shiftId) async {
    await _supabase
        .from('shifts')
        .delete()
        .eq('id', shiftId)
        .eq('company_id', companyId);
  }
}
