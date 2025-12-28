import 'dart:developer';
import 'package:flutter/foundation.dart';

/// Client-side rate limiting service to prevent API abuse
/// 
/// Features:
/// - Limits number of requests per endpoint per time window
/// - Prevents spam and abuse
/// - Configurable limits per endpoint type
/// - Automatic cleanup of old records
class RateLimiterService {
  // Singleton pattern
  static final RateLimiterService _instance = RateLimiterService._internal();
  factory RateLimiterService() => _instance;
  RateLimiterService._internal();

  // Storage for request timestamps per endpoint
  final Map<String, List<DateTime>> _requestHistory = {};

  // Rate limit configurations (requests per minute)
  static const Map<String, int> _rateLimits = {
    // Authentication endpoints - stricter limits
    'login': 5,           // 5 login attempts per minute
    'register': 3,        // 3 registration attempts per minute
    'verify-otp': 10,     // 10 OTP verifications per minute
    'resend-otp': 3,      // 3 OTP resends per minute
    'forgot-password': 3, // 3 password reset requests per minute
    
    // Data fetching endpoints - moderate limits
    'get-items': 30,      // 30 item list requests per minute
    'get-categories': 20, // 20 category requests per minute
    'search': 20,         // 20 search requests per minute
    'get-user': 15,       // 15 user profile requests per minute
    
    // Posting/updating endpoints - stricter limits
    'post-item': 5,       // 5 item posts per minute
    'update-item': 10,    // 10 item updates per minute
    'delete-item': 10,    // 10 item deletions per minute
    'add-favorite': 20,   // 20 favorite additions per minute
    'report': 5,          // 5 reports per minute
    'chat-send': 30,      // 30 chat messages per minute
    
    // Payment endpoints - very strict limits
    'payment': 3,         // 3 payment attempts per minute
    'verify-payment': 5,  // 5 payment verifications per minute
    
    // Default limit for unspecified endpoints
    'default': 60,        // 60 requests per minute (1 per second)
  };

  // Time window for rate limiting (in minutes)
  static const int _timeWindowMinutes = 1;

  /// Check if a request is allowed for the given endpoint
  /// 
  /// Returns true if request is allowed, false if rate limit exceeded
  bool isRequestAllowed(String endpoint) {
    final now = DateTime.now();
    final key = _normalizeEndpoint(endpoint);
    
    // Get or create request history for this endpoint
    _requestHistory.putIfAbsent(key, () => []);
    
    // Clean up old requests outside the time window
    _cleanupOldRequests(key, now);
    
    // Get rate limit for this endpoint
    final limit = _getRateLimitForEndpoint(key);
    
    // Check if limit is exceeded
    final currentCount = _requestHistory[key]!.length;
    
    if (currentCount >= limit) {
      if (kDebugMode) {
        log('⚠️ Rate limit exceeded for $key: $currentCount/$limit requests in last $_timeWindowMinutes minute(s)',
            name: 'RateLimiter');
      }
      return false;
    }
    
    // Record this request
    _requestHistory[key]!.add(now);
    
    if (kDebugMode) {
      log('✅ Request allowed for $key: ${currentCount + 1}/$limit requests',
          name: 'RateLimiter');
    }
    
    return true;
  }

  /// Get the rate limit for a specific endpoint
  int _getRateLimitForEndpoint(String endpoint) {
    // Check for exact match
    if (_rateLimits.containsKey(endpoint)) {
      return _rateLimits[endpoint]!;
    }
    
    // Check for partial matches (e.g., "get-items" matches "items")
    for (final key in _rateLimits.keys) {
      if (endpoint.contains(key) || key.contains(endpoint)) {
        return _rateLimits[key]!;
      }
    }
    
    // Return default limit
    return _rateLimits['default']!;
  }

  /// Normalize endpoint name for consistent matching
  String _normalizeEndpoint(String endpoint) {
    // Remove base URL and query parameters
    String normalized = endpoint
        .replaceAll(RegExp(r'https?://[^/]+'), '')
        .split('?').first
        .toLowerCase()
        .trim();
    
    // Remove leading/trailing slashes
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    
    // Extract key parts (e.g., "api/user/login" -> "login")
    final parts = normalized.split('/');
    if (parts.isNotEmpty) {
      return parts.last;
    }
    
    return normalized;
  }

  /// Remove requests older than the time window
  void _cleanupOldRequests(String key, DateTime now) {
    final cutoffTime = now.subtract(Duration(minutes: _timeWindowMinutes));
    _requestHistory[key]!.removeWhere((timestamp) => timestamp.isBefore(cutoffTime));
  }

  /// Get current request count for an endpoint (for debugging)
  int getCurrentRequestCount(String endpoint) {
    final key = _normalizeEndpoint(endpoint);
    if (!_requestHistory.containsKey(key)) {
      return 0;
    }
    
    final now = DateTime.now();
    _cleanupOldRequests(key, now);
    return _requestHistory[key]!.length;
  }

  /// Reset rate limiter (useful for testing)
  void reset() {
    _requestHistory.clear();
    if (kDebugMode) {
      log('🔄 Rate limiter reset', name: 'RateLimiter');
    }
  }

  /// Get remaining requests for an endpoint
  int getRemainingRequests(String endpoint) {
    final key = _normalizeEndpoint(endpoint);
    final limit = _getRateLimitForEndpoint(key);
    final current = getCurrentRequestCount(key);
    return limit - current;
  }
}

