import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service for sensitive data like JWT tokens
/// Uses platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
class SecureStorageService {
  static SecureStorageService? _instance;
  static FlutterSecureStorage? _storage;

  SecureStorageService._internal();

  factory SecureStorageService() {
    _instance ??= SecureStorageService._internal();
    return _instance!;
  }

  /// Initialize secure storage with platform-specific options
  static Future<void> init() async {
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'sokofiti_secure_prefs',
      preferencesKeyPrefix: 'sokofiti_',
    );

    const iosOptions = IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'SokofitSecureStorage',
    );

    _storage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );

    log('SecureStorageService initialized', name: 'SecureStorage');
  }

  /// Get the storage instance
  static FlutterSecureStorage get storage {
    if (_storage == null) {
      throw Exception('SecureStorageService not initialized. Call init() first.');
    }
    return _storage!;
  }

  // Storage Keys
  static const String _jwtTokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  /// Store JWT token securely
  static Future<void> setJWT(String token) async {
    try {
      await storage.write(key: _jwtTokenKey, value: token);
      log('JWT stored securely', name: 'SecureStorage');
    } catch (e) {
      log('Error storing JWT: $e', name: 'SecureStorage');
      rethrow;
    }
  }

  /// Retrieve JWT token
  static Future<String?> getJWT() async {
    try {
      return await storage.read(key: _jwtTokenKey);
    } catch (e) {
      log('Error reading JWT: $e', name: 'SecureStorage');
      return null;
    }
  }

  /// Store refresh token securely
  static Future<void> setRefreshToken(String token) async {
    try {
      await storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      log('Error storing refresh token: $e', name: 'SecureStorage');
      rethrow;
    }
  }

  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await storage.read(key: _refreshTokenKey);
    } catch (e) {
      log('Error reading refresh token: $e', name: 'SecureStorage');
      return null;
    }
  }

  /// Store user ID securely
  static Future<void> setUserId(String userId) async {
    try {
      await storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      log('Error storing user ID: $e', name: 'SecureStorage');
      rethrow;
    }
  }

  /// Retrieve user ID
  static Future<String?> getUserId() async {
    try {
      return await storage.read(key: _userIdKey);
    } catch (e) {
      log('Error reading user ID: $e', name: 'SecureStorage');
      return null;
    }
  }

  /// Delete a specific key
  static Future<void> delete(String key) async {
    try {
      await storage.delete(key: key);
    } catch (e) {
      log('Error deleting key $key: $e', name: 'SecureStorage');
    }
  }

  /// Clear all secure storage (for logout)
  static Future<void> clearAll() async {
    try {
      await storage.deleteAll();
      log('All secure storage cleared', name: 'SecureStorage');
    } catch (e) {
      log('Error clearing secure storage: $e', name: 'SecureStorage');
    }
  }

  /// Check if JWT exists
  static Future<bool> hasJWT() async {
    final token = await getJWT();
    return token != null && token.isNotEmpty;
  }
}

