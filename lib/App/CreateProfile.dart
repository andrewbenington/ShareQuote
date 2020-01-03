import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'HomePage.dart';

String message = "";

List<NewLineForm> lines = [];

class CreateProfile extends StatefulWidget {
  CreateProfile({Key key, this.document, this.title}) : super(key: key);

  final DocumentReference document;
  final String title;

  @override
  _CreateProfileState createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  bool mostRecent = true;
  String errorMessage = "";

  @override
  void initState() {
    lines = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NewLineForm();
  }
}

class NewLineForm extends StatefulWidget {
  NewLineForm({this.index, this.key, this.remove});
  ValueKey key;
  int index;
  String message;
  String name;
  Function remove;
  bool editing = true;
  Color color = Colors.white;

  @override
  State<StatefulWidget> createState() {
    return NewLineFormState();
  }
}

class NewLineFormState extends State<NewLineForm> {
  String email;
  String password;
  String errorMessage;
  bool loading = false;
  TextEditingController passController = TextEditingController();
  TextEditingController passConfirmController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController imageController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[200],
      child: Form(
        child: Column(
          children: <Widget>[
            Spacer(),
            Padding(
              child: Card(
                color: Colors.white,
                child: Container(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: <Widget>[
                        Align(
                          child: Container(
                            height: MediaQuery.of(context).size.width * 0.4,
                            width: MediaQuery.of(context).size.width * 0.4,
                            margin: EdgeInsets.only(top: 20, bottom: 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                fit: BoxFit.fill,
                                image: NetworkImage(
                                    "https://i.imgur.com/YaWFEJs.jpg"),
                              ),
                              border:
                                  Border.all(width: 5.0, color: Colors.green),
                            ),
                          ),
                          alignment: Alignment.center,
                        ),
                        signUpForm(nameController, "Display Name", (String a) {
                          return a != ""
                              ? null
                              : "Please enter a display name.";
                        }, false),
                        signUpForm(emailController, "Email", (String a) {
                          return a != "" ? null : "Please enter an email.";
                        }, false),
                        signUpForm(passController, "Password", (String a) {
                          return a != "" ? null : "Please enter a password.";
                        }, true),
                        signUpForm(passConfirmController, "Confirm Password",
                            passwordMatches, true),
                        signUpForm(imageController, "Image URL", (String a) {
                          return null;
                        }, false),
                        Row(
                          children: <Widget>[
                            Spacer(),
                            Container(
                              child: ButtonTheme(
                                child: RaisedButton(
                                  child: Icon(
                                    Icons.clear,
                                    color: Colors.white,
                                  ),
                                  color: Colors.red,
                                  elevation: 3.0,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.only(right: 15.0, left: 5.0),
                            ),
                            Spacer(),
                            Container(
                              child: ButtonTheme(
                                child: RaisedButton(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  ),
                                  color: Colors.green,
                                  elevation: 3.0,
                                  onPressed: () {
                                    FormState f = formKey.currentState;
                                    if (f.validate()) {
                                      attemptSignUp(
                                          nameController.text,
                                          emailController.text,
                                          passController.text,
                                          imageController.text);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.only(right: 15.0, left: 15.0),
                            ),
                            Spacer(),
                          ],
                        )
                      ],
                    ),
                  ),
                  padding:
                      EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.0),
            ),
            Spacer()
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
    );
  }

  String passwordMatches(String a) {
    return passController.text == passConfirmController.text
        ? null
        : "Passwords don't match.";
  }

  void attemptSignUp(
      String name, String email, String pass, String imageURL) async {
    formKey.currentState.save();
    print(email);
    print(password);
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      AuthResult result = await auth.createUserWithEmailAndPassword(
          email: email, password: pass);
      var info = UserUpdateInfo();
      info.displayName = name;
      result.user.updateProfile(info);
      globals.firebaseUser = result.user;
      globals.firebaseAuth = auth;
      Firestore.instance.collection("users")
          .document(result.user.uid)
          .setData({"image": imageURL, "display": name, "email": email, "friends": ""});
      Firestore.instance.collection("users").document(result.user.uid).collection("friends");
      Firestore.instance.collection("users").document(result.user.uid).collection("awards");
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

Widget signUpForm(
    TextEditingController controller, String label, Function validator, bool hide) {
  return Padding(
      child: TextFormField(
        obscureText: hide,
        validator: validator,
        controller: controller,
        decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
            hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            hintText: label,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.green, width: 2)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.green, width: 2))),
      ),
      padding: EdgeInsets.only(bottom: 20.0));
}
