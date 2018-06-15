import 'dart:async';

import 'package:flutter/material.dart';
import 'package:node_auth/api_service.dart';
import 'package:node_auth/main.dart';

import 'package:image_picker/image_picker.dart';


class HomePage extends StatefulWidget {
  final String token;
  final String email;

  HomePage(this.email, this.token);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _token, _email, _createdAt;
  User _user;
  ApiService _apiService;

  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _token = widget.token;
    _email = widget.email;
    _createdAt = 'loading...';
    _apiService = new ApiService();

    getUserInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Home'),
      ),
      body: new Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
                image: new AssetImage('assets/bg.jpg'),
                fit: BoxFit.cover,
                colorFilter: new ColorFilter.mode(
                    Colors.black.withAlpha(0xBF), BlendMode.darken))),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new Card(
              color: Colors.black.withOpacity(0.5),
              child: new Padding(
                padding: const EdgeInsets.all(8.0),
                child: new Column(
                  children: <Widget>[
                    new Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipOval(
                          child: new GestureDetector(
                            child: _user?.imageUrl != null
                                ? Image.network(
                                    new Uri.https(
                                            ApiService.baseUrl, _user?.imageUrl)
                                        .toString(),
                                    fit: BoxFit.cover,
                                    width: 90.0,
                                    height: 90.0,
                                  )
                                : new Image.asset(
                                    'assets/user.png',
                                    width: 90.0,
                                    height: 90.0,
                                  ),
                            onTap: _pickAndUploadImage,
                          ),
                        ),
                        new Expanded(
                          child: ListTile(
                            title: Text(
                              _user?.name ?? "loading...",
                              style: new TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "${_user?.email ?? "loading..."}\n$_createdAt",
                              style: new TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            new Container(
              height: 48.0,
              margin: new EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
              width: double.infinity,
              child: new RaisedButton.icon(
                onPressed: () {
                  _showChangePassword();
                },
                label: new Text('Change password'),
                icon: new Icon(Icons.lock_outline),
                color: Theme.of(context).backgroundColor,
                colorBrightness: Brightness.dark,
                splashColor: Colors.white.withOpacity(0.5),
              ),
            ),
            new Container(
              height: 48.0,
              margin: new EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
              width: double.infinity,
              child: new RaisedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    new MaterialPageRoute(builder: (BuildContext context) {
                      return new LoginPage();
                    }),
                  );
                },
                label: new Text('Logout'),
                icon: new Icon(Icons.exit_to_app),
                color: Theme.of(context).backgroundColor,
                colorBrightness: Brightness.dark,
                splashColor: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getUserInformation() async {
    try {
      final user = await _apiService.getUserProfile(_email, _token);
      setState(() {
        _user = user;
        _createdAt = user.createdAt.toString();
        debugPrint("getUserInformation $user");
      });
    } on MyHttpException catch (e) {
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text(e.message)),
      );
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(
        content: new Text('Unknown error occurred'),
      ));
    }
  }

  _showChangePassword() {
    _scaffoldKey.currentState.showBottomSheet((context) {
      return new ChangePasswordBottomSheet(
        email: _email,
        token: _token,
      );
    });
  }

  _pickAndUploadImage() async {
    try {
      final imageFile = await ImagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 720.0,
        maxHeight: 720.0,
      );
      final user = await _apiService.uploadImage(imageFile, _email);
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(
          content: new Text('Changed avatar successfully!'),
        ),
      );
      setState(() {
        _user = user;
        debugPrint('After change avatar $user');
      });
    } on MyHttpException catch (e) {
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(
          content: new Text(e.message),
        ),
      );
    } catch (e) {
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text('An unknown error occurred!')),
      );
    }
  }
}

class ChangePasswordBottomSheet extends StatefulWidget {
  final String email;
  final String token;

  const ChangePasswordBottomSheet({Key key, this.email, this.token})
      : super(key: key);

