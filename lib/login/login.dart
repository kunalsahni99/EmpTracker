import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_locator/screens/user_list.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/emp_locator.dart';
import '../screens/user_list.dart';
import '../utils/utils.dart';

class Login extends StatefulWidget {
  final bool isAdmin;

  Login({@required this.isAdmin});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController(),
      passController = TextEditingController();
  bool isVisible = false;
  SharedPreferences sPreferences;

  @override
  void initState() {
    super.initState();
    getPrefs();
  }

  void getPrefs() async {
    sPreferences = await Utils().prefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ConnectivityScreenWrapper(
          disableInteraction: true,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'LOGIN',
                    style: TextStyle(color: Colors.black, fontSize: 20.0),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20.0, left: 40.0, right: 40.0),
                    child: TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 2)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                      ),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20.0, left: 40.0, right: 40.0),
                    child: TextFormField(
                      obscureText: !isVisible,
                      controller: passController,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 2)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black)),
                        suffixIcon: IconButton(
                          color: Colors.grey,
                          icon: Icon(isVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () {
                            setState(() => isVisible = !isVisible);
                          },
                        ),
                      ),
                      keyboardType: TextInputType.visiblePassword,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 25.0),
                    child: MaterialButton(
                      minWidth: 200.0,
                      height: 50.0,
                      onPressed: () async {
                        if (emailController.text.isNotEmpty &&
                            passController.text.isNotEmpty) {
                          //todo: if admin login
                          if (GetUtils.isEmail(emailController.text) == true) {
                            if (widget.isAdmin) {
                              EasyLoading.show(status: "Please wait...");
                              Map<String, dynamic> pass;
                              FirebaseFirestore.instance
                                  .collection('admins')
                                  .doc('${emailController.text}')
                                  .get()
                                  .then((doc) {
                                if (doc.exists) {
                                  pass = doc.data();
                                  if (pass['pass'] == passController.text) {
                                    Duration duration = Duration(seconds: 1);
                                    Future.delayed(duration)
                                        .whenComplete(() async {
                                      await sPreferences.setBool(
                                          'adminLogin', true);
                                      await sPreferences.setString(
                                          'adminID', emailController.text);
                                      EasyLoading.dismiss();
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => UserList(
                                                  id: emailController.text)),
                                          (route) => false);
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                        msg: "Incorrect password");
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                      msg: "This admin doesn't exist");
                                }
                              });
                            }
                            //todo: if employee login
                            else {
                              EasyLoading.show(status: "Signing In");
                              Duration duration = Duration(seconds: 1);
                              Future.delayed(duration).whenComplete(() async {
                                try {
                                  FirebaseAuth fAuth = FirebaseAuth.instance;
                                  var credential =
                                      await fAuth.signInWithEmailAndPassword(
                                          email: emailController.text,
                                          password: passController.text);

                                  if (credential.user.email ==
                                      emailController.text) {
                                    await sPreferences.setBool(
                                        'empLogin', true);
                                    await sPreferences.setString(
                                        'empID', credential.user.uid);
                                    EasyLoading.dismiss();
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => EmpLocator()),
                                        (route) => false);
                                  }
                                } on Exception catch (e) {
                                  EasyLoading.dismiss();
                                  print(e);
                                  Fluttertoast.showToast(
                                      msg: 'Wrong email or password');
                                }
                              });
                            }
                          } else
                            Fluttertoast.showToast(
                                msg: 'Please enter a valid email.');
                        } else {
                          Fluttertoast.showToast(msg: 'Please fill all fields');
                        }
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
