import 'dart:convert';
import 'dart:io';

import 'package:app_recommend_package/config/apis.dart';
import 'package:dio/dio.dart';

import 'models.dart';
import 'utils.dart';

class BaseResp<T> {
  int code;
  String msg;
  T data;

  BaseResp(this.code, this.msg, this.data);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer('{');
    sb.write(",\"code\":$code");
    sb.write(",\"msg\":\"$msg\"");
    sb.write(",\"data\":\"$data\"");
    sb.write('}');
    return sb.toString();
  }
}

/// 请求方法.
class Method {
  static final String get = "GET";
  static final String post = "POST";
  static final String put = "PUT";
  static final String head = "HEAD";
  static final String delete = "DELETE";
  static final String patch = "PATCH";
}

/// 单例 DioUtil.
/// debug模式下可以打印请求日志. DioUtil.openDebug().
/// dio详细使用请查看dio官网(https://github.com/flutterchina/dio).
class DioUtil {
  static final DioUtil _singleton = DioUtil._init();
  static late Dio _dio;

  /// BaseResp [String status]字段 key, 默认：status.
  String _statusKey = "status";

  /// BaseResp [int code]字段 key, 默认：errorCode.
  //String _codeKey = "errorCode";
  String _codeKey = "code";

  /// BaseResp [String msg]字段 key, 默认：errorMsg.
  //String _msgKey = "errorMsg";
  String _msgKey = "msg";

  /// BaseResp [T data]字段 key, 默认：data.
  String _dataKey = "data";

  /// PEM证书内容.
  // String _pem;

  // /// PKCS12 证书路径.
  // String _pKCSPath;

  // /// PKCS12 证书密码.
  // String _pKCSPwd;

  /// 是否是debug模式.
  static bool _isDebug = false;

  static DioUtil getInstance() {
    return _singleton;
  }

  factory DioUtil() {
    return _singleton;
  }

  DioUtil._init() {
    _dio = Dio();
    // _dio.interceptors.add(QueuedInterceptorsWrapper(
    //   onError: (error, handle) async{
    //     bool hasNetwork = await checkNetwork();
    //     if (hasNetwork 
    //         && (error.type == DioErrorType.connectTimeout || error.type == DioErrorType.other && error.error is SocketException && error.message.contains('Failed host lookup'))
    //     ) {
    //       var requestOptions = error.requestOptions;
    //       if(requestOptions.path.contains(Api.host) || requestOptions.baseUrl.contains(Api.host)) {
    //         List<HostGetModel> model = await getServerHostJson();
    //         print(model);
    //       }
    //     }
    //   })
    // );
  }

  Future<bool> checkNetwork() async {
    try {
      final result = await InternetAddress.lookup('baidu.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> checkOurHost(String host) async {
    try {
      Response response = await Dio().get(host);
      if (response.data != null) {
        return true;
      }else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  /// 打开debug模式.
  static void openDebug() {
    _isDebug = true;
  }


  /// Make http request with options.
  /// [method] The request method.
  /// [path] The url path.
  /// [data] The request data
  /// [options] The request options.
  /// <BaseResp<T> 返回 status code msg data .
  Future<BaseResp<T>> request<T>(String method, String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) async {
    Response response = await _dio.request(path,
        data: data,
        queryParameters: queryParameters,
        options: _checkOptions(method, options),
        cancelToken: cancelToken,
      );
    print(response);
    int _code;
    String _msg;
    T _data;
    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      try {
        if (response.data is Map) {
          _code = (response.data[_codeKey] is String)
              ? int.tryParse(response.data[_codeKey])
              : response.data[_codeKey];
          _msg = response.data[_msgKey];
          _data = response.data[_dataKey];
        } else {
          Map<String, dynamic> _dataMap = _decodeData(response);
          _code = (_dataMap[_codeKey] is String)
              ? int.tryParse(_dataMap[_codeKey])
              : _dataMap[_codeKey];
          _msg = _dataMap[_msgKey];
          _data = _dataMap[_dataKey];
        }
        return new BaseResp(_code, _msg, _data);
      } catch (e) {
        return new Future.error(new DioError(
          response: response,
          //message: "data parsing exception...",
          error: "data parsing exception...",
          type: DioErrorType.response, 
          requestOptions: response.requestOptions,
        ));
      }
    }
    return new Future.error(new DioError(
      response: response,
      //message: "statusCode: $response.statusCode, service error",
      error: "statusCode: $response.statusCode, service error",
      type: DioErrorType.response, 
      requestOptions: response.requestOptions,
    ));
  }

  /// decode response data.
  Map<String, dynamic> _decodeData(Response response) {
    if (response == null ||
        response.data == null ||
        response.data.toString().isEmpty) {
      return new Map();
    }
    return json.decode(response.data.toString());
  }

  /// check Options.
  /// 在这里加入了新的请求配置，如果是post请求就添加"application/x-www-form-urlencoded"
  Options _checkOptions(method, options) {
    if (options == null) {
      options = new Options();
      options.sendTimeout = 1000 * 3;
      options.receiveTimeout = 1000 * 3;
      if (method == Method.post) {
        options.contentType = "application/x-www-form-urlencoded";
      }
    }

    options.method = method;
    return options;
  }

  /// get dio.
  Dio getDio() {
    return _dio;
  }

  Future<List<HostGetModel>> getServerHostJson() async {
    int res = await Utils.spReadData('blockTime');
    if ((res == null || res == 0) || DateTime.now().millisecondsSinceEpoch - res > 1000 * 60 * 36) {
      try {
        return await getServerHost(Api.backupHost1);
      } on Exception catch (_) {
        try {
          return await getServerHost(Api.backupHost2);
        } on Exception catch (_) {
          try {
            return await getServerHost(Api.backupHost3);
          } on Exception catch (_) {
            try {
              return await getServerHost(Api.backupHost4);
            } on Exception catch (_) {
              return [];
            }
          }
        }
      }
    }
    return [];
  }

  Future<List<HostGetModel>> getServerHost(host) async {
    Response response = await Dio().get(host);
      if (response.data != null) {
        await Utils.spWriteData('blockTime', DateTime.now().millisecondsSinceEpoch);
        return response.data['hosts'].map<HostGetModel>((value) {
          return HostGetModel.fromJson(value);
        }).toList();  
      }else {
        throw Exception();
      }
  }
}

