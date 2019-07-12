import 'package:flutter/material.dart';

class Utils {
  static void showAlertDialog(BuildContext context ,String title, String message, {Color titleCol, Color msgCol}) {
    AlertDialog alertDialog = AlertDialog(
      title: Text(title, style: TextStyle(color: titleCol),),
      content: Text(message, style: TextStyle(color: msgCol),),
    );
    showDialog(context: context, builder: (_) => alertDialog);
  }

  static void showSnackBar(BuildContext context, String message, {Duration d}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: d == null?Duration(seconds: 2): d,
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }
}