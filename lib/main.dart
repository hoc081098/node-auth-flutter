import 'dart:async';

import 'package:flutter/material.dart';
import 'package:node_auth/api_service.dart';
import 'package:node_auth/home.dart';
import 'package:node_auth/register.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData.dark(),
      home: new LoginPage(),
      routes: {
        '/register_page': (context) => new RegisterPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _MyLoginPageState createState() => new _MyLoginPageState();
}

class _MyLoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  String _email, _password;
  static const String emailRegExpString =
      r'[a-zA-Z0-9\+\.\_\%\-\+]{1,256}\@[a-zA-Z0-9][a-zA-Z0-9\-]{0,64}(\.[a-zA-Z0-9][a-zA-Z0-9\-]{0,25})+';
  static final RegExp emailRegExp =
      new RegExp(emailRegExpString, caseSensitive: false);
  bool _obscurePassword = true;
  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  AnimationController _loginButtonController;
  Animation<double> _buttonSqueezeAnimation;

  ApiService apiService;

  @override
  void initState() {
    super.initState();
    _loginButtonController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
    _buttonSqueezeAnimation = new Tween(
      begin: 320.0,
      end: 70.0,
    ).animate(new CurvedAnimation(
        parent: _loginButtonController, curve: new Interval(0.0, 0.250)))
      ..addListener(() {
        debugPrint(_buttonSqueezeAnimation.value.toString());
        setState(() {});
      });
    apiService = new ApiService();
  }

  @override
  void dispose() {
    super.dispose();
    _loginButtonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailTextField = new TextFormField(
      autocorrect: true,
      autovalidate: true,
      decoration: new InputDecoration(
        prefixIcon: new Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: new Icon(Icons.email),
        ),
        labelText: 'Email',
      ),
      keyboardType: TextInputType.emailAddress,
      maxLines: 1,
      style: new TextStyle(fontSize: 16.0),
      onSaved: (s) => _email = s,
      validator: (s) =>
          emailRegExp.hasMatch(s) ? null : 'Invalid email address!',
    );

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
        labelText: 'Password',
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

    final loginButton = new Container(
      width: _buttonSqueezeAnimation.value,
      height: 60.0,
      child: new Material(
        elevation: 5.0,
        shadowColor: Theme.of(context).accentColor,
        borderRadius: new BorderRadius.circular(24.0),
        child: _buttonSqueezeAnimation.value > 75.0
            ? new MaterialButton(
                onPressed: _login,
                color: Theme.of(context).backgroundColor,
                child: new Text(
                  'LOGIN',
                  style: new TextStyle(color: Colors.white, fontSize: 16.0),
                ),
                splashColor: new Color(0xFF00e676),
              )
            : new Container(
                padding:
                    new EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                child: new CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
      ),
    );

    final needAnAccount = new FlatButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/register_page');
      },
      child: new Text(
        "Don't have an account? Sign up",
        style: new TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
          fontSize: 14.0,
        ),
      ),
    );

    final forgotPassword = new FlatButton(
      onPressed: _resetPassword,
      child: new Text(
        "Forgot password?",
        style: new TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
          fontSize: 14.0,
        ),
      ),
    );

    return new Scaffold(
      key: _scaffoldKey,
      body: new Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
                image: new AssetImage('assets/bg.jpg'),
                fit: BoxFit.cover,
                colorFilter: new ColorFilter.mode(
                    Colors.black.withAlpha(0xBF), BlendMode.darken))),
        child: new Center(
          child: new Form(
            key: _formKey,
            autovalidate: true,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: emailTextField,
                ),
                new Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: passwordTextField,
                ),
                new SizedBox(height: 32.0),
                new Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: loginButton,
                ),
                new Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: needAnAccount,
                ),
                new Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: forgotPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    if (!_formKey.currentState.validate()) {
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text('Invalid information')),
      );
      return;
    }

    _formKey.currentState.save();
    _loginButtonController.reset();
    _loginButtonController.forward();

    apiService.loginUser(_email, _password).then((Response response) {
      _loginButtonController.reverse();
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text(response.message)),
      );
      Navigator.of(context).pushReplacement(
            new MaterialPageRoute(
              builder: (context) => new HomePage(_email, response.token),
              fullscreenDialog: true,
              maintainState: false,
            ),
          );
    }).catchError((error) {
      _loginButtonController.reverse();
      final message =
          error is MyHttpException ? error.message : 'Unknown error occurred';
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text(message)),
      );
    });
  }

  _resetPassword() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return new ResetPasswordDialog();
      },
    );
  }
}

