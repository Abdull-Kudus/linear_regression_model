import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The live FastAPI service on Render (Swagger UI is at /docs).
const apiBaseUrl = 'https://ng-business-revenue-api.onrender.com';

/// What /predict sends back when the request is valid.
class Prediction {
  const Prediction({required this.perWorker, required this.wholeBusiness, required this.model});

  final double perWorker; // monthly revenue per worker, PPP US$
  final double wholeBusiness; // per worker x number of workers
  final String model; // e.g. RandomForestRegressor

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    perWorker: (json['revenue_per_worker_ppp'] as num).toDouble(),
    wholeBusiness: (json['business_monthly_revenue_ppp'] as num).toDouble(),
    model: json['model'] as String,
  );
}

/// A failure with a message that is safe to show to the user as it is.
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
}

/// Sends the 12 inputs to POST /predict and returns the prediction.
/// [labels] maps API field names to the labels on screen, so a 422 error
/// says "Survey year: ..." instead of "body.survey_year: ...".
Future<Prediction> predict(Map<String, Object> inputs, Map<String, String> labels) async {
  final http.Response response;
  try {
    response = await http
        .post(
          Uri.parse('$apiBaseUrl/predict'),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(inputs),
        )
        // The free Render server sleeps when idle; the first request can take ~50 s to wake it.
        .timeout(const Duration(seconds: 90));
  } on TimeoutException {
    throw const ApiException('The server took too long to answer. Please try again.');
  } on http.ClientException {
    throw const ApiException('Could not reach the server. Check your internet connection.');
  }

  final Object? body = _decode(response.body);

  if (response.statusCode == 200 && body is Map<String, dynamic>) {
    return Prediction.fromJson(body);
  }

  // FastAPI puts the reason in "detail": a list of field errors for 422, a string otherwise.
  final detail = body is Map<String, dynamic> ? body['detail'] : null;
  if (response.statusCode == 422 && detail is List) {
    final lines = detail.whereType<Map<String, dynamic>>().map((error) {
      final location = (error['loc'] as List?) ?? const [];
      final field = location.isNotEmpty ? location.last.toString() : '';
      final label = labels[field] ?? field;
      return label.isEmpty ? '${error['msg']}' : '$label: ${error['msg']}';
    });
    throw ApiException(lines.join('\n'));
  }
  if (detail is String) throw ApiException(detail);
  throw ApiException('The server answered with an unexpected error (${response.statusCode}).');
}

Object? _decode(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}
