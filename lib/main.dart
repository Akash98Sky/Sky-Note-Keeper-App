import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/screens/note_list.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  Logger.root.level = Level.FINER;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.loggerName}: ${rec.message}');
  });
  var myApp = MyApp();
  myApp._loadColorIndex();
  runApp(myApp);
}

class MyApp extends StatelessWidget {
  static final Logger log = new Logger('MyApp');

  static const _sharedPrefColorKey = "primaryColor";
  static const List<Color> primaryColors = [
    Colors.red,
    Colors.indigo,
    Colors.orange,
    Colors.green,
    Colors.blue
  ];
  static const Color defaultColor = Colors.orange;

  static Color _color;

  MyApp() {
    log.fine("class is loaded...");
  }

  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => new ThemeData(
              primarySwatch: _color,
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

  Future<void> _loadColorIndex() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _color = primaryColors[prefs.getInt(_sharedPrefColorKey) ??
        MyApp.primaryColors.indexOf(MyApp.defaultColor)];
    log.info("Colour code loaded :: $_color");
  }
}
