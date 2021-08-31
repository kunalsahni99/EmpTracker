import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fab_dialer/flutter_fab_dialer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../utils/utils.dart';

class Tracker extends StatefulWidget {
  final String empID;

  Tracker({this.empID});

  @override
  _TrackerState createState() => _TrackerState();
}

class _TrackerState extends State<Tracker> {
  GoogleMapController mapController;
  Set<Marker> _markers = Set(), tempMarkers = Set();
  Set<Polyline> _polyLines = Set();
  Set<Map<String, dynamic>> filteredList = Set();
  BitmapDescriptor locationIcon;
  int i = 0;
  DateTime now = DateTime.now(), dateTime;
  List<LatLng> time8to12List = [], time12to4List = [], time4to8List = [];
  List time8to12 = [], time12to4 = [], time4to8 = [];

  void _onMapCreated(GoogleMapController controller) =>
      mapController = controller;

  addToList({Set<Map<String, dynamic>> track, Map<String, dynamic> element}) {
    if (track != null) {
      track.forEach((element){
        if (element != track.elementAt(track.length-1)){
          checkRange(element);
        }
      });
    } else if (element != null) {
      checkRange(element);
    }
  }

  double compDistance(double startLat, double startLong, double endLat, double endLong) =>
      Geolocator.distanceBetween(startLat, startLong, endLat, endLong);

  calcDistance({Distance d, Set<Map<String, dynamic>> disTrack}){
    double tempDist = 0.0;
    i = 0;
    d.initDistance(0.0);
    var cor1, cor2;
    if (disTrack != null){
      int length = disTrack.length;
      //todo: change i+1 to i+10 and check whether element at (i+10)th position is not null
      while (i < length && i != length-1){
        cor1 = disTrack.elementAt(i);
        cor2 = disTrack.elementAt(i+1);
        tempDist += compDistance(cor1['lat'], cor1['long'],
              cor2['lat'], cor2['long']);
        i++;
      }
    }
    d.initDistance(tempDist);
  }

  checkRange(Map<String, dynamic> el) {
    DateTime dt = DateFormat('dd MMMM').add_jms().parse(el['time']);
    if (dt.hour >= 8 && dt.hour < 12) {
      time8to12.add(el);
      time8to12List.add(LatLng(el['lat'], el['long']));
    } else if (dt.hour >= 12 && dt.hour < 16) {
      time12to4.add(el);
      time12to4List.add(LatLng(el['lat'], el['long']));
    } else if (dt.hour >= 16 && dt.hour < 20) {
      time4to8.add(el);
      time4to8List.add(LatLng(el['lat'], el['long']));
    }
  }

  List<FabMiniMenuItem> fabList(Opened opened){
    return [
      FabMiniMenuItem.withText(
          Icon(Icons.timelapse_sharp), Colors.blue, 4.0, "Location History",
              () {
            if (time8to12.isNotEmpty) {
              tempMarkers.clear();
              tempMarkers.addAll(_markers);
              _markers.clear();
              _polyLines.clear();
              time8to12.forEach((element) {
                addMarker(LatLng(element['lat'], element['long']), element['time']);
              });
              opened.changeOpened(true);
              opened.changeTimeRange(1);
            } else
              Fluttertoast.showToast(msg: 'No location history in this range');
          }, "8 AM - 12 PM", Colors.grey, Colors.white, true),
      FabMiniMenuItem.withText(
          Icon(Icons.timelapse_sharp), Colors.blue, 4.0, "Location History",
              () {
            if (time12to4.isNotEmpty) {
              tempMarkers.clear();
              tempMarkers.addAll(_markers);
              _markers.clear();
              _polyLines.clear();
              time12to4.forEach((element) {
                addMarker(LatLng(element['lat'], element['long']), element['time']);
              });
              opened.changeOpened(true);
              opened.changeTimeRange(2);
            } else
              Fluttertoast.showToast(msg: 'No location history in this range');
          }, "12-4 PM", Colors.grey, Colors.white, true),
      FabMiniMenuItem.withText(
          Icon(Icons.timelapse_sharp), Colors.blue, 4.0, "Location History",
              () {
            if (time4to8.isNotEmpty) {
              tempMarkers.clear();
              tempMarkers.addAll(_markers);
              _markers.clear();
              _polyLines.clear();
              print(_markers);
              print(tempMarkers);
              time4to8.forEach((element) {
                addMarker(LatLng(element['lat'], element['long']), element['time']);
              });
              opened.changeOpened(true);
              opened.changeTimeRange(3);
            } else
              Fluttertoast.showToast(msg: 'No location history in this range');
          }, "4-8 PM", Colors.grey, Colors.white, true),
    ];
  }

  @override
  void initState() {
    super.initState();
    setIcon();
    getList(FirebaseFirestore.instance
        .doc('Locator/${widget.empID}')
        .get());
  }

