import 'package:apexload/core/network/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReviewerAccessValidation { verified, invalid, unavailable }

final reviewerAccessServiceProvider = Provider<ReviewerAccessService>((ref) {
  final service = ReviewerAccessService();
  ref.onDispose(service.dispose);
  return service;
});

class ReviewerAccessService {
  ReviewerAccessService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              sendTimeout: ApiConfig.sendTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              headers: const {'Accept': 'application/json'},
            ),
          );

  // This client intentionally has no LogInterceptor because the request body
  // contains a sensitive reviewer credential.
  final Dio _dio;

  Future<ReviewerAccessValidation> verify(String code) async {
    try {
      final response = await _dio.post<Object?>(
        ApiConfig.reviewerAccessPath,
        data: <String, String>{'code': code},
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return ReviewerAccessValidation.verified;
      }
      return ReviewerAccessValidation.unavailable;
    } on DioException catch (error) {
      if (error.response?.statusCode == 403) {
        return ReviewerAccessValidation.invalid;
      }
      return ReviewerAccessValidation.unavailable;
    } on Object {
      return ReviewerAccessValidation.unavailable;
    }
  }

  void dispose() => _dio.close(force: true);
}
