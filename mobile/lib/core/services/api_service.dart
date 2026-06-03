import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'auth_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            await _refreshToken();
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${AuthStorage.getAccessToken()}';
            final response = await _dio.fetch(opts);
            handler.resolve(response);
            return;
          } catch (_) {
            await AuthStorage.clear();
          }
        }
        handler.next(error);
      },
    ));
  }

  factory ApiService() => _instance ??= ApiService._();

  Future<void> _refreshToken() async {
    final refreshToken = AuthStorage.getRefreshToken();
    if (refreshToken == null) throw const ApiException('Sin refresh token');
    final response = await _dio.post(
      '/api/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    await AuthStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final res = await _dio.get(path, queryParameters: params);
      return _handle(res);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return _handle(res);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final res = await _dio.put(path, data: data);
      return _handle(res);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return _handle(res);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Map<String, dynamic> _handle(Response res) {
    final body = res.data as Map<String, dynamic>;
    if (body['status'] == 'error') {
      throw ApiException(
        body['message'] as String? ?? 'Error desconocido',
        statusCode: res.statusCode,
      );
    }
    return body;
  }

  ApiException _mapError(DioException e) {
    if (e.response != null) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        return ApiException(
          body['message'] as String? ?? 'Error del servidor',
          statusCode: e.response?.statusCode,
        );
      }
      return ApiException('Error ${e.response?.statusCode}', statusCode: e.response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException('Tiempo de espera agotado.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const ApiException('No se puede conectar al servidor.');
    }
    return ApiException(e.message ?? 'Error de red');
  }
}
