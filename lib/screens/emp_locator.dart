import 'dart:async';
import 'dart:core';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_intent/android_intent.dart';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login/login_options.dart';
import '../utils/file_manager.dart';
import '../utils/location_callback_handler.dart';
import '../utils/location_service_repository.dart';

class EmpLocator extends StatefulWidget {
  @override
  _EmpLocatorState createState() => _EmpLocatorState();
}

class _EmpLocatorState extends State<EmpLocator> {
  ReceivePort port = ReceivePort();

  String logStr = '';
  bool isRunning;
  LocationDto lastLocation;
  DateTime lastTimeLocation;
  SharedPreferences preferences;
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    User user = _auth.currentUser;
    FirebaseDatabase.instance
        .reference()
        .child('/users/${user.uid}')
        .onDisconnect()
        .update({
      'active': false,
    });

    if (IsolateNameServer.lookupPortByName(
            LocationServiceRepository.isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          LocationServiceRepository.isolateName);
    }

    IsolateNameServer.registerPortWithName(
        port.sendPort, LocationServiceRepository.isolateName);

    port.listen(
      (dynamic data) async {
        await updateUI(data);
        preferences = await SharedPreferences.getInstance();
        preferences.setString('lat', data.toString());
      },
    );

    initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> updateUI(LocationDto data) async {
    final log = await FileManager.readLogFile();
    await _updateNotificationText(data);

    setState(() {
      if (data != null) {
        lastLocation = data;
        lastTimeLocation = DateTime.now();
      }
      logStr = log;
    });
  }

  void _openLocationSettingsConfiguration() {
    final AndroidIntent intent = const AndroidIntent(
      action: 'action_location_source_settings',
    );
    intent.launch();
  }

  Future<void> _updateNotificationText(LocationDto data) async {
    if (data == null) {
      return;
    }

    await BackgroundLocator.updateNotificationText(
        title: "Running in background");
  }

