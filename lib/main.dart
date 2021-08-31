import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/user_list.dart';
import 'login/login_options.dart';
import 'screens/emp_locator.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SplashScreen());
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SharedPreferences sharedPreferences;
  bool isAdminLogin = false, isEmpLogin = false;

  @override
  void initState() {
    super.initState();
    getPrefs();
  }

  void getPrefs() async {
    sharedPreferences = await Utils().prefs();
    setState(() {
      isAdminLogin = sharedPreferences.getBool('adminLogin') ?? false;
      isEmpLogin = sharedPreferences.getBool('empLogin') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Opened()),
        ChangeNotifierProvider.value(value: Distance())
      ],
      child: ScreenUtilInit(
          designSize: Size(1080, 2160),
          allowFontScaling: false,
          builder: () => ConnectivityAppWrapper(
                  app: GetMaterialApp(
                debugShowCheckedModeBanner: false,
                home: isAdminLogin
                    ? UserList(
                        id: sharedPreferences.getString('adminID'),
                      )
                    : (isEmpLogin ? EmpLocator() : LoginOptions()),
                builder: EasyLoading.init(),
              ))),
    );
  }
}
