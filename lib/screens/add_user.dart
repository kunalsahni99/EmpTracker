import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
class AddUser extends StatefulWidget {
  final String adminID;

  AddUser({this.adminID});

  @override
  _AddUserState createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  bool isVisible = false;
  TextEditingController nameController = TextEditingController(),
      emailController = TextEditingController(),
      passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add user'),
      ),
      body: ConnectivityScreenWrapper(disableInteraction: true,
      child:Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 20.0, left: 40.0, right: 40.0),
                child: TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black)),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20.0, left: 40.0, right: 40.0),
                child: TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2)),
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
                      )),
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
                        passController.text.isNotEmpty &&
                        nameController.text.isNotEmpty) {
                      if (!GetUtils.isEmail(emailController.text))
                        Fluttertoast.showToast(
                            msg: 'Please enter a valid email');
                      else
                        try {
                          EasyLoading.show(status: "Adding User");
                          Duration duration = Duration(seconds: 1);
                          Future.delayed(duration).whenComplete(() async {
                            UserCredential credential = await FirebaseAuth
                                .instance
                                .createUserWithEmailAndPassword(
                                    email: emailController.text,
                                    password: passController.text)
                                .catchError((e) {
                              EasyLoading.dismiss();
                              Fluttertoast.showToast(msg: "${e.message}");
                            });

                            FirebaseFirestore.instance
                                .doc('admins/${widget.adminID}')
                                .set({
                                  'employees': FieldValue.arrayUnion([
                                    {
                                      'name': nameController.text,
                                      'email': emailController.text,
                                      'id': credential.user.uid
                                    }
                                  ])
                                }, SetOptions(merge: true))
                                .whenComplete(() => FirebaseFirestore.instance
                                    .doc('Locator/${credential.user.uid}')
                                    .set({'adminID': widget.adminID}))
                                .whenComplete(() async{ await credential.user.updateProfile(displayName: nameController.text);EasyLoading.dismiss();});
                            Fluttertoast.showToast(
                                msg: 'User added successfully');
                            Navigator.pop(context);
                          });
                        } on FirebaseAuthException catch (e) {
                          EasyLoading.dismiss();
                          Fluttertoast.showToast(msg: "${e.message}");
                        }
                    } else
                      Fluttertoast.showToast(msg: 'Please fill all the fields');
                  },
                  child: Text(
                    'Add',
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
