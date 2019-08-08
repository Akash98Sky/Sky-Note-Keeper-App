import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteSettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NoteSettingsState();
  }
}

class NoteSettingsState extends State<NoteSettings> {
  static const _sharedPrefColorKey = "primaryColor";
  static const _defaultColor = Colors.orange;

  static bool _darkMode = false;
  static final _primaryColors = [
    Colors.red,
    Colors.indigo,
    Colors.orange,
    Colors.greenAccent,
    Colors.blueAccent
  ];
  static Color _color;

  @override
  void initState() {
    super.initState();
    _color = _defaultColor;
    _darkMode =
        DynamicTheme.of(context).brightness == Brightness.dark ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !moveToLastScreen();
      },
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => moveToLastScreen()),
            title: Text("Settings"),
          ),
          body: Container(
            padding: EdgeInsets.only(left: 20, right: 10),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        _setDarkMode(!_darkMode);
                        print("Dark Mode : $_darkMode");
                      },
                      child: Text(
                        "Dark Mode",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Checkbox(
                        value: _darkMode,
                        onChanged: (value) {
                          _setDarkMode(value);
                          print("Dark Mode : $_darkMode");
                        }),
                    Container(
                      width: 20,
                    ),
                    Text(
                      "Colour",
                      style: TextStyle(fontSize: 20),
                    ),
                    DropdownButton(
                      items: _primaryColors.map(_changeColorMenuItems).toList(),
                      value: _color,
                      onChanged: (selectedColor) {
                        _changeColor(primaryColor: selectedColor);
                        print("Colour : $_color");
                      },
                    )
                  ],
                ),
              ],
            ),
          )),
    );
  }

  DropdownMenuItem _changeColorMenuItems(Color value) {
    if (DynamicTheme.of(context).data.primaryColor == value)
      _color = value;
    return DropdownMenuItem(
      value: value,
      child: Container(
        margin: EdgeInsets.all(10),
        height: 20,
        width: 50,
        color: value,
      ),
    );
  }

  void _setDarkMode(bool isDark) {
    _darkMode = isDark;
    DynamicTheme.of(context)
        .setBrightness(isDark ? Brightness.dark : Brightness.light);
    if (DynamicTheme.of(context).data.primaryColor != _color)
      _changeColor(primaryColor: _color);
  }

  void _changeColor({Color primaryColor}) {
    _color = primaryColor;
    DynamicTheme.of(context).setThemeData(ThemeData(
        brightness: _darkMode ? Brightness.dark : Brightness.light,
        primaryColor: primaryColor));
    _saveColor(primaryColor);
  }

  Future<void> _saveColor(Color primaryColor) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sharedPrefColorKey, primaryColor.value);
    print("Colour code :: ${primaryColor.value}");
  }

  bool moveToLastScreen() {
    return Navigator.of(context).pop(true);
  }
}
