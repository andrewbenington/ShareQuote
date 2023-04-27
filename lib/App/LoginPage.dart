import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pearawards/Utils/Utils.dart';
import 'CreateProfile.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
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
  bool persistAuth = false;
  TextEditingController passController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: globals.theme.backgroundColor,
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
                    style: TextStyle(
                        fontSize: 52.0, color: globals.theme.backTextColor),
                  ),
                  Text(
                    "Quote",
                    style: TextStyle(
                        fontSize: 52.0,
                        fontWeight: FontWeight.w600,
                        color: globals.theme.darkPrimary),
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
      Center(
        child: Card(
          child: Container(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    cursorColor: globals.theme.primaryColor,
                    controller: emailController,
                    onSaved: (entry) {
                      email = entry;
                    },
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
                      hintStyle:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                      hintText: "Email",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                              color: globals.theme.lightPrimary, width: 2)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                              color: globals.theme.primaryColor, width: 2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                              color: globals.theme.primaryColor, width: 2)),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.03,
                  ),
                  TextFormField(
                    cursorColor: globals.theme.primaryColor,
                    controller: passController,
                    onSaved: (entry) {
                      password = entry;
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
                      hintStyle:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                      hintText: "Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                              color: globals.theme.primaryColor, width: 2)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(
                            color: globals.theme.primaryColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                              color: globals.theme.primaryColor, width: 2)),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Checkbox(
                        activeColor: globals.theme.primaryColor,
                        value: persistAuth,
                        onChanged: (changed) {
                          persistAuth = changed;
                          setState(() {});
                        },
                      ),
                      Text("Stay signed in")
                    ],
                  ),
                  RaisedButton(
                    child: Text(
                      "Log In",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    color: globals.theme.primaryColor,
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    //color: globals.theme.primaryColor,
                    //elevation: 3.0,
                    onPressed: () {
                      Navigator.push(
                        context,
                        growSignupPage(),
                      );

                      //attemptSignUp(emailController.text, passController.text);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ],
              ),
            ),
            padding: EdgeInsets.only(
                top: 20.0,
                left: MediaQuery.of(context).size.height * 0.03,
                right: MediaQuery.of(context).size.height * 0.03),
            width: MediaQuery.of(context).size.width * 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 2,
        ),
      ),
    ]);
  }

  void attemptLogin(String email, String pass) async {
    formKey.currentState.save();
    try {
      setState(() {
        loading = true;
      });
      FirebaseAuth auth = FirebaseAuth.instance;
      var user = await auth.currentUser();
      AuthResult result = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      globals.firebaseUser = result.user;

      setState(() {
        loading = false;
      });

      globals.firebaseAuth = auth;
      globals.loadedCollections = Map();
      globals.me = await getUserFromUID(globals.firebaseUser.uid);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => HomePage(),
      ));
    } catch (error) {
      setState(() {
        loading = false;
      });
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

Route growSignupPage() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => CreateProfile(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
          scale: animation.drive(CurveTween(curve: Curves.ease)),
          alignment: Alignment.center,
          child: child);
    },
  );
}
