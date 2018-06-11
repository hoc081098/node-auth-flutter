import 'package:flutter/material.dart';
import 'package:node_auth/api_service.dart';
import 'package:node_auth/main.dart';

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
  final _formKey = new GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  String _password, _newPassword;
  bool _isLoading = false;

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
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: new Column(
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text(
                        _user?.name ?? "loading...",
                        style: new TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _user?.email ?? "loading...",
                        style: new TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                    new Text(_createdAt),
                  ],
                ),
              ),
            ),
            new Container(
              height: 48.0,
              margin: new EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
              width: double.infinity,
              child: new RaisedButton.icon(
                onPressed: _changePassword,
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
            _isLoading ? new CircularProgressIndicator() : new Container(),
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

  _changePassword() {
    _scaffoldKey.currentState.showBottomSheet(
      (context) {
        final passwordTextField = new TextFormField(
          autocorrect: true,
          autovalidate: true,
          obscureText: _obscurePassword,
          decoration: new InputDecoration(
            suffixIcon: new IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
          validator: (s) =>
              s.length < 6 ? "Minimum length of password is 6" : null,
        );

        final newPasswordTextField = new TextFormField(
          autocorrect: true,
          autovalidate: true,
          obscureText: _obscureNewPassword,
          decoration: new InputDecoration(
            suffixIcon: new IconButton(
              onPressed: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
              icon: new Icon(_obscureNewPassword
                  ? Icons.visibility_off
                  : Icons.visibility),
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
          validator: (s) =>
              s.length < 6 ? "Minimum length of password is 6" : null,
        );

        final changePasswordButton = new RaisedButton(
          color: Colors.teal.shade400,
          onPressed: () async {
            Navigator.pop(context);
            setState(() => _isLoading = true);

            if (!_formKey.currentState.validate()) {
              _scaffoldKey.currentState.showSnackBar(new SnackBar(
                content: new Text('Invalid information'),
              ));
              return;
            }

            debugPrint("$_password|$_newPassword");

            try {
              final response = await _apiService.changePassword(
                  _email, _password, _newPassword, _token);
              setState(() => _isLoading = false);
              
              _scaffoldKey.currentState.showSnackBar(new SnackBar(
                content: new Text(response.message),
              ));
            } on MyHttpException catch (e) {
              setState(() => _isLoading = false);

              _scaffoldKey.currentState.showSnackBar(new SnackBar(
                content: new Text(e.message),
              ));
            } catch (e) {
              setState(() => _isLoading = false);

              _scaffoldKey.currentState.showSnackBar(new SnackBar(
                content: new Text('An unknown error occurred'),
              ));
            }
          },
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
                  padding: const EdgeInsets.all(16.0),
                  child: changePasswordButton,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
