import 'dart:io';

import 'package:dio/dio.dart';

import '../config/utils.dart';
import '/config/apis.dart';
import '/config/dio_util.dart';
import '/config/enums.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:url_launcher/url_launcher.dart';

import '/config/models.dart';

import 'base/list_view_model.dart';

class AppRecommendViewModel extends ListViewModel<RacommendApp> {
  final String packageName;

  AppRecommendViewModel({required this.packageName});
  
  @override
  Future<List<RacommendApp>> loadData() async{
    List<RacommendApp> list = await recommendApps();
    print(list);
    RacommendApp? myApp;
    if (Platform.isAndroid) {
      List<DownloadTask>? tasks;
      try {
        tasks = await FlutterDownloader.loadTasks();
        if (tasks != null) {
          for (var task in tasks) {
            if(task.status.index != 2 && task.status.index != 3 && task.status.index != 6) {
              FlutterDownloader.remove(taskId: task.taskId, shouldDeleteContent:true);
            }
          }
        }
      } on Exception catch (e) {
        print(e.toString());
      }
      for (RacommendApp item in list) {
          if(tasks != null) {
            for (var i = tasks.length-1; i >= 0; i--) {
              DownloadTask task = tasks[i];
              if(task.filename == getRecommendApkFileName(item.aid, item.aversion)) {
                item.task.status = task.status.index;
                item.task.taskId = task.taskId;
                item.task.progress = task.progress;
                item.task.filename = task.filename!;
                break;
              }
            }
          }
          
          String url = "${item.aid}://${item.apath}";
          if(await canLaunch(url)) {
            item.type = RecommendAppType.canOpen;
            url = "${item.aprotocal}.${item.aversion}://${item.apath}";
            if (await canLaunch(url)) {
              item.type = RecommendAppType.canOpen;
              if(item.task.status == 3) {
                FlutterDownloader.remove(taskId: item.task.taskId, shouldDeleteContent:true);
              }
            }else {
              item.type = RecommendAppType.needUpdate;
            }
          }else {
            if(item.task.status == 3 && item.task.filename == getRecommendApkFileName(item.aid, item.aversion) ) {
              item.type = RecommendAppType.needInstall;
            }else{
              item.type = RecommendAppType.needDownload;
            }
          }
        
        if((Platform.isAndroid && packageName == item.aid) 
          ||(Platform.isIOS && packageName == item.iid)) {
            myApp = item;
        }
      }
      if(myApp != null) {
        list.remove(myApp);
      }
    } else {
      for (RacommendApp item in list) {
        //IOS手机
        String url = "${item.iprotocal}://";
        if(await canLaunch(url)) {
          item.type = RecommendAppType.canOpen;
        }else {
          item.type = RecommendAppType.needDownload;
        }
        if((Platform.isAndroid && packageName == item.aid) 
          ||(Platform.isIOS && packageName == item.iid)) {
            myApp = item;
        }
      }
      if(myApp != null) {
        list.remove(myApp);
      }
    }
    
    return list;
  }

  void changeTaskStatus({required String taskId, required int progress, required int status,}) {
    for (RacommendApp item in list) {
      if(item.task.taskId == taskId) {
        item.task.taskId = taskId;
        item.task.progress = progress;
        item.task.status = status;
        break;
      }
    }
    if (status != 0) {
      notifyListeners();
    }
    
  }

  String getRecommendApkFileName(String aid, String aversion) {
    String apkName = aid.substring(
      aid.lastIndexOf('.')+1, aid.length
    );
    apkName = '$apkName$aversion.apk';
    return apkName;
  }



  Future<List<RacommendApp>> recommendApps() async {
    String? host = await Utils.spReadData("ApiHost");
    if (host == null || host == "") {
      host = Api.host;
      await Utils.spWriteData("ApiHost", Api.host);
    }
    try { 
      BaseResp baseResp = await DioUtil().request(Method.get, host + Api.recommendApps);
      return baseResp.data.map<RacommendApp>((value) {
        return RacommendApp.fromJson(value);
      }).toList();
    } on Exception catch (e) {
      if (e is DioError) {
        DioError error = e;
        bool hasNetwork = await DioUtil().checkNetwork();
        print(error.error);
        if (hasNetwork 
            && (error.type == DioErrorType.connectTimeout 
                || error.type == DioErrorType.receiveTimeout 
                || (error.type == DioErrorType.other && error.error is SocketException))) {
          var requestOptions = error.requestOptions;
          if(requestOptions.path.contains(Api.host) || requestOptions.baseUrl.contains(Api.host)) {
            List<HostGetModel> hosts = await DioUtil().getServerHostJson();
            if(hosts.length > 0) {
              var stopWatch = Stopwatch();
              int? minTime;
              String? minHost;
              for (var item in hosts) {
                stopWatch.start();
                bool result = await DioUtil().checkOurHost(item.host);
                if (result) {
                  if(minTime == null) {
                    minTime = stopWatch.elapsed.inSeconds;
                    minHost = item.host;
                  }else {
                    if (stopWatch.elapsed.inSeconds < minTime) {
                      minTime = stopWatch.elapsed.inSeconds;
                      minHost = item.host;
                    }
                  }
                }
              }
              if (minTime != null) {
                await Utils.spWriteData("ApiHost", minHost);
                BaseResp baseResp = await DioUtil().request(Method.get, minHost! + Api.recommendApps);
                return baseResp.data.map<RacommendApp>((value) {
                  return RacommendApp.fromJson(value);
                }).toList();
              }
              
            }else {
              throw NotSuccessException(404, "连接服务器失败,请联系管理员或稍后重试!");
            }
          }
        }else if (error.type == DioErrorType.response) {
          throw NotSuccessException(error.hashCode, "网络错误，请稍后重试。");
        }
      }
    }
    throw NotSuccessException(404, "未知错误");
  }
}
