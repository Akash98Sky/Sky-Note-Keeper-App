import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:logging/logging.dart';
import 'package:note_keeper/screens/widgets/connectivity_widget.dart';
import 'package:note_keeper/utils/packageinfo_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

enum UpdateStatus {
  Checking,
  CheckFailed,
  Downloading,
  NotFound,
  Available,
  Failed,
  Finished
}

class CheckUpdateWidget extends StatefulWidget {
  CheckUpdateWidget();
  @override
  State<StatefulWidget> createState() {
    return CheckUpdateState();
  }
}

class CheckUpdateState extends State<CheckUpdateWidget> {
  static Logger _log;
  static String _url;

  static UpdateStatus updateStatus;

  final PackageInfoHelper packageHelper = PackageInfoHelper();

  CheckUpdateState() {
    if (_log == null)
      _log =
          Logger(this.toString(minLevel: DiagnosticLevel.hint).split("#")[0]);
    _log.info("class is loaded...");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: Firestore.instance
            .collection('AppDoc')
            .document('updates')
            .snapshots(),
        builder: (context, snapshot) {
          if (!ConnectivityIndicator.isOnline || snapshot.hasError) {
            if (snapshot.hasError)
              _log.severe("Failed to check update | ${snapshot.error}");
            else
              _log.warning("Failed to check update | No internet connection");
            updateStatus = UpdateStatus.CheckFailed;
          } else if (updateStatus != UpdateStatus.Available) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              updateStatus = UpdateStatus.Checking;
            } else if (snapshot.data.data['build'] >
                int.parse(packageHelper.appBuildNo)) {
              updateStatus = UpdateStatus.Available;
              _url = snapshot.data.data['url'];
            } else {
              updateStatus = UpdateStatus.NotFound;
            }
          }

          _log.info("Update status => $updateStatus");
          return ChangeNotifierProvider<_UpdateNotifier>(
            key: GlobalKey(),
            builder: (_) {
              if(updateStatus == UpdateStatus.CheckFailed || updateStatus == UpdateStatus.NotFound || snapshot.data == null)
                return _UpdateNotifier(context, _url, status: updateStatus);
              return _UpdateNotifier(context, _url, status: updateStatus, appVersion: snapshot.data.data['version'], appBuildNo: snapshot.data.data['build'], appSize: snapshot.data.data['size']);
            },
            child: _UpdateStatus(),
          );
        });
  }
}

class _UpdateNotifier with ChangeNotifier {
  static Logger _log;

  final BuildContext context;

  static String _taskID;
  static UpdateStatus _updateStatus;
  static DownloadTaskStatus _downloadStatus;
  static double _downloadProgress;
  String _downloadPath;
  String _downloadURL;
  static DownloadTask _taskInfo;

  String checkUpdateTitle;
  Widget checkUpdateWidget;
  Color iconColor;

  _UpdateNotifier(this.context, this._downloadURL, {UpdateStatus status, String appVersion, int appBuildNo, String appSize}) {
    if (_log == null) _log = Logger(this.toString().split("'")[1]);
    if (_taskID == null) _updateStatus = status ?? UpdateStatus.CheckFailed;
    switch (_updateStatus) {
      case UpdateStatus.Checking:
        _updateCheckNotifier();
        break;
      case UpdateStatus.Available:
        _updateAvailableNotifier(appBuildNo, appVersion, appSize);
        break;
      case UpdateStatus.Downloading:
        _downloaderRegisterCallback();
        _updateProgressNotifier();
        break;
      case UpdateStatus.NotFound:
        _updateNotFoundNotifier();
        break;
      case UpdateStatus.CheckFailed:
      case UpdateStatus.Failed:
        _updateFailedNotifier();
        break;
      case UpdateStatus.Finished:
        _updateFinishedNotifier();
        break;
      default:
    }
  }

  @override
  void notifyListeners() {
    _log.finest("Update Status => $_updateStatus");
    switch (_updateStatus) {
      case UpdateStatus.Downloading:
        _updateProgressNotifier();
        break;
      case UpdateStatus.CheckFailed:
      case UpdateStatus.Failed:
        _updateFailedNotifier();
        break;
      case UpdateStatus.Finished:
        _updateFinishedNotifier();
        break;
      default:
    }
    super.notifyListeners();
  }

  void _downloaderRegisterCallback() {
    FlutterDownloader.registerCallback((id, status, progress) async {
      if (_taskID == id) {
        _downloadProgress = progress / 100;
        _downloadStatus = status;
        if (status == DownloadTaskStatus.complete)
          _updateStatus = UpdateStatus.Finished;
        else if (status == DownloadTaskStatus.failed ||
            status == DownloadTaskStatus.undefined)
          _updateStatus = UpdateStatus.Failed;
        notifyListeners();

        _log.finer("Download Progress => $progress");
        if (_taskInfo == null || _taskInfo.filename == null)
          _taskInfo = (await FlutterDownloader.loadTasksWithRawQuery(
              query: "SELECT * FROM task WHERE task_id='$_taskID';"))[0];
      }
    });
  }

