import 'dart:async';
import 'dart:io';

import '../../data/services/api_client.dart';

String formatError(Object? error) {
  if (error == null) return 'An unexpected error occurred.';
  if (error is ApiException) return error.message;
  if (error is TimeoutException) {
    return 'Request timed out. Please check your network connection and try again.';
  }
  if (error is SocketException) {
    return 'Unable to reach the server. Please check your internet connection.';
  }
  return error.toString();
}
