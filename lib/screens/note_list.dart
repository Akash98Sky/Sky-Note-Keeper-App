import 'package:flutter/material.dart';
import 'package:note_keeper/models/note.dart';
import 'package:note_keeper/screens/note_detail.dart';
import 'package:note_keeper/utils/database_helper.dart';
import 'package:sqflite/sqlite_api.dart';

class NoteList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NoteListState();
  }
}

class NoteListState extends State<NoteList> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Note> noteList;
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    if(noteList == null) {
      noteList = List<Note>();
      updateListView();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Notes')),
      body: getNodeListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB pressed');
          navToDetail(Note('', '', 1),'Add Note');
          updateListView();
        },
        tooltip: 'Add Note',
        child: Icon(Icons.add_box),
      ),
    );
  }

  ListView getNodeListView() {
    TextStyle titleStyle = Theme.of(context).textTheme.subhead;

    return ListView.builder(
      itemCount: _count,
      itemBuilder: (BuildContext context, int pos) {
        return Card(
          color: Colors.white,
          elevation: 2.0,
          child: ListTile(
            leading: CircleAvatar(
              child: getPriorityIcon(this.noteList[pos].priority),
              backgroundColor: getPriorityColor(this.noteList[pos].priority),
            ),
            title: Text(this.noteList[pos].title, style: titleStyle),
            subtitle: Text(this.noteList[pos].date),
            trailing: GestureDetector(
              child: Icon(Icons.delete, color: Colors.grey,),
              onTap: () {
                _delete(context, noteList[pos]);
              },
            ),
            onTap: () {
              debugPrint('ListTile Tapped');
              navToDetail(this.noteList[pos] ,'Edit Node');
              updateListView();
            },
          ),
        );
      },
    );
  }

  Color getPriorityColor(int priority) {
    switch(priority) {
      case 0:
        return Colors.red;
        break;
      case 1:
        return Colors.yellow;
        break;
      default:
        return Colors.blue;
    }
  }

  Icon getPriorityIcon(int priority) {
    switch(priority) {
      case 0:
        return Icon(Icons.play_arrow);
        break;
      case 1:
        return Icon(Icons.keyboard_arrow_right);
        break;
      default:
        return Icon(Icons.keyboard_arrow_right);
    }
  }

  void _delete(BuildContext context, Note note) async {
    int result = await databaseHelper.deleteNote(note.id);
    if(result != 0)
    {
      _showSnackBar(context, 'Note Deleted Successfully!');
      updateListView();
    }
  }

  void _showSnackBar(BuildContext context, String message) {

		final snackBar = SnackBar(content: Text(message), duration: Duration(seconds: 2),);
		Scaffold.of(context).showSnackBar(snackBar);
	}

  void navToDetail(Note note,String rsn) async {
    bool result = await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return NoteDetail(note, rsn);
    }));
    if(result == true)
      updateListView();
  }

  void updateListView() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<Note>> noteListFuture = databaseHelper.getNoteList();
      noteListFuture.then((noteList) {
        setState(() {
          this.noteList = noteList;
          this._count = noteList.length;
          debugPrint('Updated List View');
        });
      });
    });
  }

}
