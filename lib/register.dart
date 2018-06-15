import 'package:flutter/material.dart';
import 'package:node_auth/api_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  String _email, _password, _name;
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

    final registerButton = new Container(
      width: _buttonSqueezeAnimation.value,
      height: 60.0,
      child: new Material(
        elevation: 5.0,
        shadowColor: Theme.of(context).accentColor,
        borderRadius: new BorderRadius.circular(24.0),
        child: _buttonSqueezeAnimation.value > 75.0
            ? new MaterialButton(
                onPressed: _register,
                color: Theme.of(context).backgroundColor,
                child: new Text(
                  'REGISTER',
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

    final nameTextField = new TextFormField(
      autocorrect: true,
      autovalidate: true,
      decoration: new InputDecoration(
        labelText: 'Name',
        prefixIcon: new Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: new Icon(Icons.person),
        ),
      ),
      keyboardType: TextInputType.text,
      maxLines: 1,
      style: new TextStyle(fontSize: 16.0),
      onSaved: (s) => _name = s,
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
        child: new Stack(
          children: <Widget>[
            new Center(
              child: new Form(
                key: _formKey,
                autovalidate: true,
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: nameTextField,
                    ),
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
                      child: registerButton,
                    ),
                  ],
                ),
              ),
            ),
            _getToolbar(context)
          ],
        ),
      ),
    );
  }

  _getToolbar(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: BackButton(color: Colors.white),
    );
  }

  void _register() {
    if (!_formKey.currentState.validate()) {
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text('Invalid information')),
      );
      return;
    }

    _formKey.currentState.save();
    _loginButtonController.reset();
    _loginButtonController.forward();

    debugPrint("$_name $_email $_password");

    apiService.registerUser(_name, _email, _password).then((Response response) {
      _loginButtonController.reverse();
      _scaffoldKey.currentState
          .showSnackBar(
            new SnackBar(content: new Text(response.message)),
          )
          .closed
          .then((_) => Navigator.of(context).pop());
    }).catchError((error) {
      _loginButtonController.reverse();
      final message =
          error is MyHttpException ? error.message : 'Unknown error occurred';
      _scaffoldKey.currentState.showSnackBar(
        new SnackBar(content: new Text(message)),
      );
    });
  }
}
