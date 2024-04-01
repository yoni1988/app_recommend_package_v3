class Api {
  static String host = '';
  static String recommendApps = '/opendata/applications/find';

  static String appsRecommendShareUrl = '/opendata/applications/get/shareUrl';

  static String backupHost1 = "";
  static String backupHost2 = "";
  static String backupHost3 = "";
  static String backupHost4 = "";
}


class UnAuthorizedException implements Exception {
  const UnAuthorizedException();

  @override
  String toString() => 'UnAuthorizedException';
}

class NotSuccessException implements Exception {
  final int code;
  final String message;

  NotSuccessException(this.code, this.message);

  // NotSuccessException.fromRespData(String msg) {
  //   message = msg;
  // }

  @override
  String toString() {
    return '$code, $message';
  }
}
