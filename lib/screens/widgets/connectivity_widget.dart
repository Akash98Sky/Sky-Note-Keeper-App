import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class ConnectivityWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ConnectivityIndicator();
  }
}

class ConnectivityIndicator extends State<ConnectivityWidget> {
  static bool isOnline = false;
  static var _subscription;
  static Logger _log;

  ConnectivityIndicator() {
    if (_log == null)
      _log = Logger(this.toString(minLevel: DiagnosticLevel.hint).split("#")[0]);
  }

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      _log.info("Connectivity => $result");
      if ((result == ConnectivityResult.mobile ||
              result == ConnectivityResult.wifi) &&
          isOnline == false)
        setState(() {
          isOnline = true;
        });
      else if (isOnline == true)
        setState(() {
          isOnline = false;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      child: CircleAvatar(
        child: CircleAvatar(
          backgroundColor: isOnline ? Colors.lightGreen : Colors.redAccent,
          radius: 9,
        ),
        backgroundColor: Colors.white,
        radius: 12,
      ),
      message: "Connectivity Status",
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