  Future<void> initPlatformState() async {
    print('Initializing...');
    await BackgroundLocator.initialize();
    logStr = await FileManager.readLogFile();
    print('Initialization done');
    final _isRunning = await BackgroundLocator.isServiceRunning();
    setState(() {
      isRunning = _isRunning;
    });
    print('Running ${isRunning.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    final start = SizedBox(
      width: 200,
      child: MaterialButton(
        color: Colors.black,
        child: Text(
          'Start Services',
          style: TextStyle(color: Colors.white),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        onPressed: () {
          if (isRunning)
            Get.snackbar("Services are already running", "",
                snackPosition: SnackPosition.BOTTOM,
                animationDuration: Duration(milliseconds: 750));
          else
            _onStart();
        },
      ),
    );
    final stop = SizedBox(
      width: 200,
      child: MaterialButton(
        color: Colors.black,
        child: Text(
          'Stop Services',
          style: TextStyle(color: Colors.white),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        onPressed: () {
          if (!isRunning)
            Get.snackbar("Services are not running", "",
                snackPosition: SnackPosition.BOTTOM);
          else
            onStop();
        },
      ),
    );

    String msgStatus = "-";
    if (isRunning != null) {
      if (isRunning) {
        msgStatus = 'Is running';
      } else {
        msgStatus = 'Is not running';
      }
    }
    final status = Text(
      "Status: $msgStatus",
      style: TextStyle(fontWeight: FontWeight.bold),
    );
    final log = Text(
      logStr,
    );
    void _signOut() async {
      EasyLoading.show(status: "Signing out");
      Duration duration = Duration(seconds: 1);
      Future.delayed(duration).whenComplete(() async {
        await FirebaseAuth.instance
            .signOut()
            .whenComplete(() => EasyLoading.dismiss());
        preferences = await SharedPreferences.getInstance();
        preferences.setBool('empLogin', false);
        preferences.remove('empID');
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginOptions()),
            (route) => false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EmpLocator'),
        // actions: [
        //   IconButton(
        //       icon: Icon(Icons.person), onPressed: () => Get.to(Profile()))
        // ],
      ),
      body: ConnectivityScreenWrapper(
        disableInteraction: true,
        child: Container(
          width: double.maxFinite,
          height: Get.height,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              start,
              stop,
              status,
              Container(
                margin: EdgeInsets.only(top: 40.0),
                child: MaterialButton(
                  color: Colors.black,
                  child: Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  onPressed: () async {
                    if (!isRunning)
                      _signOut();
                    else
                      Get.defaultDialog(
                          title: "Are you sure?",
                          middleText: "Your services will be stopped.",
                          onCancel: () => Get.back(),
                          onConfirm: () async {
                            await onStop();
                            _signOut();
                          });
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void onStop() async {
    EasyLoading.show(status: "Stopping Services");
    Duration duration = Duration(seconds: 1);
    Future.delayed(duration).whenComplete(() async {
      BackgroundLocator.unRegisterLocationUpdate().whenComplete(() {
        FileManager.clearLogFile();
        setState(() {
          logStr = '';
        });
      });
      User user = _auth.currentUser;
      var getData =
          await FirebaseFirestore.instance.doc("EmpLocator/${user.uid}").get();
      var adminID = getData['adminID'];

      FirebaseDatabase.instance
          .reference()
          .child('/users/${user.uid}')
          .update({
            'active': false,
            'time': DateFormat('dd LLLL h:mma').format(Timestamp.now().toDate())
          })
          .whenComplete(() => FirebaseFirestore.instance
                  .collection("admins")
                  .doc(adminID)
                  .collection("Notifications")
                  .add({
                "title": "A user turned off location services.",
                "body": "Email:${user.email}\nName:${user.displayName}",
                "time": FieldValue.serverTimestamp(),
              }))
          .whenComplete(() => EasyLoading.dismiss());
      final _isRunning = await BackgroundLocator.isServiceRunning();

      setState(() {
        isRunning = _isRunning;
//      lastTimeLocation = null;
//      lastLocation = null;
      });
    });
  }

  void _onStart() async {
    if (await _checkLocationPermission()) {
      if (await geo.Geolocator.isLocationServiceEnabled()) {
        EasyLoading.show(status: "Starting Services");
        Duration duration = Duration(seconds: 1);
        Future.delayed(duration).whenComplete(() async {
          await _startEmpLocator();
          final _isRunning = await BackgroundLocator.isServiceRunning();
          print(_isRunning);

          setState(() {
            isRunning = _isRunning;
            lastTimeLocation = null;
            lastLocation = null;
          });
          User user = _auth.currentUser;
          FirebaseDatabase.instance
              .reference()
              .child('/users/${user.uid}')
              .update({
            'active': true,
            'time': DateFormat('dd LLLL h:mma').format(Timestamp.now().toDate())
          }).whenComplete(() => EasyLoading.dismiss());
        });
      } else
        _openLocationSettingsConfiguration();
    } else {
      // show error
    }
  }

  Future<bool> _checkLocationPermission() async {
    final access = await LocationPermissions().checkPermissionStatus();
    switch (access) {
      case PermissionStatus.unknown:
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await LocationPermissions().requestPermissions(
          permissionLevel: LocationPermissionLevel.locationAlways,
        );
        if (permission == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
        break;
      case PermissionStatus.granted:
        return true;
        break;
      default:
        return false;
        break;
    }
  }

  void _startEmpLocator() async {
    preferences = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {
      'countInit': 1,
      'id': preferences.getString('empID')
    };
    BackgroundLocator.registerLocationUpdate(LocationCallbackHandler.callback,
        initCallback: LocationCallbackHandler.initCallback,
        initDataCallback: data,
/*
        Comment initDataCallback, so service not set init variable,
        variable stay with value of last run after unRegisterLocationUpdate
 */
        disposeCallback: LocationCallbackHandler.disposeCallback,
        iosSettings: IOSSettings(
            accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 0),
        autoStop: false,
        androidSettings: AndroidSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            interval: 30,
            distanceFilter: 0,
            client: LocationClient.google,
            androidNotificationSettings: AndroidNotificationSettings(
                notificationChannelName: 'Location tracking',
                notificationTitle: 'Start Location Tracking',
                notificationMsg: 'Services are running.',
                notificationBigMsg: 'Services are running.',
                notificationIcon: '',
                notificationIconColor: Colors.grey,
                notificationTapCallback:
                    LocationCallbackHandler.notificationCallback)));
  }
}
