import 'dart:core';
import 'package:dio/dio.dart';

import '/core/config/app_config.dart';

class RESTfulAPI {

  Dio dio = Dio();

  Duration connectTimeout = Duration(seconds: 50);
  Duration receiveTimeout = Duration(seconds: 50);

  Future<void> init() async {

    dio.options = BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          // String? access_token = await ShareLocalStorage().getStringData('access_token') ?? '';
          // options.headers['Authorization'] = 'Bearer ${access_token}';
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          print('RESTful API | ${response.statusCode} | ${response.data}');
          return handler.next(response);
        },
        onError: (DioException err, ErrorInterceptorHandler handler) {
          print('RESTful API | Error | ${err.response?.statusCode} : ${err.requestOptions.path}');
          if (err.response?.statusCode == 401) {
            print('Unauthorized: Token expired or invalid.');
          }
          return handler.next(err);
        },
      ),
    );
  
  }

  Future<Map<String, dynamic>> get(String pathUrl, Map<String, dynamic> params) async {
    try {
      await init();
      final uri = Uri(path: pathUrl, queryParameters: params);
      print('RESTful API | GET | ${AppConfig.apiUrl}${params.toString() == '{}' ? uri.toString() : '${uri.toString()}&'}version=${AppConfig.appVersion}&accessToken=${AppConfig.accessToken}');
      if (params.toString() != '{}') print('RESTful API | PARAMS | ${params.toString()}');
      params['version'] = AppConfig.appVersion;
      params['accessToken'] = AppConfig.accessToken;
      Response response = await dio.get<Map<String, dynamic>>(
        pathUrl,
        queryParameters: params,
      );
      return {
        'status': response.statusCode,
        'message': 'OK',
        'data': response.data,
      };
    } on DioException catch (e) {
      print('RESTful API | Dio Exception | ${e.message}');
      return { 'status': 500, 'message': 'Server Error' };
    } catch (e) {
      print('RESTful API | ERROR | $e');
      return { 'status': 500, 'message': 'Server Error' };
    }
  }

  Future<Map<String, dynamic>> post(String pathUrl, Map<String, dynamic> body, Map<String, dynamic> params) async {
    try {
      await init();
      final uri = Uri(path: pathUrl, queryParameters: params);
      print('RESTful API | POST | ${AppConfig.apiUrl}${params.toString() == '{}' ? uri.toString() : '${uri.toString()}&'}version=${AppConfig.appVersion}&accessToken=${AppConfig.accessToken}');
      if (body.toString() != '{}') print('RESTful API | BODY | ${body.toString()}');
      if (params.toString() != '{}') print('RESTful API | PARAMS | ${params.toString()}');
      params['version'] = AppConfig.appVersion;
      params['accessToken'] = AppConfig.accessToken;
      final response = await dio.post<Map<String, dynamic>>(
        pathUrl,
        data: body,
        queryParameters: params,
      );
      return {
        'status': response.statusCode,
        'message': response.statusCode == 201 ? 'CREATED' : 'OK',
        'data': response.data,
      };
    } on DioException catch (e) {
      print('RESTful API | Dio Exception | ${e.message}');
      return { 'status': 500, 'message': 'Server Error' };
    } catch (e) {
      print('RESTful API | ERROR | $e');
      return { 'status': 500, 'message': 'Server Error' };
    }
  }

  Future<Map<String, dynamic>> put(String pathUrl, Map<String, dynamic> body, Map<String, dynamic> params) async {
    try {
      await init();
      final uri = Uri(path: pathUrl, queryParameters: params);
      print('RESTful API | PUT | ${AppConfig.apiUrl}${params.toString() == '{}' ? uri.toString() : '${uri.toString()}&'}version=${AppConfig.appVersion}&accessToken=${AppConfig.accessToken}');
      if (body.toString() != '{}') print('RESTful API | BODY | ${body.toString()}');
      if (params.toString() != '{}') print('RESTful API | PARAMS | ${params.toString()}');
      params['version'] = AppConfig.appVersion;
      params['accessToken'] = AppConfig.accessToken;
      Response response = await dio.put<Map<String, dynamic>>(
        pathUrl,
        data: body,
        queryParameters: params,
      );
      return {
        'status': response.statusCode,
        'message': 'UPDATED',
        'data': response.data,
      };
    } on DioException catch (e) {
      print('RESTful API | Dio Exception | ${e.message}');
      return { 'status': 500, 'message': 'Server Error' };
    } catch (e) {
      print('RESTful API | ERROR | $e');
      return { 'status': 500, 'message': 'Server Error' };
    }
  }

  Future<Map<String, dynamic>> del(String pathUrl, Map<String, dynamic> params) async {
    try {
      await init();
      final uri = Uri(path: pathUrl, queryParameters: params);
      print('RESTful API | DELETE | ${AppConfig.apiUrl}${params.toString() == '{}' ? uri.toString() : '${uri.toString()}&'}version=${AppConfig.appVersion}&accessToken=${AppConfig.accessToken}');
      if (params.toString() != '{}') print('RESTful API | PARAMS | ${params.toString()}');
      params['version'] = AppConfig.appVersion;
      params['accessToken'] = AppConfig.accessToken;
      Response response = await dio.delete<Map<String, dynamic>>(
        pathUrl,
        queryParameters: params,
      );
      return {
        'status': response.statusCode,
        'message': 'DELETED',
        'data': response.data,
      };
    } on DioException catch (e) {
      print('RESTful API | Dio Exception | ${e.message}');
      return { 'status': 500, 'message': 'Server Error' };
    } catch (e) {
      print('RESTful API | ERROR | $e');
      return { 'status': 500, 'message': 'Server Error' };
    }
  }

}