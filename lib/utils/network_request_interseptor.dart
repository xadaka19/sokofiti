import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Network request interceptor for debugging API calls
/// Logs are only enabled in debug mode to prevent sensitive data leakage in production
class NetworkRequestInterceptor extends Interceptor {
  int totalAPICallTimes = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      totalAPICallTimes++;
      log(
          {
            "URL": options.path,
            "Parameters": options.method == "POST"
                ? (options.data as FormData).fields
                : options.queryParameters,
            "Method": options.method,
            "_total_api_calls": totalAPICallTimes
          }.toString(),
          name: "Request-API");
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      log(
          {
            "URL": err.response?.requestOptions.path ?? "",
            "Type": err.type,
            "Error": err.error,
            "Message": err.message,
            "body": err.response?.data
          }.toString(),
          name: "API-Error");
    }
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      log(
          {
            "URL": response.requestOptions.path,
            "Method": response.requestOptions.method,
            "status": response.statusCode,
            "statusMessage": response.statusMessage,
            "response": response.data,
          }.toString(),
          name: "Response-API");
    }
    handler.next(response);
  }
}
