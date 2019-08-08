import 'package:flutter/material.dart';
import 'package:note_keeper/screens/note_list.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static const _sharedPrefColorKey = "primaryColor";
  static const _defaultColor = Colors.orange;

  static Color _color;

  MyApp() {
    _loadColor().then((value) {
                _color = Color(value);
              }
              );
    print("MyApp class is loaded...");
  }

  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => new ThemeData(
              primaryColor: _color,
              brightness: brightness,
            ),
        themedWidgetBuilder: (context, theme) {
          return MaterialApp(
            title: 'Note Keeper',
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: NoteList(),
          );
        });
  }

  Future<int> _loadColor() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sharedPrefColorKey) ?? _defaultColor.value;
  }
}