  @override
  _ChangePasswordBottomSheetState createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState extends State<ChangePasswordBottomSheet> {
  final _formKey = new GlobalKey<FormState>();
  ApiService _apiService;
  bool _obscurePassword;
  bool _obscureNewPassword;
  String _password, _newPassword;
  bool _isLoading;
  String _msg;

  String _token, _email;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _token = widget.token;
    _apiService = new ApiService();
    _isLoading = false;
    _obscurePassword = true;
    _obscureNewPassword = true;
  }

  @override
  Widget build(BuildContext context) {
    final passwordTextField = new TextFormField(
      autocorrect: true,
      autovalidate: true,
      obscureText: _obscurePassword,
      decoration: new InputDecoration(
        suffixIcon: new IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: new Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility),
          iconSize: 18.0,
        ),
        labelText: 'Old password',
        prefixIcon: new Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: new Icon(Icons.lock),
        ),
      ),
      keyboardType: TextInputType.text,
      maxLines: 1,
      style: new TextStyle(fontSize: 16.0),
      onSaved: (s) => _password = s,
      validator: (s) => s.length < 6 ? "Minimum length of password is 6" : null,
    );

    final newPasswordTextField = new TextFormField(
      autocorrect: true,
      autovalidate: true,
      obscureText: _obscureNewPassword,
      decoration: new InputDecoration(
        suffixIcon: new IconButton(
          onPressed: () =>
              setState(() => _obscureNewPassword = !_obscureNewPassword),
          icon: new Icon(
              _obscureNewPassword ? Icons.visibility_off : Icons.visibility),
          iconSize: 18.0,
        ),
        labelText: 'New password',
        prefixIcon: new Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: new Icon(Icons.lock),
        ),
      ),
      keyboardType: TextInputType.text,
      maxLines: 1,
      style: new TextStyle(fontSize: 16.0),
      onSaved: (s) => _newPassword = s,
      validator: (s) => s.length < 6 ? "Minimum length of password is 6" : null,
    );

    final changePasswordButton = _isLoading
        ? new CircularProgressIndicator()
        : _msg != null
            ? new Text(
                _msg,
                style: new TextStyle(
                  fontSize: 14.0,
                  fontStyle: FontStyle.italic,
                  color: Colors.amber,
                ),
              )
            : new RaisedButton(
                color: Colors.teal.shade400,
                onPressed: _changePassword,
                child: new Text(
                  "Change password",
                  style: TextStyle(fontSize: 16.0),
                ),
              );

    return new Container(
      decoration: new BoxDecoration(
        borderRadius: new BorderRadius.only(
          topLeft: new Radius.circular(8.0),
          topRight: new Radius.circular(8.0),
        ),
      ),
      child: new Form(
        key: _formKey,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Padding(
              padding: const EdgeInsets.all(8.0),
              child: passwordTextField,
            ),
            new Padding(
              padding: const EdgeInsets.all(8.0),
              child: newPasswordTextField,
            ),
            new Padding(
              padding: const EdgeInsets.all(32.0),
              child: changePasswordButton,
            )
          ],
        ),
      ),
    );
  }

  _changePassword() async {
    setState(() => _isLoading = true);

    if (!_formKey.currentState.validate()) {
      setState(() {
        _isLoading = false;
        _msg = 'Invalid information';
      });
      await new Future.delayed(Duration(seconds: 1));
      setState(() {
        _msg = null;
      });
      return;
    }

    _formKey.currentState.save();
    debugPrint("$_password|$_newPassword");

    try {
      final response = await _apiService.changePassword(
          _email, _password, _newPassword, _token);

      setState(() {
        _isLoading = false;
        _msg = response.message;
      });
      await new Future.delayed(Duration(seconds: 1));
      setState(() {
        _msg = null;
      });
    } on MyHttpException catch (e) {
      setState(() {
        _isLoading = false;
        _msg = e.message;
      });
      await new Future.delayed(Duration(seconds: 1));
      setState(() {
        _msg = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _msg = 'Unknown error occurred';
      });
      await new Future.delayed(Duration(seconds: 1));
      setState(() {
        _msg = null;
      });
      throw e;
    }
  }
}
