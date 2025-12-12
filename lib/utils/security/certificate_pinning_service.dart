import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// SSL Certificate Pinning Service
/// Prevents Man-in-the-Middle (MITM) attacks by validating server certificates
class CertificatePinningService {
  // SHA-256 fingerprint of the certificate for admin.sokofiti.ke
  // To get the fingerprint, run:
  // echo | openssl s_client -servername admin.sokofiti.ke -connect admin.sokofiti.ke:443 2>/dev/null | openssl x509 -fingerprint -sha256 -noout
  // Or use the certificate's SHA-256 hash
  static const List<String> _allowedCertificateHashes = [
    // Primary certificate hash - update this when certificate is rotated
    'iwC/DpmJ/9sHtqeY8fWNgCvrhwS9rkH62PPOMBEdUqM=',
    // Add backup hashes here for certificate rotation
  ];

  // Domain to pin
  static const String _pinnedDomain = 'admin.sokofiti.ke';

  /// Validates the SSL certificate against pinned certificates
  /// Returns true if certificate is valid, false otherwise
  static bool validateCertificate(X509Certificate cert, String host) {
    // Only pin certificates for our API domain
    if (host != _pinnedDomain) {
      if (kDebugMode) {
        log('Certificate pinning skipped for non-API domain: $host', name: 'CertPinning');
      }
      return true; // Allow other domains (e.g., Firebase, Google services)
    }

    try {
      // Get the certificate's SHA-256 hash
      final certHash = _getCertificateHash(cert);

      if (kDebugMode) {
        log('Validating certificate for: $host', name: 'CertPinning');
        log('Certificate hash: $certHash', name: 'CertPinning');
      }

      // Check if the certificate matches any of the allowed hashes
      final isValid = _allowedCertificateHashes.contains(certHash);

      if (!isValid) {
        log('⚠️ CERTIFICATE PINNING FAILED for $host', name: 'CertPinning');
        log('Allowed hashes: $_allowedCertificateHashes', name: 'CertPinning');
        log('Received hash: $certHash', name: 'CertPinning');
      } else {
        if (kDebugMode) {
          log('✅ Certificate pinning validated for $host', name: 'CertPinning');
        }
      }

      return isValid;
    } catch (e) {
      log('Error validating certificate: $e', name: 'CertPinning');
      return false; // Fail closed - reject on error
    }
  }

  /// Extracts and returns the SHA-256 hash of the certificate's DER encoding
  static String _getCertificateHash(X509Certificate cert) {
    try {
      // Hash the certificate's DER encoding with SHA-256
      final certDer = cert.der;
      final digest = sha256.convert(certDer);

      // Base64 encode the hash
      return base64.encode(digest.bytes);
    } catch (e) {
      log('Error hashing certificate: $e', name: 'CertPinning');
      rethrow;
    }
  }

  /// Creates an HttpClient with certificate pinning enabled
  static HttpClient createPinnedHttpClient() {
    final client = HttpClient();
    
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // In debug mode, you might want to allow self-signed certificates for testing
      if (kDebugMode) {
        log('Certificate validation for $host:$port', name: 'CertPinning');
      }
      
      // Validate the certificate
      return validateCertificate(cert, host);
    };

    return client;
  }

  /// Updates the pinned certificate hash
  /// Use this when rotating SSL certificates
  static void updatePinnedHash(String newHash) {
    // In production, you would update this through a secure configuration update
    // For now, this is a placeholder for the update mechanism
    if (kDebugMode) {
      log('Certificate hash update requested: $newHash', name: 'CertPinning');
      log('⚠️ Update the _apiServerPublicKeyHash constant in code', name: 'CertPinning');
    }
  }

  /// Checks if certificate pinning is enabled
  static bool get isEnabled => !kDebugMode; // Disable in debug mode for easier testing

  /// Gets information about the pinned certificate
  static Map<String, dynamic> getPinningInfo() {
    return {
      'domain': _pinnedDomain,
      'allowedHashes': _allowedCertificateHashes,
      'enabled': isEnabled,
    };
  }
}

