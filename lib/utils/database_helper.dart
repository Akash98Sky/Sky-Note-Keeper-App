import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:note_keeper/utils/firestore_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:note_keeper/models/note.dart';

class DatabaseHelper {
  static const String noteTable = 'note_table';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colPriority = 'priority';
  static const String colDate = 'date';
  static const String _sharedPrefPendingChanges = 'firestorePendingChanges';
  static const String _sharedPrefPendingDeletes = 'firestorePendingDeletes';

  static DatabaseHelper _databaseHelper;
  static Database _database;
  static Logger log;

  static final FirestoreHelper firestoreHelper = FirestoreHelper('notes');

  List<String> _pendingDeletes, _pendingChanges;

  DatabaseHelper._createInstance() {
    _loadPendingNotes();
    log = Logger(this.toString().split("'")[1]);
  }

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper._createInstance();
    }
    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'notes.db';

    var noteDatabase =
        await openDatabase(path, version: 1, onCreate: _createDb);
    return noteDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'create table $noteTable($colId integer primary key autoincrement, $colTitle text, '
        '$colDescription text, $colPriority integer, $colDate text)');
  }

  Future<List<Map<String, dynamic>>> getNoteMapList() async {
    Database db = await this.database;

    var result = await db.query(noteTable, orderBy: '$colPriority ASC');

    return result;
  }

  Future<int> insertNote(Note note) async {
    Database db = await this.database;
    Map<String, dynamic> map = note.toMap();

    int result = await db.insert(noteTable, map);
    String id = (await db.query(noteTable, columns: ['max($colId)']))[0]
            ['max(id)']
        .toString(); // As 'id' column is autoincrement so max('id') will give the id of last inserted values

    if (!firestoreHelper.uploadNote(id, map)) {
      _pendingChanges.add(id);
      _savePendingChanges();
    }
    return result;
  }

  Future<int> updateNote(Note note) async {
    Database db = await this.database;
    Map<String, dynamic> map = note.toMap();

    int result = await db
        .update(noteTable, map, where: '$colId = ?', whereArgs: [note.id]);

    if (!firestoreHelper.uploadNote(note.id.toString(), map) && !_pendingChanges.contains(note.id.toString())) {
      _pendingChanges.add(note.id.toString());
      _savePendingChanges();
    }
    return result;
  }

  Future<int> deleteNote(int id) async {
    Database db = await this.database;
    int result =
        await db.rawDelete('delete from $noteTable where $colId = $id');

    if (!firestoreHelper.deleteNote(id.toString())) {
      if (_pendingChanges.remove(id.toString())) {
        _savePendingChanges();
      } else {
        _pendingDeletes.add(id.toString());
        _savePendingDeletes();
      }
    }
    return result;
  }

  Future<bool> syncNotes() async {
    Database db = await this.database;

    if (_pendingDeletes.isNotEmpty) {
      while (_pendingDeletes.isNotEmpty) {
        String id = _pendingDeletes[0];
        if (firestoreHelper.deleteNote(id))
          _pendingDeletes.remove(id);
        else
          break;
      }
      _savePendingDeletes();
    }
    if (_pendingChanges.isNotEmpty) {
      while (_pendingChanges.isNotEmpty) {
        String id = _pendingChanges[0];
        Map<String, dynamic> map =
            (await db.query(noteTable, where: '$colId = ${int.parse(id)}'))[0];
        if (firestoreHelper.uploadNote(id, map))
          _pendingChanges.remove(id);
        else
          break;
      }
      _savePendingChanges();
    }

    if (_pendingChanges.isEmpty && _pendingDeletes.isEmpty) return true;
    return false;
  }

  Future<void> _savePendingChanges() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await prefs.setStringList(_sharedPrefPendingChanges, _pendingChanges))
      log.severe("Failed to save pending changes.");
    else
      log.info("Saved : Pending Changes => ${_pendingChanges.toString()}");
  }

  Future<void> _savePendingDeletes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!await prefs.setStringList(_sharedPrefPendingDeletes, _pendingDeletes))
      log.severe("Failed to save pending deletes.");
    else
      log.info("Saved : Pending Deletes => ${_pendingDeletes.toString()}");
  }

  Future<void> _loadPendingNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      _pendingChanges =
          prefs.getStringList(_sharedPrefPendingChanges) ?? List<String>();
      log.info("Loaded : Pending Changes => ${_pendingChanges.toString()}");
    } catch (E) {
      log.severe("$E | Failed to load pending changes.");
    }

    try {
      _pendingDeletes =
          prefs.getStringList(_sharedPrefPendingDeletes) ?? List<String>();
      log.info("Loaded : Pending Deletes => ${_pendingDeletes.toString()}");
    } catch (E) {
      log.severe("$E | Failed to load pending deteles.");
    }
  }

  Future<int> getCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery('select count(*) from $noteTable');
    int result = Sqflite.firstIntValue(x);
    return result;
  }

  Future<List<Note>> getNoteList() async {
    var noteMapList = await getNoteMapList();
    int count = noteMapList.length;

    List<Note> noteList = List<Note>();

    for (int i = 0; i < count; i++) {
      noteList.add(Note.fromMapObject(noteMapList[i]));
    }

    return noteList;
  }

  void dispose() { 
    _pendingChanges.clear();
    _pendingDeletes.clear();
    _database.close();
    log.clearListeners();
  }
}
