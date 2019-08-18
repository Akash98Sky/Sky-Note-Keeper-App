import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/screens/widgets/connectivity_widget.dart';
import 'package:note_keeper/utils/packageinfo_helper.dart';

class CheckUpdateAlert extends StatefulWidget {
  CheckUpdateAlert();
  @override
  State<StatefulWidget> createState() {
    return CheckUpdateState();
  }
}

class CheckUpdateState extends State<CheckUpdateAlert> {
  static Color iconColor;
  static Logger _log;
  
  String url;
  String checkUpdateTitle;
  Widget checkUpdateWidget;

  final PackageInfoHelper packageHelper = PackageInfoHelper();

  CheckUpdateState() {
    if (_log == null)
      _log = Logger(this.toString(minLevel: DiagnosticLevel.hint).split("#")[0]);
    _log.info("class is loaded...");
  }
  @override
  Widget build(BuildContext context) {
    iconColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).primaryColor
        : null;

    return StreamBuilder<DocumentSnapshot>(
        stream: Firestore.instance
            .collection('AppDoc')
            .document('updates')
            .snapshots(),
        builder: (context, snapshot) {
          if (!ConnectivityIndicator.isOnline || snapshot.hasError) {
            if (snapshot.hasError)
              _log.severe("Failed to check update | ${snapshot.error}");
            else
              _log.warning("Failed to check update | No internet connection");
            checkUpdateTitle = "Failed to check for update !";
            checkUpdateWidget = Container(
                child: LinearProgressIndicator(
              semanticsLabel: checkUpdateTitle,
              semanticsValue: "100",
              value: 1,
            ));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            checkUpdateTitle = "Checking for updates...";
            checkUpdateWidget = Container(
              child: LinearProgressIndicator(
                semanticsLabel: checkUpdateTitle,
                semanticsValue: "100",
                value: null,
              ),
            );
          } else if (snapshot.data.data['build'] >
              int.parse(packageHelper.appBuildNo)) {
            checkUpdateTitle = "New App Update Found !";
            checkUpdateWidget = Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                RaisedButton(
                  child: Icon(
                    Icons.file_download,
                    color: iconColor,
                  ),
                  onPressed: () {},
                ),
                RaisedButton(
                  child: Icon(
                    Icons.cancel,
                    color: iconColor,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          } else {
            checkUpdateTitle = "Your app is up-to date :)";
            checkUpdateWidget = Container(
                child: LinearProgressIndicator(
              semanticsLabel: checkUpdateTitle,
              semanticsValue: "100",
              value: 1,
            ));
          }
          return AlertDialog(
            title: Text(checkUpdateTitle),
            content: checkUpdateWidget,
          );
        });
  }
}
