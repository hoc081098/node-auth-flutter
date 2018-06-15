import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

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
  final String imageUrl;

  User.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'],
        createdAt = DateTime.tryParse(json['created_at']) ?? new DateTime.now(),
        imageUrl = json['image_url'];

  @override
  String toString() => '$name, $email, $imageUrl';
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
    final body = <String, String>{
      'name': name,
      'email': email,
      'password': password,
    };
    final decoded = await NetworkUtils.post(url, body: body);
    return new Response.fromJson(decoded);
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
  Future<Response> resetPassword(String email,
      {String token, String newPassword}) async {
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

  Future<User> uploadImage(File file, String email) async {
    final url = new Uri.https(baseUrl, '/users/upload');
    final stream = new http.ByteStream(file.openRead());
    final length = await file.length();
    final request = new http.MultipartRequest('POST', url)
      ..fields['user'] = email
      ..files.add(
        new http.MultipartFile('my_image', stream, length, filename: path.basename(file.path)),
      );
    final streamedReponse = await request.send();
    final statusCode = streamedReponse.statusCode;
    final decoded = json.decode(await streamedReponse.stream.bytesToString());

    debugPrint('decoded: $decoded');

    if (statusCode < 200 || statusCode >= 300) {
      throw MyHttpException(statusCode, decoded['message']);
    }

    return User.fromJson(decoded);
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
      {Map<String, String> headers, Map<String, String> body}) {
    return _helper('POST', url, headers: headers, body: body);
  }

  static Future _helper(String method, Uri url,
      {Map<String, String> headers, Map<String, String> body}) async {
    final request = new http.Request(method, url);
    if (body != null) {
      request.bodyFields = body;
    }
    if (headers != null) {
      request.headers.addAll(headers);
    }
    final streamedReponse = await request.send();

    final statusCode = streamedReponse.statusCode;
    final decoded = json.decode(await streamedReponse.stream.bytesToString());

    debugPrint('decoded: $decoded');

    if (statusCode < 200 || statusCode >= 300) {
      throw MyHttpException(statusCode, decoded['message']);
    }

    return decoded;
  }

  static Future put(Uri url, {Map<String, String> headers, body}) {
    return _helper('PUT', url, headers: headers, body: body);
  }
}
