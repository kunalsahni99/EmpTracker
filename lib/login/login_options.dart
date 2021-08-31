import 'package:flutter/material.dart';

import 'login.dart';

class LoginOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 20.0),
            child: MaterialButton(
              minWidth: 200.0,
              height: 50.0,
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => Login(isAdmin: false)));
              },
              child: Text(
                'Login as Employee',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              color: Colors.black,
            ),
          ),
          MaterialButton(
            minWidth: 200.0,
            height: 50.0,
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => Login(isAdmin: true)));
            },
            child: Text(
              'Login as Admin',
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
            color: Colors.black,
          )
        ],
      ),
    ));
  }
}
