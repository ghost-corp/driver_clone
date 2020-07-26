import 'package:driver_clone/home/drawer_option.dart';
import 'package:driver_clone/models/auth_model.dart';
import 'package:driver_clone/models/location_model.dart';
import 'package:driver_clone/models/trip_model.dart';
import 'package:driver_clone/widgets/NavCenterButton.dart';
import 'package:driver_clone/widgets/online_toggle_button.dart';
import 'package:driver_clone/widgets/request_card.dart';
import 'package:driver_clone/widgets/rider_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tindercard/flutter_tindercard.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController mapController;
  CardController swipeController;
  String mapStyle;

  void getMapStyle() async {
    String style = await rootBundle.loadString("assets/grey_detailed.json");
    if (mounted) {
      setState(() {
        mapStyle = style;
      });
    } else {
      mapStyle = style;
    }
  }

  @override
  void initState() {
    getMapStyle();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
    double iconSize = 30;
    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: SideDrawerOption(),
      ),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Consumer<AuthModel>(
          builder: (context, authModel, _) {
            Widget alternate = GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "edit_account",
                    arguments: "You have to setup your account");
              },
              child: ToggleOnline(
                isInitiallyOffline: true,
              ),
            );
            if (authModel.userDetails == null) {
              return alternate;
            }

            if (authModel.userDetails.firstName == "" ||
                authModel.userDetails.lastName == "") {
              return alternate;
            }

            bool isOffline = true;
            if (authModel.userDetails.isOnline == false ||
                authModel.userDetails.isOnline == null) {
              isOffline = true;
            } else {
              isOffline = false;
            }
            return ToggleOnline(
              isInitiallyOffline: isOffline,
              onOffline: () => authModel.setOnlineStatus(false),
              onOnline: () => authModel.setOnlineStatus(true),
            );
          },
        ),
        leading: Center(
          child: GestureDetector(
            onTap: () {
              scaffoldKey.currentState.openDrawer();
            },
            child: CircleAvatar(
              child: ClipOval(
                child: Image.asset("images/avatar.jpg"),
              ),
              maxRadius: 20,
            ),
          ),
        ),
        actions: <Widget>[
          Card(
            elevation: 4,
            shape: CircleBorder(),
            child: CircleAvatar(
              child: Icon(Icons.search, size: 20),
              maxRadius: 20,
              backgroundColor: Colors.white,
            ),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Consumer<LocationModel>(
              builder: (context, locationModel, _) {
                if (locationModel.currentLocation == null) {
                  return Container();
                }

                return Stack(
                  children: <Widget>[
                    mapStyle == null
                        ? Container()
                        : GoogleMap(
                            onMapCreated: (controller) {
                              mapController = controller;
                              mapController.setMapStyle(mapStyle);
                            },
                            initialCameraPosition: CameraPosition(
                                target: LatLng(
                                    locationModel.currentLocation.latitude,
                                    locationModel.currentLocation.longitude),
                                zoom: 12.5),
                            myLocationEnabled: true,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                    Align(
                      alignment: Provider.of<TripModel>(context, listen: true)
                                  .requests
                                  .length ==
                              0
                          ? Alignment.bottomRight
                          : Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: NavCenterButton(
                          onTap: () {
                            mapController.animateCamera(
                                CameraUpdate.newCameraPosition(CameraPosition(
                                    target: LatLng(
                                        locationModel.currentLocation.latitude,
                                        locationModel
                                            .currentLocation.longitude),
                                    zoom: 17)));
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                          padding: EdgeInsets.all(1),
                          child: Consumer<TripModel>(
                            builder: (context, tripModel, _) {
                              if (tripModel.requests.length == 0) {
                                return Container(height: 0, width: 0);
                              }

                              if (tripModel.currentTrip != null) {
                                return Consumer<TripModel>(
                                  builder: (context, tripModel, _) {
                                    return RiderInfo(
                                      trip: tripModel.currentTrip,
                                    );
                                  },
                                );
                              }
                              return Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: TinderSwapCard(
                                    swipeUp: false,
                                    swipeDown: false,
                                    cardController: swipeController,
                                    allowVerticalMovement: false,
                                    orientation: AmassOrientation.BOTTOM,
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.9,
                                    maxHeight:
                                        MediaQuery.of(context).size.width *
                                            0.65,
                                    minWidth:
                                        MediaQuery.of(context).size.width * 0.8,
                                    minHeight:
                                        MediaQuery.of(context).size.width *
                                            0.55,
                                    cardBuilder: (context, index) {
                                      return TripCard(
                                        trip: tripModel.requests[index],
                                      );
                                    },
                                    stackNum: 3,
                                    swipeCompleteCallback:
                                        (orientation, index) {
                                      if (orientation ==
                                              CardSwipeOrientation.LEFT ||
                                          orientation ==
                                              CardSwipeOrientation.RIGHT) {
                                        print("swiped");
                                        tripModel.removeRequest(index);
                                      }
                                    },
                                    totalNum: tripModel.requests.length),
                              );
                            },
                          )),
                    )
                  ],
                );
              },
            ),
          ),
          Container(
            height: kToolbarHeight,
            padding: EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(
                  Icons.explore,
                  size: iconSize,
                ),
                Icon(
                  Icons.show_chart,
                  size: iconSize,
                ),
                Icon(
                  Icons.settings,
                  size: iconSize,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
