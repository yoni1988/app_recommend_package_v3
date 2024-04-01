import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  //保存SharedPreferences
  static Future<void> spWriteData(String key, dynamic value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (value is String) {
      bool _res = await sp.setString(key, value);
      print('$_res save String to sp complete $key type=${value.runtimeType}');
    } else if (value is int) {
      sp.setInt(key, value);
    } else if (value is bool) {
      sp.setBool(key, value);
    } else if (value is double) {
      sp.setDouble(key, value);
    } else if (value is List<String>) {
      sp.setStringList(key, value);
    } else if (value is List) {
      List<String> _tmp = [];
      value.forEach((v) {
        _tmp.add(v.toString()); //
      });
      sp.setStringList(key, _tmp);
      print('save List<String> to sp complete ');
    }
    //print('save List<String> to sp complete $key type=${value.runtimeType}');
  }

  //读取SharedPreferences
  static dynamic spReadData(String key) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    print('read from sp complete $key ');
    return sp.get(key);
  }
}