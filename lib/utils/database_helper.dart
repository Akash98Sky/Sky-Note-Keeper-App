import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:note_keeper/utils/firestore_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:note_keeper/models/note.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper;
  static Database _database;

  static final String noteTable = 'note_table';
  static final String colId = 'id';
  static final String colTitle = 'title';
  static final String colDescription = 'description';
  static final String colPriority = 'priority';
  static final String colDate = 'date';
  static final FirestoreHelper firestoreHelper = FirestoreHelper('notes');

  List<int> _pendingDeletes, _pendingChanges;

  DatabaseHelper._createInstance() {
    _pendingChanges = List<int>();
    _pendingDeletes = List<int>();
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

    var result = await db.insert(noteTable, map);
    var id = await db.query(noteTable, columns: [
      'max($colId)'
    ]); // As 'id' column is autoincrement so max('id') will give the id of last inserted values

    if (!firestoreHelper.uploadNote(id[0]['max(id)'], map))
      _pendingChanges.add(id[0]['max(id)']);
    return result;
  }

  Future<int> updateNote(Note note) async {
    Database db = await this.database;
    Map<String, dynamic> map = note.toMap();

    var result = await db
        .update(noteTable, map, where: '$colId = ?', whereArgs: [note.id]);

    if (!firestoreHelper.uploadNote(note.id, map)) _pendingChanges.add(note.id);
    return result;
  }

  Future<int> deleteNote(int id) async {
    Database db = await this.database;
    int result =
        await db.rawDelete('delete from $noteTable where $colId = $id');

    if (!firestoreHelper.deleteNote(id)) {
      if (_pendingChanges.remove(id)){}
      else
        _pendingDeletes.add(id);
    }
    return result;
  }

  Future<bool> syncNotes() async {
    Database db = await this.database;

    if (_pendingChanges.isNotEmpty)
      while (_pendingChanges.isNotEmpty) {
        int id = _pendingChanges[0];
        Map<String, dynamic> map =
            (await db.query(noteTable, where: '$colId = $id'))[0];
        if (firestoreHelper.uploadNote(id, map))
          _pendingChanges.remove(id);
        else
          break;
      }
    if (_pendingDeletes.isNotEmpty)
      while (_pendingDeletes.isNotEmpty) {
        int id = _pendingDeletes[0];
        if (firestoreHelper.deleteNote(id))
          _pendingDeletes.remove(id);
        else
          break;
      }
    if (_pendingChanges.isEmpty && _pendingDeletes.isEmpty) return true;
    return false;
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
}
