import 'package:flutter/material.dart';

class NoteSettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NoteSettingsState();
  }
}

class NoteSettingsState extends State<NoteSettings> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        moveToLastScreen();
      }, 
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              moveToLastScreen();
            }
          ),
          title: Text("Settings"),
        ),
      ),
    );
  }

  bool moveToLastScreen() {
    return Navigator.pop(context, true);
  }

}