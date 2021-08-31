import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geo_locator/screens/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login/login_options.dart';
import '../utils/utils.dart';
import 'add_user.dart';
import 'tracker.dart';

class UserList extends StatefulWidget {
  final String id;

  UserList({this.id});

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  SharedPreferences sp;
  bool active;
  String time = '';
  StreamSubscription sub;
  bool notificationValue;

  @override
  void initState() {
    EasyLoading.show(status: "Loading...");
    getPrefs();
    sub = FirebaseFirestore.instance
        .collection('admins')
        .doc(widget.id)
        .collection('Notifications')
        .snapshots()
        .listen((event) {
      setState(() {
        notificationValue = event.size > 0 ? true : false;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    sub.cancel();
    super.dispose();
  }

  void getPrefs() async {
    sp = await Utils().prefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employees'),
        actions: [
          IconButton(
              icon: new Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications,
                    color: Colors.white,
                  ),
                  notificationValue == true
                      ? Positioned(
                          child: Icon(
                            Icons.brightness_1,
                            color: Colors.redAccent,
                            size: 8,
                          ),
                          top: 0,
                          right: 0,
                        )
                      : Container()
                ],
              ),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => Notifications(
                            adminID: widget.id,
                          )))),
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              sp.setBool('adminLogin', false);
              sp.remove('adminID');
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginOptions()),
                  (route) => false);
            },
          )
        ],
      ),
      body: ConnectivityScreenWrapper(
          disableInteraction: true,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .doc('admins/${widget.id}')
                .snapshots(),
            builder: (_, snapShot) {
              if (snapShot.hasData) {
                List employees = snapShot.data['employees'];
                Duration duration = Duration(seconds: 2);
                Future.delayed(duration)
                    .whenComplete(() => EasyLoading.dismiss());

                return ListView.separated(
                    itemCount: employees.length,
                    separatorBuilder: (_, index) =>
                        Divider(indent: 25.0, endIndent: 25.0),
                    itemBuilder: (_, index) {
                      return Users(
                        empId: employees[index]['id'],
                        empEmail: employees[index]['email'],
                        empName: employees[index]['name'],
                      );
                    });
              } else {
                Duration duration = Duration(seconds: 2);
                Future.delayed(duration)
                    .whenComplete(() => EasyLoading.dismiss());
                return Center(
                    child:
                        Text('Start adding user by clicking + in the bottom'));
              }
            },
          )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddUser(adminID: widget.id)));
        },
        label: Text('Add user'),
        icon: Icon(Icons.add),
      ),
    );
  }
}

class Users extends StatefulWidget {
  final String empId, empName, empEmail;

  Users(
      {@required this.empId, @required this.empEmail, @required this.empName});

  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends State<Users> {
  bool active;
  String time = '';

  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    super.initState();
  }

  void getUserData() {
    FirebaseDatabase.instance
        .reference()
        .child('users/${widget.empId}')
        .onValue
        .listen((event) {
      var snapshot = event.snapshot;
      if (mounted)
        setState(() {
          active = snapshot.value['active'];
          time = snapshot.value['time'];
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    String na = 'NA';
    return ListTile(
      title: Text(
        widget.empName,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(widget.empEmail),
      leading: active == true
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.green,
                ),
                Text("Online", style: TextStyle(fontWeight: FontWeight.bold))
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: Colors.grey,
                ),
                Text("Offline", style: TextStyle(fontWeight: FontWeight.bold))
              ],
            ),
      // trailing: IconButton(
      //   icon: Icon(Icons.edit,
      //     color: Colors.grey,
      //   ),
      //   onPressed: (){},
      // ),
      trailing: active == true
          ? Text(
              'Active since:\n${time == '' ? na : time}',
              textAlign: TextAlign.center,
            )
          : Text(
              'Last Seen:\n${time == '' ? na : time}',
              textAlign: TextAlign.center,
            ),
      onTap: () {
        time != ""
            ? Navigator.push(context,
                MaterialPageRoute(builder: (_) => Tracker(empID: widget.empId)))
            : Fluttertoast.showToast(
                msg: "User has not started location services.");
      },
    );
  }
}
