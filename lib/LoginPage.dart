import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AwardsStream.dart';
import 'Globals.dart' as globals;
import 'HomePage.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  String email;
  String password;
  String errorMessage;
  bool loading = false;
  TextEditingController passController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.green[200],
        body: Container(
            child: Center(
                child: Stack(children: <Widget>[
          Column(
            children: <Widget>[
              Spacer(),
              Row(
                children: <Widget>[
                  Spacer(),
                  Text(
                    "Share",
                    style: TextStyle(fontSize: 52.0, color: Colors.grey[900]),
                  ),
                  Text(
                    "Quote",
                    style: TextStyle(
                        fontSize: 52.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900]),
                  ),
                  Spacer(),
                ],
              ),
              Spacer(),
              loginWindow(),
              Spacer(),
            ],
          ),
          loading ? Center(child: CircularProgressIndicator()) : Container()
        ]))));
  }

  Widget loginWindow() {
    return Stack(children: <Widget>[
      Card(
        child: Container(
          child: Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: emailController,
                  onSaved: (entry) {
                    email = entry;
                  },
                  decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
                      hintStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      hintText: "Email",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide:
                              BorderSide(color: Colors.green, width: 2)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide:
                              BorderSide(color: Colors.green, width: 2))),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.03,
                ),
                TextFormField(
                  controller: passController,
                  onSaved: (entry) {
                    password = entry;
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
                      hintStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      hintText: "Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide:
                              BorderSide(color: Colors.green, width: 2)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide:
                              BorderSide(color: Colors.green, width: 2))),
                ),
                Spacer(),
                RaisedButton(
                  child: Text(
                    "Log In",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  color: Colors.green,
                  elevation: 3.0,
                  onPressed: () {
                    loading = true;
                    attemptLogin(emailController.text, passController.text);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                FlatButton(
                  child: Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  //color: Colors.green,
                  //elevation: 3.0,
                  onPressed: () {
                    attemptSignUp(emailController.text, passController.text);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
          padding: EdgeInsets.only(
              top: 20.0,
              left: MediaQuery.of(context).size.height * 0.03,
              right: MediaQuery.of(context).size.height * 0.03),
          width: MediaQuery.of(context).size.width * 0.8,
          height: 300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 2,
      ),
    ]);
  }

  void attemptLogin(String email, String pass) async {
    formKey.currentState.save();
    print(email);
    print(password);
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      AuthResult result = await auth.signInWithEmailAndPassword(
          email: email, password: password);
          globals.firebaseUser = result.user;
      globals.firebaseAuth = auth;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => HomePage(),
      ));
    } catch (error) {
      print(error);
      switch (error.code) {
        case "ERROR_USER_NOT_FOUND":
          {
            errorMessage = "Username is incorrect.";
          }
          break;
        case "ERROR_INVALID_EMAIL":
          {
            errorMessage = "Please enter a valid email.";
          }
          break;
        case "ERROR_WRONG_PASSWORD":
          {
            errorMessage = "Incorrect Password.";
          }
          break;
        default:
          {
            errorMessage = "Unknown error.";
          }
      }

      setState(() {
        loading = false;
      });
      showErrorMessage();
    }
  }

  void attemptSignUp(String email, String pass) async {
    formKey.currentState.save();
    print(email);
    print(password);
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      AuthResult result = await auth.createUserWithEmailAndPassword(
          email: email, password: pass);
      globals.firebaseUser = result.user;
          globals.firebaseAuth = auth;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => HomePage(),
      ));
    } catch (error) {
      switch (error.code) {
        case "ERROR_WEAK_PASSWORD":
          {
            errorMessage = "Please enter a stronger password.";
          }
          break;
        case "ERROR_INVALID_EMAIL":
          {
            errorMessage = "Please enter a valid email.";
          }
          break;
        case "ERROR_WRONG_PASSWORD":
          {
            errorMessage = "Incorrect Password.";
          }
          break;
        default:
          {
            errorMessage = "Unknown error.";
          }
      }

      setState(() {
        loading = false;
      });
      showErrorMessage();
    }
  }

  void showErrorMessage() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Container(
              child: Text(errorMessage),
            ),
          );
        });
  }
}
