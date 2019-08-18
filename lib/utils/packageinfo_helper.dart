import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';

class PackageInfoHelper {
  static PackageInfoHelper _packageInfoHelper;
  static Logger _log;

  String _appName;
  String _appVersion;
  String _appBuildNo;

  PackageInfoHelper._createInstance() {
    if (_log == null) _log = Logger(this.toString().split("'")[1]);
    _loadAppDetails();
  }

  factory PackageInfoHelper() {
    if (_packageInfoHelper == null)
      _packageInfoHelper = PackageInfoHelper._createInstance();
    return _packageInfoHelper;
  }

  String get appName => _appName;
  String get appVersion => _appVersion;
  String get appBuildNo => _appBuildNo;

  Future<void> _loadAppDetails() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    _appName = packageInfo.appName;
    _appVersion = packageInfo.version;
    _appBuildNo = packageInfo.buildNumber;

    _log.info("$_appName | Version: $_appVersion | Build No: $_appBuildNo");
  }
}
