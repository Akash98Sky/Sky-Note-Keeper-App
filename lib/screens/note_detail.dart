import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/models/note.dart';
import 'package:note_keeper/utils/database_helper.dart';
import 'package:note_keeper/utils/utils.dart';

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
  static const _priorities = ['High', 'Normal', 'Low'];
  static const _priorityColor = [Colors.red, Colors.yellow, Colors.green];

  static Logger _log;

  var _formKey = GlobalKey<FormState>();

  int _selectedPriority = 1;
  String appBarTitle;
  Note note;
  DatabaseHelper helper = DatabaseHelper();

  TextEditingController titleControler = TextEditingController();
  TextEditingController descriptionControler = TextEditingController();

  NoteDetailState(this.note, this.appBarTitle) {
    if (_log == null)
      _log = Logger(this.toString(minLevel: DiagnosticLevel.hint).split("#")[0]);
    _log.fine("class is loaded...");
  }

  @override
  void initState() {
    super.initState();
    titleControler.text = note.title;
    descriptionControler.text = note.description;
    _selectedPriority = note.priority;
    _log.finer("init complete...");
  }

  @override
  Widget build(BuildContext context) {
    _log.finest("Widget build started...");
    TextStyle textStyle = Theme.of(context).textTheme.title;

    return WillPopScope(
      onWillPop: () async {
        return !moveToLastScreen();
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
                    title: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Priority :",
                        style: textStyle,
                      ),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    Expanded(
                      child: DropdownButton(
                        items: _priorities.map((String dropDownStringItem) {
                          return DropdownMenuItem(
                            value: dropDownStringItem,
                            child: Text(dropDownStringItem,
                                style: textStyle.apply(
                                    color: _priorityColor[_priorities
                                        .indexOf(dropDownStringItem)])),
                          );
                        }).toList(),
                        isExpanded: true,
                        value: _priorities[_selectedPriority],
                        onChanged: (String value) {
                          setState(() {
                            note.priority = _priorities.indexOf(value);
                            _selectedPriority = note.priority;
                          });
                        },
                      ),
                    )
                  ],
                )),
                Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 15),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    controller: titleControler,
                    style: textStyle,
                    onFieldSubmitted: (value) {
                      _log.info("Something changed in Title Text Field");
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
                      _log.info("Something changed in Description Text Field");
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
                              _log.info("Saved button clicked");
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
                              _log.info("Delete button clicked");
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
    return Navigator.of(context).pop(true);
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
      Utils.showAlertDialog(context, 'Status', 'Note Saved Successfully');
    else
      Utils.showAlertDialog(context, 'Status', 'Problem in Saving Note');
  }

  void _delete() async {
    moveToLastScreen();

    if (note.id == null) {
      Utils.showAlertDialog(context, 'Status', 'No Note was deleted');
      return;
    }

    int result = await helper.deleteNote(note.id);

    if (result != 0) {
      Utils.showAlertDialog(context, 'Status', 'Note Deleted Successfully');
    } else {
      Utils.showAlertDialog(
          context, 'Status', 'Error Occured while Deleting Note');
    }
  }
}