  getList(Future<DocumentSnapshot> snapShot) async{
    var snap = await snapShot;
    snap.data()['track'].forEach((ele){
      dateTime = DateFormat('dd MMMM').add_jms().parse(ele['time']);
      if (dateTime.day == now.day && dateTime.month == now.month)
        filteredList.add(ele);
    });
    addToList(track: filteredList);
  }

  addMarker(LatLng latLng, String id) {
    Marker resultMarker = Marker(
      icon: locationIcon,
      infoWindow: InfoWindow(
        title: id,
      ),
      markerId: MarkerId(id),
      position: latLng,
    );
    _markers.add(resultMarker);
  }

  void setIcon() async {
    locationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'images/map_marker.png');
  }

  @override
  Widget build(BuildContext context) {
    Opened opened = Provider.of<Opened>(context);
    Distance dist = Provider.of<Distance>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracker'),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .doc('Locator/${widget.empID}')
                .snapshots(),
            builder: (context, snapShot) {
              if (snapShot.hasData) {
                List track = snapShot.data['track'];
                int len = track.length;
                if (track.isNotEmpty) {
                  addToList(element: track[len - 1]);
                  addMarker(
                      LatLng(track[len - 1]['lat'],
                          track[len - 1]['long']),
                      track[len - 1]['time']);
                  filteredList.add(track[len-1]);
                }
                return GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: snapShot.hasData
                        ? LatLng(track[track.length - 1]['lat'],
                            track[track.length - 1]['long'])
                        : LatLng(20.593684, 78.96288),
                    zoom: snapShot.hasData ? 17.0 : 5.0,
                  ),
                  markers: _markers,
                  polylines: _polyLines,
                );
              }
              return Container();
            },
          ),

          Positioned(
            top: 10.0,
            right: 10.0,
            child: FloatingActionButton(
              onPressed: (){
                calcDistance(d: dist, disTrack: filteredList);
                showDialog(
                  context: context,
                  builder: (con) => dist.dist !=  null ? AlertDialog(
                    title: Text('Distance travelled',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25.0
                      ),
                    ),
                    content: Container(
                      height: 200.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_walk_rounded, size: 100.0),
                          SizedBox(height: 10.0),
                          Text((dist.dist/1000).toStringAsFixed(2) + ' km',
                            style: TextStyle(
                              fontSize: 30.0,
                              color: Colors.black54
                            ),
                          ),
                        ],
                      ),
                    ),
                  ) :
                  CircularProgressIndicator()
                );
              },
              child: Icon(Icons.directions_walk),
            )
          ),

          Positioned(
            top: 10.0,
            left: 10.0,
            child: Visibility(
              visible: opened.opened,
              child: InkWell(
                onTap: () {
                  _markers.clear();
                  _markers.addAll(tempMarkers);
                  _polyLines.clear();
                  opened.changeOpened(false);
                  opened.changeShowPath(false);
                  opened.changeTimeRange(0);
                },
                child: Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(Icons.close_sharp, color: Colors.black),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10.0,
            left: 10.0,
            child: Visibility(
              visible: opened.opened,
              child: FloatingActionButton.extended(
                onPressed: () {
                  opened.changeShowPath(!opened.path);
                  if (opened.path) {
                    _markers.clear();
                    switch (opened.timeRange) {
                      case 1:
                        _polyLines.add(Polyline(
                            polylineId: PolylineId(time8to12[0]['time']),
                            points: time8to12List,
                            color: Colors.blue,
                            startCap: Cap.roundCap,
                            endCap: Cap.roundCap,
                            jointType: JointType.bevel));
                        break;
                      case 2:
                        _polyLines.add(Polyline(
                            polylineId: PolylineId(time12to4[0]['time']),
                            points: time12to4List,
                            color: Colors.blue,
                            startCap: Cap.roundCap,
                            endCap: Cap.roundCap,
                            jointType: JointType.bevel));
                        break;
                      case 3:
                        _polyLines.add(Polyline(
                            polylineId: PolylineId(time4to8[0]['time']),
                            points: time4to8List,
                            color: Colors.blue,
                            startCap: Cap.roundCap,
                            endCap: Cap.roundCap,
                            jointType: JointType.bevel));
                        break;
                    }
                  } else{
                    _polyLines.clear();
                    switch(opened.timeRange){
                      case 1:
                        time8to12.forEach((element) {
                          addMarker(LatLng(element['lat'], element['long']), element['time']);
                        });
                        break;
                      case 2:
                        time12to4.forEach((element) {
                          addMarker(LatLng(element['lat'], element['long']), element['time']);
                        });
                        break;
                      case 3:
                        time4to8.forEach((element) {
                          addMarker(LatLng(element['lat'], element['long']), element['time']);
                        });
                        break;
                    }
                  }
                },
                label: Text(opened.path ? 'Close path' : 'Show path'),
                icon:
                    Icon(opened.path ? Icons.close_sharp : Icons.show_chart_sharp),
                backgroundColor: opened.path ? Colors.red : Colors.blue,
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 80.0),
        child: FabDialer(fabList(opened), Colors.blue, Icon(Icons.add),
            AnimationStyle.slideInDown),
      ),
    );
  }
}
