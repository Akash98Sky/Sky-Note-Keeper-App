import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteSettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NoteSettingsState();
  }
}

class NoteSettingsState extends State<NoteSettings> {
  static const _sharedPrefColorKey = "primaryColor";

  static bool _darkMode = false;
  static int _selectedColorIndex =
      MyApp.primaryColors.indexOf(MyApp.defaultColor);

  static Logger log;

  NoteSettingsState() {
    log = Logger(this.toString(minLevel: DiagnosticLevel.hint));
    log.info("class is loaded...");
  }

  @override
  void initState() {
    super.initState();
    _loadColorData();
    log.finest("init complete...");
  }

  Future<void> _loadColorData() async {
    _selectedColorIndex = await _loadColorIndex();
    log.info("Color code loaded : ${MyApp.primaryColors[_selectedColorIndex]}");
    _darkMode =
        DynamicTheme.of(context).brightness == Brightness.dark ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    log.finest("Widget build started..");

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
                        log.info("Dark Mode : $_darkMode");
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
                          log.info("Dark Mode : $_darkMode");
                        }),
                    Container(
                      width: 20,
                    ),
                    Text(
                      "Colour",
                      style: TextStyle(fontSize: 20),
                    ),
                    DropdownButton(
                      items: MyApp.primaryColors
                          .map(_changeColorMenuItems)
                          .toList(),
                      value: MyApp.primaryColors[_selectedColorIndex],
                      onChanged: (selectedColor) {
                        _selectedColorIndex =
                            MyApp.primaryColors.indexOf(selectedColor);
                        _changeColor(primaryColor: selectedColor);
                      },
                    )
                  ],
                ),
                FlatButton(
                  child: Text("Check for Update"),
                  onPressed: () {
                    _checkForUpdate();
                  },
                ),
              ],
            ),
          )),
    );
  }

  void _checkForUpdate() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Checking for updates..."),
            content: Container(
              child: LinearProgressIndicator(
                semanticsLabel: "Checking For updates...",
                semanticsValue: "100",
                value: null,
              ),
            ),
          );
        });
  }

  DropdownMenuItem _changeColorMenuItems(Color value) {
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

    if (DynamicTheme.of(context).data.primaryColor !=
        MyApp.primaryColors[_selectedColorIndex])
      _changeColor(primaryColor: MyApp.primaryColors[_selectedColorIndex]);
  }

  void _changeColor({Color primaryColor}) {
    DynamicTheme.of(context).setThemeData(ThemeData(
      brightness: _darkMode ? Brightness.dark : Brightness.light,
      primarySwatch: primaryColor,
    ));
    _saveColorIndex(_selectedColorIndex);
  }

  Future<void> _saveColorIndex(int primaryColorIndex) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_sharedPrefColorKey, primaryColorIndex);
    
    log.info("Colour code saved :: ${MyApp.primaryColors[primaryColorIndex]}");
  }

  Future<int> _loadColorIndex() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_sharedPrefColorKey) ??
        MyApp.primaryColors.indexOf(MyApp.defaultColor);
  }

  bool moveToLastScreen() {
    return Navigator.of(context).pop(true);
  }
}
