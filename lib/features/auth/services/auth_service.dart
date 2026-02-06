import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:humana/features/auth/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _storage = FlutterSecureStorage();

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> _saveToken(Session? session) async {
    if (session != null) {
      await _storage.write(key: 'access_token', value: session.accessToken);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final AuthResponse response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception("Login failed");
    }

    await _saveToken(response.session);

    // Fetch extra data based on role from metadata
    final metadata = response.user!.userMetadata ?? {};
    final role =
        metadata['role'] as String? ??
        'employee'; // Default to employee for old users
    final table = role == 'candidate' ? 'candidates' : 'employees';

    // Fetch extra data from Supabase table
    final data = await _supabase
        .from(table)
        .select(role == 'candidate' ? '*, recruitments(title)' : '*, shifts(*)')
        .eq('id', response.user!.id)
        .maybeSingle();

    if (data == null) {
      // Fallback if profile missing
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        fullName: metadata['full_name'] ?? 'User',
        role: role,
        status: 'active',
      );
    }

    final userData = Map<String, dynamic>.from(data);
    // Inject role from metadata if missing in table (candidates table has no role column)
    if (!userData.containsKey('role')) {
      userData['role'] = role;
    }
    // Map 'full_name' to 'name' if necessary (candidates table uses full_name, model uses name)
    if (userData.containsKey('full_name') && !userData.containsKey('name')) {
      userData['name'] = userData['full_name'];
    }

    final status = userData['status'] as String? ?? 'active';
    if (status.toLowerCase() == 'inactive') {
      await _supabase.auth.signOut(); // Ensure they are not left signed in
      throw Exception("Your account is deactivated. Please contact admin.");
    }

    return UserModel.fromJson(userData);
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String? companyName,
    required String role,
  }) async {
    // 0. Pre-check for Company (Required if role is NOT candidate and companyName provided)
    String? companyId;
    if (companyName != null && companyName.isNotEmpty && role != 'candidate') {
      final List<dynamic> companies = await _supabase
          .from('companies')
          .select()
          .eq('name', companyName)
          .limit(1);

      if (companies.isEmpty) {
        throw Exception(
          "Company '$companyName' not found. Please check spelling.",
        );
      }
      companyId = companies.first['id'] as String;
    } else if (role != 'candidate') {
      // If role is employee but no company name provided
      throw Exception("Company name is required for employees.");
    }

    // 1. Create Auth Account
    final AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );

    if (response.user == null) {
      throw Exception("Registration failed");
    }

    await _saveToken(response.session);
    final uid = response.user!.id;

    final user = UserModel(
      id: uid,
      fullName: fullName,
      email: email,
      role: role, // Use passed role
      companyId: companyId,
    );

    // 2. Create User Profile in public table
    // Note: 'status' usually defaults to 'pending' or 'active' in DB.
    if (role == 'candidate') {
      await _supabase.from('candidates').insert({
        'id': uid,
        'full_name': fullName, // Correct column name
        'email': email,
        // 'role' column does not exist in candidates table
        'status': 'active',
      });
    } else {
      await _supabase.from('employees').insert(user.toJson());
    }

    return user;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    // Clear ALL secure storage
    await _storage.deleteAll();
    // Clear SharedPreferences but keep 'seenOnboarding' and 'admin_last_cleared_' keys
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    // Get all admin keys we want to preserve
    final keys = prefs.getKeys();
    final adminKeys = keys
        .where((k) => k.startsWith('admin_last_cleared_'))
        .toList();
    final adminValues = <String, String?>{};

    for (var key in adminKeys) {
      adminValues[key] = prefs.getString(key);
    }

    await prefs.clear();

    // Restore preserved values
    if (seenOnboarding) {
      await prefs.setBool('seenOnboarding', true);
    }

    for (var key in adminValues.keys) {
      if (adminValues[key] != null) {
        await prefs.setString(key, adminValues[key]!);
      }
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    String? department,
    String? manager,
    String? companyName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Get user role from metadata
    final userRole = user.userMetadata?['role'] as String?;
    final isCandidate = userRole == 'candidate';

    // Update Auth Metadata - ONLY update fullName, NOT email
    // Updating email in Auth will logout user and require verification
    await _supabase.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );

    if (isCandidate) {
      // Update Candidates Table
      final Map<String, dynamic> updateData = {
        'full_name': fullName,
        'email': email,
      };
      if (phone != null) updateData['phone'] = phone;

      await _supabase.from('candidates').update(updateData).eq('id', user.id);

      // Fetch updated candidate
      final updatedDoc = await _supabase
          .from('candidates')
          .select('*, recruitments(title)')
          .eq('id', user.id)
          .single();

      // CRITICAL: Inject role and map full_name to name for UserModel
      final userData = Map<String, dynamic>.from(updatedDoc);
      userData['role'] = 'candidate'; // Preserve role
      if (userData.containsKey('full_name') && !userData.containsKey('name')) {
        userData['name'] = userData['full_name']; // Map for UserModel
      }

      return UserModel.fromJson(userData);
    } else {
      // Update Employees Table
      final Map<String, dynamic> updateData = {
        'name': fullName,
        'email': email,
      };
      if (phone != null) updateData['phone'] = phone;
      if (department != null) updateData['department'] = department;
      if (manager != null) updateData['manager'] = manager;

      await _supabase.from('employees').update(updateData).eq('id', user.id);

      // Fetch updated employee
      final updatedDoc = await _supabase
          .from('employees')
          .select('*, shifts(*)')
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(updatedDoc);
    }
  }

  Future<UserModel> updateProfilePhoto(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 1. Upload to Storage
      await _supabase.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // 2. Determine Table and Update DB
      final metadata = user.userMetadata ?? {};
      final role = metadata['role'] as String? ?? 'employee';
      final table = role == 'candidate' ? 'candidates' : 'employees';

      await _supabase
          .from(table)
          .update({'avatar': imageUrl})
          .eq('id', user.id);

      // Also update central profiles table for consistency
      try {
        await _supabase
            .from('profiles')
            .update({'avatar_url': imageUrl})
            .eq('id', user.id);
      } catch (e) {
        // Silently fail if profiles update fails, as the main table is updated
        print('Warning: Failed to update profiles table: $e');
      }

      // 3. Return updated user
      final doc = await _supabase
          .from(table)
          .select(
            role == 'candidate' ? '*, recruitments(title)' : '*, shifts(*)',
          )
          .eq('id', user.id)
          .single();

      // Ensure local state reflects update immediately
      final Map<String, dynamic> responseData = Map<String, dynamic>.from(doc);
      responseData['avatar'] = imageUrl;

      // Inject role and map names if candidate
      if (!responseData.containsKey('role')) {
        responseData['role'] = role;
      }
      if (responseData.containsKey('full_name') &&
          !responseData.containsKey('name')) {
        responseData['name'] = responseData['full_name'];
      }

      return UserModel.fromJson(responseData);
    } catch (e) {
      throw Exception("Failed to upload photo: $e");
    }
  }

  Future<String?> getCompanyName(String companyId) async {
    final List<dynamic> response = await _supabase
        .from('companies')
        .select('name')
        .eq('id', companyId);

    if (response.isNotEmpty) {
      return response.first['name'] as String?;
    }
    return null;
  }

  Future<UserModel?> checkAuthStatus() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Get role from user metadata
      final metadata = user.userMetadata ?? {};
      final role =
          metadata['role'] as String? ??
          'employee'; // Default to employee for old users
      final table = role == 'candidate' ? 'candidates' : 'employees';

      try {
        final doc = await _supabase
            .from(table)
            .select(
              role == 'candidate' ? '*, recruitments(title)' : '*, shifts(*)',
            )
            .eq('id', user.id)
            .maybeSingle();

        if (doc == null) {
          // Fallback if profile missing
          return UserModel(
            id: user.id,
            email: user.email ?? '',
            fullName: metadata['full_name'] ?? 'User',
            role: role,
            status: 'active',
          );
        }

        final userData = Map<String, dynamic>.from(doc);
        // Inject role from metadata if missing in table
        if (!userData.containsKey('role')) {
          userData['role'] = role;
        }
        // Map 'full_name' to 'name' if necessary
        if (userData.containsKey('full_name') &&
            !userData.containsKey('name')) {
          userData['name'] = userData['full_name'];
        }

        return UserModel.fromJson(userData);
      } catch (e) {
        // If fetch fails, return null to log them out
        return null;
      }
    }
    return null;
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
