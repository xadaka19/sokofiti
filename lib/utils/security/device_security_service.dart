import 'dart:io';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Device Security Service
/// Detects rooted Android devices and jailbroken iOS devices
class DeviceSecurityService {
  static const MethodChannel _channel = MethodChannel('com.sokofiti.app/security');

  /// Check if device is compromised (rooted/jailbroken)
  static Future<bool> isDeviceCompromised() async {
    if (kDebugMode) {
      // Skip check in debug mode for development
      log('Skipping security check in debug mode', name: 'DeviceSecurity');
      return false;
    }

    try {
      if (Platform.isAndroid) {
        return await _isAndroidRooted();
      } else if (Platform.isIOS) {
        return await _isIOSJailbroken();
      }
      return false;
    } catch (e) {
      log('Error checking device security: $e', name: 'DeviceSecurity');
      return false;
    }
  }

  /// Check if Android device is rooted
  static Future<bool> _isAndroidRooted() async {
    try {
      // Check for common root indicators
      final rootIndicators = [
        '/system/app/Superuser.apk',
        '/system/xbin/su',
        '/system/bin/su',
        '/sbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/data/local/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/su/bin/su',
        '/data/adb/magisk',
        '/sbin/.magisk',
      ];

      for (final path in rootIndicators) {
        if (await _fileExists(path)) {
          log('Root indicator found: $path', name: 'DeviceSecurity');
          return true;
        }
      }

      // Check for root management apps
      final rootApps = [
        'com.topjohnwu.magisk',
        'com.koushikdutta.superuser',
        'com.noshufou.android.su',
        'eu.chainfire.supersu',
        'com.thirdparty.superuser',
        'com.yellowes.su',
      ];

      for (final app in rootApps) {
        if (await _isAppInstalled(app)) {
          log('Root app found: $app', name: 'DeviceSecurity');
          return true;
        }
      }

      // Check build tags
      if (await _hasDangerousBuildTags()) {
        return true;
      }

      return false;
    } catch (e) {
      log('Error checking Android root status: $e', name: 'DeviceSecurity');
      return false;
    }
  }

  /// Check if iOS device is jailbroken
  static Future<bool> _isIOSJailbroken() async {
    try {
      // Check for common jailbreak indicators
      final jailbreakIndicators = [
        '/Applications/Cydia.app',
        '/Applications/Sileo.app',
        '/Applications/Zebra.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
        '/private/var/stash',
        '/private/var/lib/cydia',
        '/usr/bin/ssh',
      ];

      for (final path in jailbreakIndicators) {
        if (await _fileExists(path)) {
          log('Jailbreak indicator found: $path', name: 'DeviceSecurity');
          return true;
        }
      }

      // Check if app can write outside sandbox
      if (await _canWriteOutsideSandbox()) {
        return true;
      }

      return false;
    } catch (e) {
      log('Error checking iOS jailbreak status: $e', name: 'DeviceSecurity');
      return false;
    }
  }

  /// Check if file exists at path
  static Future<bool> _fileExists(String path) async {
    try {
      return File(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Check if an app is installed (Android only)
  static Future<bool> _isAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod('isAppInstalled', {'packageName': packageName});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Check for dangerous build tags (Android only)
  static Future<bool> _hasDangerousBuildTags() async {
    try {
      final result = await _channel.invokeMethod('getBuildTags');
      if (result is String) {
        return result.contains('test-keys');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if app can write outside sandbox (iOS only)
  static Future<bool> _canWriteOutsideSandbox() async {
    try {
      final file = File('/private/jailbreak_test.txt');
      await file.writeAsString('test');
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

