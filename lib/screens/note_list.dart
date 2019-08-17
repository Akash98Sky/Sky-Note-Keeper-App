import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/models/note.dart';
import 'package:note_keeper/screens/note_detail.dart';
import 'package:note_keeper/screens/note_settings.dart';
import 'package:note_keeper/utils/database_helper.dart';
import 'package:note_keeper/utils/utils.dart';

class NoteList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NoteListState();
  }
}

class NoteListState extends State<NoteList> {
  static const List<String> _popupOptions = ['Settings', 'About'];

  static Logger log;

  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Note> noteList;
  int _count = 0;

  NoteListState() {
    log = Logger(this.toString(minLevel: DiagnosticLevel.hint));
    log.info("class is loaded...");
  }

  @override
  void initState() {
    super.initState();

    updateListView().whenComplete(() {
      if (noteList == null) noteList = List<Note>();
    });

    log.info("init complete...");
  }

  @override
  Widget build(BuildContext context) {
    log.info("Widget build started...");

    return WillPopScope(
        onWillPop: () async => _exitAlertDialog(context),
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: EdgeInsets.all(4),
              child: Image.asset(
                'icons/launcher_icon.png',
              ),
            ),
            title: Text('Notes'),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: choiceAction,
                itemBuilder: (BuildContext context) {
                  return _popupOptions.map((String choice) {
                    return PopupMenuItem(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
              )
            ],
          ),
          body: getNodeListView(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              log.info("FAB pressed");
              navToDetail(Note('', '', 1), 'Add Note');
            },
            tooltip: 'Add Note',
            child: Icon(Icons.add_box),
            backgroundColor:
                DynamicTheme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : null,
            foregroundColor:
                DynamicTheme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : null,
          ),
        ));
  }

  bool _exitAlertDialog(BuildContext context) {
    return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Are you sure?'),
            content: Text('Do you want to exit'),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              FlatButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  ListView getNodeListView() {
    TextStyle titleStyle = Theme.of(context).textTheme.subhead;

    return ListView.builder(
      itemCount: _count,
      itemBuilder: (BuildContext context, int pos) {
        return Card(
          elevation: 2.0,
          color: DynamicTheme.of(context).brightness == Brightness.dark
              ? Colors.black12
              : null,
          child: ListTile(
            leading: CircleAvatar(
              child: getPriorityIcon(this.noteList[pos].priority),
              backgroundColor: getPriorityColor(this.noteList[pos].priority),
            ),
            title: Text(this.noteList[pos].title, style: titleStyle),
            subtitle: Text(this.noteList[pos].date),
            trailing: GestureDetector(
              child: Icon(
                Icons.delete,
                color: Colors.grey,
              ),
              onTap: () {
                _delete(context, noteList[pos]);
              },
            ),
            onTap: () {
              debugPrint('ListTile Tapped');
              navToDetail(this.noteList[pos], 'Edit Node');
            },
          ),
        );
      },
    );
  }

  Future<void> updateListView() async {
    await databaseHelper.initializeDatabase();

    this.noteList = await databaseHelper.getNoteList();
    if (noteList != null && this._count != noteList.length)
      setState(() {
        this._count = noteList.length;
      });

    log.info("Updated List View");
  }

  void choiceAction(String choice) {
    if (choice == _popupOptions[0])
      navToSettings();
    else if (choice == _popupOptions[1])
      Utils.showAlertDialog(context, "Sky Note Keeper",
          "Developer & Designer =>\n Akash Mondal (Akash98Sky)",
          titleCol: Colors.lightBlue, msgCol: Colors.orange);
    else
      return null;
  }

  Color getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return Colors.red[500];
      case 1:
        return Colors.yellow;
      case 2:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Icon getPriorityIcon(int priority) {
    switch (priority) {
      case 0:
        return Icon(
          Icons.priority_high,
          color: Colors.black,
        );
        break;
      case 1:
        return Icon(
          Icons.rotate_right,
          color: Colors.black,
        );
        break;
      default:
        return Icon(
          Icons.low_priority,
          color: Colors.black,
        );
    }
  }

  void _delete(BuildContext context, Note note) async {
    int result = await databaseHelper.deleteNote(note.id);
    if (result != 0) {
      Utils.showSnackBar(context, 'Note Deleted Successfully!');
      updateListView();
    }
  }

  void navToDetail(Note note, String rsn) async {
    bool result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return NoteDetail(note, rsn);
    }));
    if (result == true) updateListView();
  }

  void navToSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return NoteSettings();
    }));
  }
}
