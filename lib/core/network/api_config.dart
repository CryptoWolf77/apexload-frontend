import 'package:apexload/core/constants/app_config.dart';

class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'APEXLOAD_API_BASE_URL',
    defaultValue: AppConfig.apiBaseUrl,
  );

  static const healthPath = '/api/health';
  static const analyzePath = '/api/analyze';
  static const downloadPath = '/api/download';
  static String downloadStatusPath(String jobId) =>
      '/api/download/status/$jobId';
  static String filePath(String fileId) => '/api/file/$fileId';

  static const connectTimeout = Duration(seconds: 12);
  static const receiveTimeout = Duration(seconds: 20);
  static const sendTimeout = Duration(seconds: 20);

  static const enableMockAnalyzeFallback = bool.fromEnvironment(
    'APEXLOAD_ENABLE_MOCK_ANALYZE_FALLBACK',
    defaultValue: AppConfig.useMockFallback,
  );
}
