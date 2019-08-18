import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/screens/widgets/connectivity_widget.dart';

class FirestoreHelper {
  static FirestoreHelper _firestoreHelper;
  static Logger _log;
  
  String _myDoc;
  List<dynamic> list;

  FirestoreHelper._createInstance(this._myDoc) {
    if (_log == null) _log = Logger(this.toString().split("'")[1]);
  }

  factory FirestoreHelper(String collection) {
    if (_firestoreHelper == null)
      _firestoreHelper = FirestoreHelper._createInstance(collection);
    print(collection);
    return _firestoreHelper;
  }

  bool uploadNote(String id, Map<String, dynamic> map) {
    if (ConnectivityIndicator.isOnline) {
      Firestore.instance.collection(_myDoc).document(id).setData(map);
      _log.info("Note uploaded to firestore : id => $id");
      return true;
    }
    return false;
  }

  bool deleteNote(String id) {
    if (ConnectivityIndicator.isOnline) {
      Firestore.instance.collection(_myDoc).document(id).delete();
      _log.info("Note deleted from firestore : id => $id");
      return true;
    }
    return false;
  }

  List<dynamic> getLatestAppDetails() {
    print(_myDoc);
    list = List<dynamic>();
    if (ConnectivityIndicator.isOnline) {
      Firestore.instance
          .collection("AppDoc")
          .document("updates")
          .get()
          .then((snap) {
        list.addAll(
            [snap.data['build'], snap.data['version'], snap.data['url']]);
        return;
      });
      _log.info("Latest App Details : $list");
    }
    return list;
  }
}
