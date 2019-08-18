import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/screens/widgets/connectivity_widget.dart';

class FirestoreHelper {
  static Logger log;

  String _myDoc;

  FirestoreHelper(this._myDoc) {
    log = Logger(this.toString().split("'")[1]);
  }

  bool uploadNote(String id, Map<String, dynamic> map) {
    if (ConnectivityIndicator.isOnline) {
      Firestore.instance
          .collection(_myDoc)
          .document(id)
          .setData(map);
      log.info("Note uploaded to firestore : id => $id");
      return true;
    }
    return false;
  }

  bool deleteNote(String id) {
    if (ConnectivityIndicator.isOnline) {
      Firestore.instance.collection(_myDoc).document(id).delete();
      log.info("Note deleted from firestore : id => $id");
      return true;
    }
    return false;
  }
}
