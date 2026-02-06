import 'dart:convert';
// import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class AttendanceApi {
  static const String baseUrl =
      'https://raffdev.my.id/api/upload_attendance.php'; //api custom

  static Future<String?> checkIn({
    required String employeeId,
    required File photo,
    required double latitude,
    required double longitude,
    required String address,
    required bool insideOffice,
    // Add shift details
    required String shiftStart,
    required String shiftEnd,
    required int tolerance,
  }) async {
    final uri = Uri.parse(baseUrl);

    final request = http.MultipartRequest('POST', uri);

    // ---------- FORM FIELDS ----------
    request.fields['user_id'] = employeeId;
    request.fields['type'] = 'checkin';
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['address'] = address;
    request.fields['inside_office'] = insideOffice ? '1' : '0';
    // Add new fields
    request.fields['shift_start'] = shiftStart;
    request.fields['shift_end'] = shiftEnd;
    request.fields['tolerance'] = tolerance.toString();

    request.fields['timestamp'] = DateTime.now().toUtc().toIso8601String();
    request.fields['device'] = 'mobile';
    request.fields['app_version'] = '1.0.0';

    // ---------- FILE ----------
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo', // HARUS sama dengan $_FILES['photo']
        photo.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        debugPrint('UPLOAD RESPONSE: $body');
        try {
          final json = jsonDecode(body);
          if (json['status'] == 'error') {
            debugPrint('API ERROR: ${json['message']}');
            return null;
          }

          final path = json['path']?.toString();
          if (path != null && path.isNotEmpty) {
            return 'https://raffdev.my.id/$path';
          }
          return null;
        } catch (e) {
          debugPrint('JSON PARSE ERROR: $e');
          return null; // upload success but parse failed
        }
      } else {
        debugPrint('UPLOAD FAILED: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');
      return null;
    }
  }
}
