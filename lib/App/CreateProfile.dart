import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pearawards/Utils/Globals.dart' as globals;
import 'HomePage.dart';

List<NewProfileForm> lines = [];

class CreateProfile extends StatefulWidget {
  CreateProfile({Key key, this.document, this.title}) : super(key: key);

  final DocumentReference document;
  final String title;

  @override
  _CreateProfileState createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return NewProfileForm();
  }
}

class NewProfileForm extends StatefulWidget {
  NewProfileForm({this.index, this.key, this.remove});
  ValueKey key;
  int index;
  String name;
  Function remove;
  bool editing = true;
  Color color = globals.theme.backgroundColor;

  @override
  State<StatefulWidget> createState() {
    return NewProfileFormState();
  }
}

class NewProfileFormState extends State<NewProfileForm> {
  String email;
  String password;
  String errorMessage;

  TextEditingController passController = TextEditingController();
  TextEditingController passConfirmController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController imageController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Card(
      color: globals.theme.backgroundColor,
      child: Form(
        child: Column(
          children: <Widget>[
            Spacer(),
            Padding(
              child: Card(
                color: globals.theme.cardColor,
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
                            decoration: imageController.text != ""
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      fit: BoxFit.fill,
                                      image: NetworkImage(imageController.text),
                                    ),
                                    border: Border.all(
                                        width: 5.0, color: globals.theme.primaryColor),
                                  )
                                : BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green[300],
                                    border: Border.all(
                                        width: 5.0, color: globals.theme.primaryColor),
                                  ),
                          ),
                          alignment: Alignment.center,
                        ),
                        signUpForm(nameController, "Display Name", (String a) {
                          return a != ""
                              ? null
                              : "Please enter a display name.";
                        }, false, 30),
                        signUpForm(emailController, "Email", (String a) {
                          return a != "" ? null : "Please enter an email.";
                        }, false, 30),
                        signUpForm(passController, "Password", (String a) {
                          return a != "" ? null : "Please enter a password.";
                        }, true, 30),
                        signUpForm(passConfirmController, "Confirm Password",
                            passwordMatches, true, 30),
                        signUpForm(imageController, "Image URL", (String a) {
                          return null;
                        }, false, null),
                        Row(
                          children: <Widget>[
                            Spacer(),
                            Container(
                              child: ButtonTheme(
                                child: RaisedButton(
                                  child: Icon(
                                    Icons.clear,
                                    color: globals.theme.backgroundColor,
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
                                    color: globals.theme.backgroundColor,
                                  ),
                                  color: globals.theme.primaryColor,
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
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      AuthResult result = await auth.createUserWithEmailAndPassword(
          email: email, password: pass);
      var info = UserUpdateInfo();
      info.displayName = name;
      result.user.updateProfile(info);
      globals.firebaseUser = result.user;
      globals.firebaseUser.reload();
      globals.firebaseAuth = auth;
      Firestore.instance.collection("users").document(result.user.uid).setData({
        "image": imageURL,
        "display": name,
        "display_insensitive": name.toUpperCase(),
        "followers": {},
        "following": {}
      });
      Firestore.instance
          .collection("users_private")
          .document(result.user.uid)
          .setData({
        "email": email,
      });
      Firestore.instance
          .collection("users")
          .document(result.user.uid)
          .collection("awards");
      Firestore.instance
          .collection("users")
          .document(result.user.uid)
          .collection("collections");
      Firestore.instance
          .collection("users")
          .document(result.user.uid)
          .collection("created_collections");
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
          case "ERROR_EMAIL_ALREADY_IN_USE":
          {
            errorMessage = "There is already an account with that email.";
          }
          break;
        default:
          {
            errorMessage = "Unknown error.";
          }
      }

      setState(() {});
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

  Widget signUpForm(TextEditingController controller, String label,
      Function validator, bool hide, int counter) {
    return Padding(
        child: TextFormField(
          onChanged: (change) {
            setState(() {});
          },
          maxLength: counter != null ? counter : null,
          obscureText: hide,
          validator: validator,
          controller: controller,
          decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              labelText: label,
              counter: counter == null
                  ? null
                  : Text((counter - controller.text.length).toString()),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: globals.theme.primaryColor, width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: globals.theme.primaryColor, width: 2))),
        ),
        padding: EdgeInsets.only(bottom: 20.0));
  }
}
