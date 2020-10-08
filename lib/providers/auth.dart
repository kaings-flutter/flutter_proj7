import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../secret/my_credentials.dart';
import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;

  bool get isAuth {
    return getToken != null;
  }

  String get getToken {
    if (_token != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _expiryDate != null) {
      return _token;
    }

    return null;
  }

  Future<void> _authenticate(
      String email, String password, String authCategory) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$authCategory?key=${MyCredentials.PROJ6_API_KEY}';

    try {
      final response = await http.post(url,
          body: json.encode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }));

      print('$authCategory response..... ${json.decode(response.body)}');

      final responseData = json.decode(response.body);

      // we create custom error handling because firebase does not throw error
      // in case there is an error, the error will show in the response as follows
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }

      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );

      notifyListeners();
    } catch (err) {
      print('_authenticate_err..... $err');

      throw err;
    }
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> signIn(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  void signOut() {
    _token = null;
    _expiryDate = null;
    _userId = null;

    notifyListeners();
  }
}
