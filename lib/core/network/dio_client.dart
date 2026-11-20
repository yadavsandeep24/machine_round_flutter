import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const String kBaseUrl = 'https://jsonplaceholder.typicode.com/';

Dio buildDio({String baseUrl = kBaseUrl, List<Interceptor> interceptors = const []}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.addAll(interceptors);
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        responseBody: false,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }
  return dio;
}
