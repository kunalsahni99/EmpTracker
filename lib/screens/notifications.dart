import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class Notifications extends StatefulWidget {
  final String adminID;

  Notifications({@required this.adminID});

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User user = auth.currentUser;
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(190.h),
          child: AppBar(
            backgroundColor: Colors.black,
            flexibleSpace: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                  Colors.black,
                  Colors.transparent,
                ]))),
            title: Text(
              "Notifications",
              style: GoogleFonts.quicksand(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 70.nsp),
            ),
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop()),
            actions: [
              MaterialButton(
                onPressed: () {
                  Get.defaultDialog(
                      title: "Are you sure?",
                      middleText:
                          "Do you want to delete all your notifications.",
                      onConfirm: () {
                        FirebaseFirestore.instance
                            .collection("admins")
                            .doc(widget.adminID)
                            .collection("Notifications")
                            .snapshots()
                            .forEach((element) {
                          for (QueryDocumentSnapshot snapshot in element.docs) {
                            snapshot.reference.delete();
                          }
                        });
                        Get.back();
                        EasyLoading.showSuccess(
                            "All notifications successfully cleared.");
                      },
                      onCancel: () {});
                },
                child: Text(
                  "Clear All",
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          )),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("admins")
            .doc(widget.adminID)
            .collection("Notifications")
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data.size == 0)
            return new Container(
                height: MediaQuery.of(context).size.height,
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.grey,
                        size: 120.h,
                      ),
                      AutoSizeText(
                        'No new notifications.',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 45.nsp),
                      )
                    ])));

          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(bottom: 100.0),
                  child: new CircularProgressIndicator(
                    valueColor:
                        new AlwaysStoppedAnimation<Color>(Colors.black87),
                  ));

            default:
              return ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data.docs[index];
                    DateTime dt = doc['time'].toDate();

                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      key: UniqueKey(),
                      background: Container(
                          color: Colors.red,
                          child: Center(
                            child: Text(
                              "Dismiss",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 45.nsp),
                            ),
                          )),
                      child: Card(
                          child: ListTile(
                        leading: SizedBox.fromSize(
                            size: const Size(40, 40),
                            child: ClipOval(
                                child: Image.asset(
                              'images/cakewalk.png',
                              fit: BoxFit.fill,
                            ))),
                        title: AutoSizeText(
                          doc['title'],
                          overflow: TextOverflow.clip,
                          style: TextStyle(fontSize: 36.nsp),
                        ),
                        subtitle: AutoSizeText(doc['body'],
                            overflow: TextOverflow.clip,
                            style: TextStyle(fontSize: 36.nsp)),
                        trailing: AutoSizeText(
                            '${dt.day}.${dt.month}.${dt.year}\nTime: ${dt.hour >= 12 ? dt.hour - 12 : dt.hour}:${dt.minute} ${dt.hour >= 12 ? 'PM' : 'AM'}',
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 36.nsp,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo)),
                      )),
                      onDismissed: (direction) async {
                        FirebaseFirestore.instance
                            .collection("admins")
                            .doc(widget.adminID)
                            .collection("Notifications")
                            .doc(doc.id)
                            .delete();
                      },
                    );
                  });
          }
        },
      ),
    );
  }
}
