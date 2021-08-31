import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geo_locator/utils/utils.dart';
import 'package:get/get.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Container(
            width: double.maxFinite,
            height: Get.height,
            padding: EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 40),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Employee Details",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.indigo),
                  ),
                  Divider(
                    indent: 45.0,
                    endIndent: 45.0,
                    thickness: 2,
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Text("Name: ${Utils().user().displayName}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(
                    height: 10,
                  ),
                  Text("Email: ${Utils().user().email}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(
                    height: 10,
                  ),
                  MaterialButton(
                    onPressed: () {
                      Get.bottomSheet(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Change Password",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.indigo)),
                              TextField(
                                  autocorrect: false,
                                  autofocus: true,
                                  maxLength: 12,
                                  textAlign: TextAlign.center,
                                  controller: _passwordController),
                              MaterialButton(
                                color: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                onPressed: () async {
                                  if (_passwordController.text.isNotEmpty &&
                                      _passwordController.text.length >= 6 &&
                                      _passwordController.text.length <= 12) {
                                    EasyLoading.show(status: 'Please wait...');
                                    await Utils()
                                        .user()
                                        .updatePassword(
                                            _passwordController.text)
                                        .then((_) {
                                      Get.back();
                                      _passwordController.clear();
                                      EasyLoading.dismiss();
                                      EasyLoading.showSuccess(
                                          "Password changed Successfully");
                                      print(
                                          "Your password changed Succesfully ");
                                    }).catchError((err) {
                                      EasyLoading.dismiss();
                                      Get.snackbar(
                                          "You can't change the Password",
                                          err.toString(),
                                          snackPosition: SnackPosition.BOTTOM);
                                      //This might happen, when the wrong password is in, the user isn't found, or if the user hasn't logged in recently.
                                    });
                                  } else
                                    Get.snackbar("Enter a valid password.",
                                        "Max Length=12,Min Length=6",
                                        snackPosition: SnackPosition.BOTTOM);
                                },
                                child: Text(
                                  "Confirm",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            ],
                          ),
                          backgroundColor: Colors.white);
                    },
                    child: Text("Change Password",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white)),
                    color: Colors.grey,
                  )
                ],
              ),
            )));
  }
}