class ResetPasswordDialog extends StatefulWidget {
  @override
  _ResetPasswordDialogState createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  String _email, _token, _newPassword;

  final _formKey = new GlobalKey<FormState>();
  final ApiService _apiService = new ApiService();

  bool _isInit;
  bool _obscurePassword;
  bool _isLoading;
  String _message;

  @override
  void initState() {
    super.initState();
    _isInit = true;
    _obscurePassword = true;
    _isLoading = false;
    _message = null;
  }

  @override
  Widget build(BuildContext context) {
    final emailTextField = new TextFormField(
      autocorrect: true,
      autovalidate: true,
      decoration: new InputDecoration(
        prefixIcon: new Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: new Icon(Icons.email),
        ),
        labelText: 'Email',
      ),
      keyboardType: TextInputType.emailAddress,
      maxLines: 1,
      style: new TextStyle(fontSize: 16.0),
      onSaved: (s) => _email = s,
      validator: (s) => _MyLoginPageState.emailRegExp.hasMatch(s)
          ? null
          : 'Invalid email address!',
    );

    final tokenTextField = new TextFormField(
      autocorrect: true,
      autovalidate: true,
      decoration: new InputDecoration(
        prefixIcon: new Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: new Icon(Icons.email),
        ),
        labelText: 'Token',
      ),
      keyboardType: TextInputType.emailAddress,
      maxLines: 1,
      style: new TextStyle(fontSize: 16.0),
      onSaved: (s) => _token = s,
    );

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
        labelText: 'Password',
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

    return new AlertDialog(
      title: new Text('Reset password'),
      content: new SingleChildScrollView(
        child: new ListBody(
          children: <Widget>[
            new Form(
              autovalidate: true,
              key: _formKey,
              child: new Column(
                children: <Widget>[
                  new Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: emailTextField,
                  ),
                  _isInit
                      ? new Container()
                      : new Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tokenTextField,
                        ),
                  _isInit
                      ? new Container()
                      : new Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: passwordTextField,
                        ),
                  new Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _isLoading
                        ? new CircularProgressIndicator()
                        : _message != null
                            ? new Text(
                                _message,
                                style: new TextStyle(
                                  fontSize: 14.0,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.amber,
                                ),
                              )
                            : new Container(),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      actions: <Widget>[
        new FlatButton(
          child: new Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        new FlatButton(
          child: new Text('OK'),
          onPressed: _onPressed,
        ),
      ],
    );
  }

  _onPressed() {
    if (!_formKey.currentState.validate()) {
      setState(() => _message = 'Invalid information');
      new Future.delayed(Duration(seconds: 1))
          .then((_) => setState(() => _message = null));
      return;
    }

    _formKey.currentState.save();
    setState(() {
      _isLoading = true;
    });

    if (_isInit) {
      _sendResetEmail();
    } else {
      _resetPassword();
    }
  }

  _sendResetEmail() {
    print("send reset email...");

    _apiService.resetPassword(_email).then((response) {
      setState(() {
        _isInit = _isLoading = false;
        _message = response.message;
      });
      new Future.delayed(Duration(seconds: 1))
          .then((_) => setState(() => _message = null));
    }).catchError((e) {
      final message =
          e is MyHttpException ? e.message : "An unknown error occurred";
      setState(() {
        _isLoading = false;
        _message = message;
      });
      new Future.delayed(Duration(seconds: 1))
          .then((_) => setState(() => _message = null));
    });
  }

  _resetPassword() {
    print("reset password...");

    _apiService
        .resetPassword(_email, newPassword: _newPassword, token: _token)
        .then((response) {
      setState(() {
        _isLoading = false;
        _isInit = true;
        _message = response.message;
      });
      new Future.delayed(Duration(seconds: 1))
          .then((_) => Navigator.of(context).pop());
    }).catchError((e) {
      final message =
          e is MyHttpException ? e.message : "An unknown error occurred";
      setState(() {
        _isLoading = false;
        _message = message;
      });
      new Future.delayed(Duration(seconds: 1))
          .then((_) => setState(() => _message = null));
    });
  }
}
