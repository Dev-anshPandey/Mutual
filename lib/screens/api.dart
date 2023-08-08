import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioInterceptor extends Interceptor {
  final Dio api = Dio();
  String? accessToken;
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // super.onRequest(options, handler);
    var pref = await SharedPreferences.getInstance();
    print("Request");
    print('abcd');
    if (options.data is FormData) {
      options.headers['contentType'] = 'multipart/form-data';
      options.headers['accessToken'] = pref.getString('accessToken');
    }
    // options.contentType = 'multipart/form-data';
    // options.followRedirects = true;
    // options.validateStatus = (status) {
    //   return true;
    // };
    //options.headers['accessToken'] = pref.getString('accessToken');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print("Response");
    print(response.statusCode);
    return handler.next(response);
    // TODO: implement onResponse
    //super.onResponse(response, handler);
  }

  @override
  void onError(DioError error, ErrorInterceptorHandler handler) async {
    print("Error");
    // Future.delayed(const Duration(seconds: 5), () => super.onError(error,handler));
    SharedPreferences pref = await SharedPreferences.getInstance();
    print('abcdef');
    if ((error.response?.statusCode == 403 ||
        error.response?.statusCode == 401)) {
      if (await pref.getString('refreshToken').toString() != null) {
        if (await refreshToken()) {
          return handler.resolve(await _retry(error.requestOptions));
        }
      }
      return handler.next(error);
    }
    // TODO: implement onError
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    print("Retrt");
    SharedPreferences pref = await SharedPreferences.getInstance();
    var option = Options();
    if (requestOptions.data is FormData) {
      option = Options(headers: {
        'accessToken': pref.getString('accessToken'),
        'contentType': 'multipart/form-data'
      });
    }
    // final options = Options(method: requestOptions.method, headers: {
    //   'refreshToken': pref.getString('refreshToken'),
    //   'accessToken': pref.getString('accessToken'),
    //   'contentType': 'multipart/form-data',
    //   'followRedirects': true,
    //   'validateStatus': (status) {
    //     return true;
    //   }
    // }
    // );
    return api.request<dynamic>(requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: option);
  }

  Future<bool> refreshToken() async {
    print("Refreshh");
    SharedPreferences pref = await SharedPreferences.getInstance();
    final refreshToken = await pref.getString('refreshToken').toString();
    final response = await api.get('http://3.110.164.26/v1/api/user/token',
        options: Options(headers: {'refreshToken': refreshToken}));

    if (response.statusCode == 200) {
      pref.setString('refreshToken', response.data['data']['refreshToken']);
      pref.setString('accessToken', response.data['data']['accessToken']);
     // print(response.toString());
      accessToken = response.data['data']['accessToken'];
      return true;
    } else {
      // refresh token is wrong
      accessToken = null;
      // _storage.deleteAll();
      return false;
    }
  }
}

class DioClientP {
  final Dio _dio = Dio();

  DioClient() {
    _dio.interceptors.add(DioInterceptor());
  }

  Dio get dio => _dio;
}
// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// // Providers


// /// A class that holds intercepting logic for refreshing expired tokens. This
// /// is the last interceptor in the queue.
// class RefreshTokenInterceptor extends Interceptor {
//   /// An instance of [Dio] for network requests
//   final Dio _dio;
//  // final Reader _read;

//   RefreshTokenInterceptor(
//     {
//     required Dio dioClient,
//   }) : _dio = dioClient;

//   /// The name of the exception on which this interceptor is triggered.
//   // ignore: non_constant_identifier_names
//   String get TokenExpiredException => 'TokenExpiredException';

//   /// This method is used to send a refresh token request if the error
//   /// indicates an expired token.
//   ///
//   /// In case of expired token, it creates a new [Dio] instance, replicates
//   /// its options and locks the current instance to prevent further requests.
//   /// The new instance retrieves a new token and updates it. The original
//   /// request is retried with the new token.
//   ///
//   /// ** NOTE: ** Any requests from original instance will trigger all attached
//   /// interceptors as expected.
//   ///
//   /// ** The structure of response in case of errors or the refresh request is
//   /// dependant on the API and may not always be the same. It might need
//   /// changing according to your own API. **
//   @override
//   Future<void> onError(
//     DioError dioError,
//     ErrorInterceptorHandler handler,
//   ) async {
//     if (dioError.response != null) {
//       if (dioError.response!.data != null) {
//         final headers = dioError.response!.data['headers'] as JSON;

//         // Check error type to be token expired error
//         final code = headers['code'] as String;
//         if (code == TokenExpiredException) {
//           // Make new dio and lock old one
//           final tokenDio = Dio()..options = _dio.options;

//           _dio.lock();

//           // Get auth details for refresh token request
//           final kVStorageService = _read(keyValueStorageServiceProvider);
//           final currentUser = _read(currentStudentProvider);
//           final data = {
//             'erp': currentUser!.erp,
//             'password': await kVStorageService.getAuthPassword(),
//             'oldToken': await kVStorageService.getAuthToken(),
//           };

//           // Make refresh request and get new token
//           final newToken = await _refreshTokenRequest(
//             dioError: dioError,
//             handler: handler,
//             tokenDio: tokenDio,
//             data: data,
//           );

//           if (newToken == null) return super.onError(dioError, handler);

//           // Update auth and unlock old dio
//           kVStorageService.setAuthToken(newToken);

//           // Make original req with new token
//           final response = await _dio.request<JSON>(
//             dioError.requestOptions.path,
//             data: dioError.requestOptions.data,
//             cancelToken: dioError.requestOptions.cancelToken,
//             options: Options(
//               headers: <String, Object?>{'Authorization': 'Bearer $newToken'},
//             ),
//           );
//           return handler.resolve(response);
//         }
//       }
//     }

//     // if not token expired error, forward it to try catch in dio_service
//     return super.onError(dioError, handler);
//   }

//   /// This method sends out a request to refresh the token. Since this request
//   /// uses the new [Dio] instance it needs its own logging and error handling.
//   ///
//   /// ** The structure of response is dependant on the API and may not always
//   /// be the same. It might need changing according to your own API. **
//   Future<String?> _refreshTokenRequest({
//     required DioError dioError,
//     required ErrorInterceptorHandler handler,
//     required Dio tokenDio,
//     required JSON data,
//   }) async {
//     debugPrint('--> REFRESHING TOKEN');
//     try {
//       debugPrint('\tBody: $data');

//       final response = await tokenDio.post<JSON>(
//         ApiEndpoint.auth(AuthEndpoint.REFRESH_TOKEN),
//         data: data,
//       );

//       debugPrint('\tStatus code:${response.statusCode}');
//       debugPrint('\tResponse: ${response.data}');

//       // Check new token success
//       final success = response.data?['headers']['error'] == 0;

//       if (success) {
//         debugPrint('<-- END REFRESH');
//         return response.data?['body']['token'] as String;
//       } else {
//         throw Exception(response.data?['headers']['message']);
//       }
//     } on Exception catch (ex) {
//       // only caught here for logging
//       // forward to try-catch in dio_service for handling
//       debugPrint('\t--> ERROR');
//       if (ex is DioError) {
//         final de = ex;
//         debugPrint('\t\t--> Exception: ${de.error}');
//         debugPrint('\t\t--> Message: ${de.message}');
//         debugPrint('\t\t--> Response: ${de.response}');
//       } else {
//         debugPrint('\t\t--> Exception: $ex');
//       }
//       debugPrint('\t<-- END ERROR');
//       debugPrint('<-- END REFRESH');

//       return null;
//     } finally {
//       _dio
//         ..unlock()
//         ..clear();
//     }
//   }
// }
