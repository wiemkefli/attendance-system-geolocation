// Default points to the host machine when running the PHP server from the
// `attendance_api` folder on an Android emulator (10.0.2.2 maps to localhost).
// If you serve the API from a different host/port or behind an extra path like
// `/attendance_api`, override with:
//   --dart-define=API_BASE_URL=http://<host>:<port>[/attendance_api]
const String _defaultBaseUrl = 'http://10.0.2.2:8000';

/// Single place to control the backend base URL for all API calls.
const String apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

Uri apiUri(String path, {Map<String, dynamic>? queryParameters}) {
  final normalizedBase =
      apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  final uri = Uri.parse('$normalizedBase/$normalizedPath');

  if (queryParameters == null || queryParameters.isEmpty) {
    return uri;
  }

  return uri.replace(
    queryParameters:
        queryParameters.map((key, value) => MapEntry(key, value.toString())),
  );
}
