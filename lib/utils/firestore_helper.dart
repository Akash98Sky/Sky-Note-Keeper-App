import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/screens/note_list.dart';

class FirestoreHelper {
  static Logger log;

  String _myDoc;

  FirestoreHelper(this._myDoc) {
    log = Logger(this.toString());
  }

  bool uploadNote(int id, Map<String, dynamic> map) {
    if (ConnectivityIndicator.isOnline) {
      Firestore.instance
          .collection(_myDoc)
          .document(id.toString())
          .setData(map);
      log.info("Note uploaded to firestore : id => ${id.toString()}");
      return true;
    }
    return false;
  }

  bool deleteNote(int id) {
    if (ConnectivityIndicator.isOnline) {
      Firestore.instance.collection(_myDoc).document(id.toString()).delete();
      log.info("Note deleted from firestore : id => ${id.toString()}");
      return true;
    }
    return false;
  }
}
