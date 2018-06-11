import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Response {
  final String token;
  final String message;

  Response({this.token, this.message});

  Response.fromJson(Map<String, dynamic> json)
      : message = json['message'],
        token = json['token'];
}

class User {
  final String name;
  final String email;
  final DateTime createdAt;

  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'],
        createdAt = DateTime.tryParse(json['created_at']) ?? new DateTime.now();
}

class MyHttpException extends HttpException {
  final int statusCode;
  MyHttpException(this.statusCode, String message) : super(message);
}

class ApiService {
  static const String baseUrl = 'node-auth-081098.herokuapp.com';
  static const String xAccessToken = 'x-access-token';

  static ApiService instance;
  factory ApiService() => instance ??= ApiService._internal();
  ApiService._internal();

  // return message and token
  Future<Response> loginUser(String email, String password) async {
    final url = new Uri.https(baseUrl, '/users/authenticate');
    final credentials = '$email:$password';
    final basic = 'Basic ${base64Encode(utf8.encode(credentials))}';
    final json = await NetworkUtils.post(url, headers: {
      HttpHeaders.AUTHORIZATION: basic,
    });
    return Response.fromJson(json);
  }

  // return message
  Future<Response> registerUser(
      String name, String email, String password) async {
    final url = new Uri.https(baseUrl, '/users');
    final body = {
      'name': name,
      'email': email,
      'password': password,
    };
    final json = await NetworkUtils.post(url, body: body);
    return Response.fromJson(json);
  }

  Future<User> getUserProfile(String email, String token) async {
    final url = new Uri.https(baseUrl, '/users/$email');
    final json = await NetworkUtils.get(url, headers: {xAccessToken: token});
    return User.fromJson(json);
  }

  // return message
  Future<Response> changePassword(
      String email, String password, String newPassword, String token) async {
    final url = new Uri.http(baseUrl, "/users/$email/password");
    final body = {'password': password, 'new_password': newPassword};
    final json = await NetworkUtils.put(
      url,
      headers: {xAccessToken: token},
      body: body,
    );
    return Response.fromJson(json);
  }

  // return message
  // special token and newPassword to reset password,
  // otherwise, send an email to email
  resetPassword(String email, {String token, String newPassword}) async {
    final url = new Uri.https(baseUrl, '/users/$email/password');
    final task = token != null && newPassword != null
        ? NetworkUtils.post(url, body: {
            'token': token,
            'new_password': newPassword,
          })
        : NetworkUtils.post(url);
    final json = await task;
    return Response.fromJson(json);
  }
}

class NetworkUtils {
  static Future get(Uri url, {Map<String, String> headers}) async {
    final response = await http.get(url, headers: headers);
    final body = response.body;
    final statusCode = response.statusCode;
    if (body == null) {
      throw MyHttpException(statusCode, 'Response body is null');
    }
    final decoded = json.decode(body);
    if (statusCode < 200 || statusCode >= 300) {
      throw MyHttpException(statusCode, decoded['message']);
    }
    return decoded;
  }

  static Future post(Uri url,
      {Map<String, String> headers, dynamic body}) async {
    return _postOrPut(http.post, url, headers: headers);
  }

  static Future put(Uri url, {Map<String, String> headers, body}) {
    return _postOrPut(http.put, url, headers: headers);
  }

  static Future _postOrPut(function, Uri url,
      {Map<String, String> headers, body}) async {
    final response = await function(url, body: body, headers: headers);
    final responseBody = response.body;
    final statusCode = response.statusCode;
    if (responseBody == null) {
      throw MyHttpException(statusCode, 'Response body is null');
    }
    final decoded = json.decode(responseBody);
    if (statusCode < 200 || statusCode >= 300) {
      throw MyHttpException(statusCode, decoded['message']);
    }
    return decoded;
  }
}
