import 'package:dio/dio.dart';

/// Turns a failed request into something a person can act on.
///
/// Every screen used to show the same "couldn't reach the server" line no
/// matter what happened, which made a backend that was simply not running
/// indistinguishable from a timeout, a bad payload, or a crashed endpoint.
/// The distinction is the whole diagnosis, so it belongs in the message.
String describeApiError(Object error, {required String baseUrl}) {
  if (error is! DioException) return 'Something went wrong. Please try again.';

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return 'Cannot reach the server at $baseUrl.\n'
          'Start the backend, and on a phone re-run the adb reverse tunnel.';

    case DioExceptionType.connectionTimeout:
      return 'The server at $baseUrl did not respond in time.\n'
          'On a phone this usually means the tunnel dropped.';

    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The server took too long to answer. '
          'Meal plans and reports can take up to a minute - try again.';

    case DioExceptionType.cancel:
      return 'That request was cancelled.';

    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      final detail = _detailFrom(error.response?.data);
      if (status == 401 || status == 403) {
        return 'The server rejected the request ($status). '
            'Check the OPENAI_API_KEY in backend/.env.';
      }
      if (status == 404) {
        return 'That endpoint is missing on the server ($status). '
            'Restart the backend so it picks up the newest routes.';
      }
      if (status == 422) {
        return 'The server could not read the request (422).'
            '${detail == null ? '' : '\n$detail'}';
      }
      if (status != null && status >= 500) {
        return 'The server hit an error ($status).'
            '${detail == null ? '' : '\n$detail'}'
            '\nCheck the backend terminal for the traceback.';
      }
      return 'The server returned $status.${detail == null ? '' : '\n$detail'}';

    default:
      // Covers DioExceptionType.unknown and any type added by a future Dio.
      return 'Could not complete the request.\n'
          '${error.message ?? 'No further detail was reported.'}';
  }
}

/// FastAPI puts its explanation in `detail`, either as a string or as a list
/// of validation errors.
String? _detailFrom(dynamic data) {
  if (data is Map && data['detail'] != null) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
    }
    return detail.toString();
  }
  if (data is String && data.isNotEmpty) {
    return data.length > 200 ? '${data.substring(0, 200)}...' : data;
  }
  return null;
}