  void _updateAvailableNotifier(int build, String version, String size) {
    checkUpdateTitle = "New App Update Found !";
    checkUpdateWidget = WillPopScope(
      onWillPop: () async {
        _clearDownloads();
        return true;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("Sky Note Keeper", style: Theme.of(context).textTheme.display1.apply(fontSizeFactor: 0.7),),
          Text("App Version: $version", style: Theme.of(context).textTheme.body2,),
          Text("App Build: $build", style: Theme.of(context).textTheme.body2,),
          Text("App Size: $size", style: Theme.of(context).textTheme.body2,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              RaisedButton(
                child: Icon(
                  Icons.file_download,
                  color: iconColor,
                ),
                onPressed: () async {
                  _downloadPath = (await getExternalStorageDirectory()).path;
                  print(_downloadPath);
                  if (_taskID == null &&
                      _downloadURL != null &&
                      _downloadPath != null) {
                    _taskID = await FlutterDownloader.enqueue(
                      url: _downloadURL,
                      savedDir: _downloadPath,
                      showNotification:
                          true, // show download progress in status bar (for Android)
                      openFileFromNotification:
                          false, // click on notification to open downloaded file (for Android)
                    );
                    _downloaderRegisterCallback();
                  } else {
                    _log.severe(
                        "Failed to download | taskID:$_taskID downloadURL:$_downloadURL downloadPath:$_downloadPath");
                    return;
                  }
                  _updateProgressNotifier();
                  notifyListeners();
                },
              ),
              RaisedButton(
                child: Icon(
                  Icons.cancel,
                  color: iconColor,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearDownloads();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateProgressNotifier() async {
    if (_updateStatus != UpdateStatus.Downloading || checkUpdateTitle == null) {
      _updateStatus = UpdateStatus.Downloading;
      checkUpdateTitle = "Downloading";
    }
    checkUpdateWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        LinearProgressIndicator(
          semanticsLabel: checkUpdateTitle,
          semanticsValue: "100",
          value: _downloadProgress,
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              RaisedButton(
                child: Icon(
                  _downloadStatus == DownloadTaskStatus.paused
                      ? Icons.play_circle_filled
                      : Icons.pause_circle_filled,
                  color: iconColor,
                ),
                onPressed: () async {
                  if (_downloadStatus == DownloadTaskStatus.running ||
                      _downloadStatus == DownloadTaskStatus.enqueued)
                    await FlutterDownloader.pause(taskId: _taskID);
                  else if ((_taskID =
                          await FlutterDownloader.resume(taskId: _taskID)) ==
                      null) _updateStatus = UpdateStatus.Failed;
                },
              ),
              RaisedButton(
                child: Icon(
                  Icons.cancel,
                  color: iconColor,
                ),
                onPressed: () {
                  FlutterDownloader.cancel(taskId: _taskID);
                  Navigator.of(context).pop();
                  _clearDownloads();
                },
              ),
            ]),
      ],
    );
  }

  void _updateNotFoundNotifier() {
    checkUpdateTitle = "Your app is up-to date :)";
    checkUpdateWidget = Container(
        child: LinearProgressIndicator(
      semanticsLabel: checkUpdateTitle,
      semanticsValue: "100",
      value: 1,
    ));
  }

  void _updateFailedNotifier() {
    if (_updateStatus == UpdateStatus.Failed) _clearDownloads();

    checkUpdateTitle =
        "Failed to ${_updateStatus == UpdateStatus.CheckFailed ? "check for" : "download"} update !";
    checkUpdateWidget = Container(
        child: LinearProgressIndicator(
      semanticsLabel: checkUpdateTitle,
      semanticsValue: "100",
      value: _downloadProgress ?? 1,
    ));
  }

  void _updateFinishedNotifier() {
    checkUpdateTitle = "Downloading Finished";
    checkUpdateWidget = WillPopScope(
      onWillPop: () async {
        _clearDownloads();
        return true;
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        LinearProgressIndicator(
          semanticsLabel: checkUpdateTitle,
          semanticsValue: "100",
          value: 1,
        ),
        RaisedButton(
          child: Text("Open"),
          onPressed: () {
            FlutterDownloader.open(taskId: _taskID);
          },
        )
      ]),
    );
    _log.info(
        "File Downloaded to => ${_taskInfo.savedDir}/${_taskInfo.filename}");
  }

  void _updateCheckNotifier() {
    iconColor = Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).primaryColor
        : null;

    checkUpdateTitle = "Checking for updates...";
    checkUpdateWidget = Container(
      child: LinearProgressIndicator(
        semanticsLabel: checkUpdateTitle,
        semanticsValue: "100",
      ),
    );
  }

  void _clearDownloads() async {
    if (_taskID != null) {
      // FlutterDownloader.remove(taskId: _taskID);
      FlutterDownloader.registerCallback(null);
    }
    _taskID = null;
    _updateStatus = null;
    CheckUpdateState.updateStatus = null;
    _log.info("Cleared download list...");
  }
}

class _UpdateStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final updateNotifier = Provider.of<_UpdateNotifier>(context);

    return Container(
      child: AlertDialog(
        title: Text(updateNotifier.checkUpdateTitle),
        content: updateNotifier.checkUpdateWidget,
      ),
    );
  }
}
