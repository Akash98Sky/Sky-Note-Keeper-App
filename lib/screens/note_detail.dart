import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_keeper/models/note.dart';
import 'package:note_keeper/utils/database_helper.dart';

class NoteDetail extends StatefulWidget {
  final String appBarTitle;
  final Note note;

  NoteDetail(this.note, this.appBarTitle);

  @override
  State<StatefulWidget> createState() {
    return NoteDetailState(note, appBarTitle);
  }
}

class NoteDetailState extends State<NoteDetail> {
  var _formKey = GlobalKey<FormState>();

  var _priorities = ['High', 'Low'];
  int _selectedPriority = 1;
  String appBarTitle;
  Note note;
  DatabaseHelper helper = DatabaseHelper();

  TextEditingController titleControler = TextEditingController();
  TextEditingController descriptionControler = TextEditingController();

  NoteDetailState(this.note, this.appBarTitle);

  @override
  void initState() {
    super.initState();
    titleControler.text = note.title;
    descriptionControler.text = note.description;
    _selectedPriority = note.priority;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.title;

    return WillPopScope(
      onWillPop: () {
        moveToLastScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$appBarTitle'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              moveToLastScreen();
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(top: 15, left: 10, right: 10),
            child: ListView(
              children: <Widget>[
                ListTile(
                  title: DropdownButton(
                    items: _priorities.map((String dropDownStringItem) {
                      return DropdownMenuItem(
                        value: dropDownStringItem,
                        child: Text(dropDownStringItem),
                      );
                    }).toList(),
                    style: textStyle,
                    value: _priorities[_selectedPriority],
                    onChanged: (String value) {
                      setState(() {
                        note.priority = _priorities.indexOf(value);
                        _selectedPriority = note.priority;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    controller: titleControler,
                    style: textStyle,
                    onFieldSubmitted: (value) {
                      debugPrint('Something changes in Title Text Field');
                      updateTitle();
                    },
                    validator: (value) {
                      if (value.isEmpty)
                        return "Title can't be empty";
                      else if (value.length > 255)
                        return "Title length must be less than 256 characters";
                      else
                        return null;
                    },
                    decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: textStyle,
                        hintText: 'Enter the title of your note',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        )),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    controller: descriptionControler,
                    style: textStyle,
                    onFieldSubmitted: (value) {
                      debugPrint('Something changes in Description Text Field');
                      updateDescription();
                    },
                    validator: (value) {
                      if (value.length > 255)
                        return "Description length must be less than 256 characters";
                      else
                        return null;
                    },
                    decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: textStyle,
                        hintText: 'Enter the note description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        )),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 15),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                            child: RaisedButton(
                          color: Theme.of(context).primaryColorDark,
                          textColor: Theme.of(context).primaryColorLight,
                          child: Text('Save', textScaleFactor: 1.5),
                          onPressed: () {
                            setState(() {
                              debugPrint('Saved button clicked');
                              if (_formKey.currentState.validate()) _save();
                            });
                          },
                        )),
                        Container(
                          width: 5.0,
                        ),
                        Expanded(
                            child: RaisedButton(
                          color: Theme.of(context).primaryColorDark,
                          textColor: Theme.of(context).primaryColorLight,
                          child: Text('Delete', textScaleFactor: 1.5),
                          onPressed: () {
                            setState(() {
                              debugPrint('Delete button clicked');
                              _delete();
                            });
                          },
                        ))
                      ],
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool moveToLastScreen() {
    return Navigator.pop(context, true);
  }

  void updateTitle() {
    note.title = titleControler.text;
  }

  void updateDescription() {
    note.description = descriptionControler.text;
  }

  void _save() async {
    moveToLastScreen();

    updateTitle();
    updateDescription();

    note.date = DateFormat.yMMMd().format(DateTime.now());
    int result;
    if (note.id != null)
      result = await helper.updateNote(note);
    else
      result = await helper.insertNote(note);

    if (result != 0)
      _showAlertDialog('Status', 'Note Saved Successfully');
    else
      _showAlertDialog('Status', 'Problem in Saving Note');
  }

  void _delete() async {
    moveToLastScreen();

    if (note.id == null) {
      _showAlertDialog('Status', 'No Note was deleted');
      return;
    }

    int result = await helper.deleteNote(note.id);
    if (result != 0) {
      _showAlertDialog('Status', 'Note Deleted Successfully');
    } else {
      _showAlertDialog('Status', 'Error Occured while Deleting Note');
    }
  }

  void _showAlertDialog(String title, String message) {
    AlertDialog alertDialog = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(context: context, builder: (_) => alertDialog);
  }
}