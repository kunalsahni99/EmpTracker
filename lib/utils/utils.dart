import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Utils{
  FirebaseAuth _auth=FirebaseAuth.instance;
  prefs() async => await SharedPreferences.getInstance();
  User user() =>_auth.currentUser;
}

class Opened extends ChangeNotifier{
  bool isOpened = false, showPath = false;
  int whichTimeRange = 1;

  bool get opened => isOpened;
  int get timeRange => whichTimeRange;
  bool get path => showPath;

  void changeOpened(bool open){
    isOpened = open;
    notifyListeners();
  }

  void changeTimeRange(int range){
    whichTimeRange = range;
    notifyListeners();
  }

  void changeShowPath(bool path){
    showPath = path;
    notifyListeners();
  }
}

class Distance extends ChangeNotifier{
  double distance = 0.0;

  double get dist => distance;

  void initDistance(double d){
    distance = d;
    notifyListeners();
  }
}