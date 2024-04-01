library app_recommend_package;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/config/enums.dart';
import '/config/models.dart';
import '/view_model/app_recommend_view_model.dart';
import '/view_model/base/view_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'config/apis.dart';


/// 1.1.0加入长按弹出版本号功能
/// 1.2.0加入长按弹出下载安装功能
/// 1.3.0加入域名请求失败后切换备用域名
final String version = "1.3.0";

class AppRecommend extends StatefulWidget {
  final String packageName;
  final String title;
  final bool isNightMode;
  final VoidCallback? onBack;
  final bool showAppBar;
  final Color? appBarBgColor;
  final Color? appBarfgColor;
  final bool isGoogle;
  final String defaultHost;
  final String backupHost1;
  final String backupHost2;
  final String backupHost3;
  final String backupHost4;

  const AppRecommend(
      {Key? key,
      required this.packageName,
      this.isNightMode = false,
      this.onBack,
      this.title = "推荐应用",
      this.showAppBar = true,
      this.appBarBgColor,
      this.appBarfgColor,
      this.isGoogle = false,
      required this.defaultHost,
      required this.backupHost1,
      required this.backupHost2,
      required this.backupHost3,
      required this.backupHost4,

      })
      : super(key: key);

  static Future<Null> preLoad() async {
    try {
      await FlutterDownloader.initialize(ignoreSsl: true);
    } catch (_) {
      try {
        await FlutterDownloader.initialize(ignoreSsl: true);
      } catch (_) {}
    }
  }

  @override
  _AppRecommendState createState() => _AppRecommendState();
}

class _AppRecommendState extends State<AppRecommend>
    with WidgetsBindingObserver {
  //android need
  ReceivePort _port = ReceivePort();
  late AppRecommendViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    Api.host = widget.defaultHost;
    Api.backupHost1 = widget.backupHost1;
    Api.backupHost2 = widget.backupHost2;
    Api.backupHost3 = widget.backupHost3;
    Api.backupHost4 = widget.backupHost4;
    
    _viewModel = AppRecommendViewModel(packageName: widget.packageName);
    //android need
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    debugPrint("AppLifecycleState-->" + state.toString());
    if (state == AppLifecycleState.resumed) {
      _viewModel.initData();
    }
  }

  @override
  void dispose() {
    //android need
    _unbindBackgroundIsolate();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return _viewModel..initData();
      },
      child: Scaffold(
        backgroundColor:
            widget.isNightMode ? Color(0xFF111111) : Color(0xFFF3F3F3),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(44.0),
          child: widget.showAppBar
              ? AppBar(
                  backgroundColor:
                      widget.isNightMode ? Color(0xFF1F1F1F) : Colors.white,
                  elevation: 0.5,
                  title: Text(
                    widget.title,
                    style: TextStyle(
                        color: widget.isNightMode
                            ? Color(0xFFA4A4A4)
                            : Color(0xFF333333),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                  leading: InkWell(
                    onTap: () {
                      // widget.onBack();
                      Navigator.pop(context);
                    },
                    child: Icon(CupertinoIcons.back,
                        color: widget.isNightMode
                            ? Color(0xFF999999)
                            : Color(0xFF666666)),
                  ))
              : PreferredSize(
                  preferredSize: Size.fromHeight(0.0),
                  child: SizedBox.shrink()),
        ),
        body: Consumer<AppRecommendViewModel>(builder: (_, vModel, __) {
          if (vModel.viewState == ViewState.busy) {
            return Center(child: CupertinoActivityIndicator());
          } else if (vModel.viewState == ViewState.error) {
            return Center(
                child: Text(
              vModel.viewStateError?.message??"",
              style: TextStyle(
                color:
                    widget.isNightMode ? Color(0xFFA4A4A4) : Color(0xFF333333),
              ),
            ));
          }
          return EasyRefresh(
            header: MaterialHeader(),
            onRefresh: () async {
              await vModel.initData();
            },
            child: ListView.builder(
                itemCount: vModel.list.length,
                itemBuilder: (_, index) {
                  RacommendApp app = vModel.list[index];
                  // operateViewModel.task = app.task;
                  if (index == vModel.list.length - 1) {
                    return Column(
                      children: [
                        RecommendAppWidget(
                          app: app,
                          isNightMode: widget.isNightMode,
                          isGoogle: widget.isGoogle,
                        ),
                        InkWell(
                          onTap: () {
                            myToast("当前插件版本号：$version");
                          },
                          child: Container(
                            margin: EdgeInsets.only(top: 15, bottom: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 23.5,
                                  height: 1,
                                  color: widget.isNightMode
                                      ? Color(0xDDDDDDDD)
                                      : Color(0xFFDDDDDD),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6.5),
                                  child: Text(
                                    '•',
                                    style: TextStyle(color: Color(0xFFDDDDDD)),
                                  ),
                                ),
                                Container(
                                  width: 23.5,
                                  height: 1,
                                  color: widget.isNightMode
                                      ? Color(0xDDDDDDDD)
                                      : Color(0xFFDDDDDD),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return RecommendAppWidget(
                        app: app,
                        isNightMode: widget.isNightMode,
                        isGoogle: widget.isGoogle);
                  }
                }),
          );
        }),
      ),
    );
  }

  //android need
  static void downloadCallback(
      String id, int status, int progress) {
    print(
        'Background IsoCallback: task ($id) is in status ($status) and process ($progress)');
    final SendPort? sendPort = IsolateNameServer.lookupPortByName(
        'recommend_apps_downloader_send_port');
    if (sendPort != null) {
      sendPort.send([id, status, progress]);
    }
  }

  Future<void> _bindBackgroundIsolate() async {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'recommend_apps_downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }

    _port.listen((dynamic data) async {
      print('UI IsoCallback: $data');
      // _taskId = data[0];
      // DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1]);
      // DownloadTaskStatus status = data[1];

      _viewModel.changeTaskStatus(
          taskId: data[0], status: data[1], progress: data[2]);
      if (data[1] == 3) {
        FlutterDownloader.open(taskId: data[0]);
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping(
        'recommend_apps_downloader_send_port');
  }
}

class RecommendAppWidget extends StatefulWidget {
  final bool isGoogle;
  const RecommendAppWidget({
    Key? key,
    required this.app,
    this.isNightMode = false,
    this.isGoogle = false, //@required this.operateViewModel,
  }) : super(key: key);

  final RacommendApp app;
  final bool isNightMode;
  // final RecommendAppOperateViewModel operateViewModel;
  // final

  @override
  _RecommendAppWidgetState createState() => _RecommendAppWidgetState();
}

class _RecommendAppWidgetState extends State<RecommendAppWidget> {
  RecommendAppType? _buttonType;

  Color doneBtnBg = Color(0xFFF87E71);
  Color heavyBlackText = Color(0xFF333333);
  Color grayBg = Color(0xFFF3F3F3);
  Color redButton = Color(0xFFFF0000);
  Color lightBlackText = Color(0xFF999999);
  Color appOpenBg = Color(0xFFFCF1F0);
  late Color border;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _buttonType = widget.app.type;
    border = widget.isNightMode ? Color(0xFF131313) : Color(0xFFDDDDDD);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: Platform.isAndroid
          ? () => widget.isGoogle
              ? showBrowserDownloadDialog(context, widget.app.downurl)
              : showDownloadDialog(context)
          : null,
      child: Container(
        color: widget.isNightMode ? Color(0xFF262626) : Colors.white,
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                // app icon
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.5),
                      border: Border.all(width: 1, color: border)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.5),
                    child: CachedNetworkImage(
                      imageUrl: widget.app.icon,
                      placeholder: (context, url) =>
                          Center(child: CupertinoActivityIndicator()),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.app.title}',
                        style: TextStyle(
                            color: widget.isNightMode
                                ? lightBlackText
                                : heavyBlackText,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.1),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      widget.app.task.progress > 0 &&
                              widget.app.task.progress != 100
                          ? LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: widget.isNightMode
                                  ? Color(0xFFA4A4A4)
                                  : grayBg,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isNightMode
                                      ? Colors.white
                                      : redButton),
                              value: widget.app.task.progress / 100,
                            )
                          : SizedBox.shrink(),
                      widget.app.task.progress > 0 &&
                              widget.app.task.progress != 100
                          ? SizedBox(
                              height: 6,
                            )
                          : SizedBox.shrink(),
                      widget.app.task.progress > 0 &&
                              widget.app.task.progress != 100
                          ? Text(
                              widget.app.task.status == 6 ? '已暂停' : '正在下载...',
                              style: TextStyle(
                                  color: lightBlackText,
                                  fontSize: 12,
                                  height: 1),
                            )
                          : Text(
                              Platform.isAndroid
                                  ? '版本 ${widget.app.aversion}'
                                  : '版本 ${widget.app.iversion}',
                              style: TextStyle(
                                  color: lightBlackText,
                                  fontSize: 12,
                                  height: 1),
                            )
                    ],
                  ),
                ),
                SizedBox(
                  width: 24,
                ),
                isLoading
                    ? SizedBox(
                        width: 47,
                        height: 47,
                        child: Center(child: CupertinoActivityIndicator()),
                      )
                    : widget.app.task.progress > 0 &&
                            widget.app.task.progress != 100
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SmallProcessControlButton(
                                isNightMode: widget.isNightMode,
                                type: widget.app.task.status == 6
                                    ? SmallProcessControlButtonType.toPlay
                                    : SmallProcessControlButtonType.toPause,
                                onTap: () async {
                                  if (widget.app.task.status == 6) {
                                    //已经暂停
                                    widget.app.task.taskId =
                                        await FlutterDownloader.resume(
                                            taskId: widget.app.task.taskId)??"";
                                    // widget.app.task.taskId =
                                    debugPrint(widget.app.task.taskId);
                                  } else {
                                    FlutterDownloader.pause(
                                        taskId: widget.app.task.taskId);
                                  }
                                },
                              ),
                              SmallProcessControlButton(
                                //取消下载按钮
                                type: SmallProcessControlButtonType.toStop,
                                isNightMode: widget.isNightMode,
                                onTap: () async {
                                  List<DownloadTask>? list =
                                      await FlutterDownloader.loadTasks();
                                  if (list != null) {
                                    for (DownloadTask task in list) {
                                      if (task.url == widget.app.downurl) {
                                        // FlutterDownloader.cancel(taskId: widget.app.task.taskId);
                                        FlutterDownloader.remove(
                                            taskId: widget.app.task.taskId,
                                            shouldDeleteContent: true);
                                      }
                                      setState(() {
                                        widget.app.task.progress = 0;
                                      });
                                    }
                                  }
                                },
                              ),
                            ],
                          )
                        : _buttonType == RecommendAppType.canOpen
                            ? InkWell(
                                onTap: () async {
                                  String urlString;
                                  if (Platform.isAndroid) {
                                    //urlString = "${widget.app.aid}.${widget.app.aversion}://";
                                    urlString =
                                        "${widget.app.aid}://${widget.app.apath}";
                                    // urlString = "com.inhimtech.znzx://";
                                  } else {
                                    urlString = "${widget.app.iid}://";
                                  }
                                  print(urlString);
                                  if (await canLaunchUrlString(urlString)) {
                                    print('launching...$urlString');
                                    try {
                                      if (Platform.isAndroid) {
                                        AndroidIntent intent = AndroidIntent(
                                          action: 'action_view',
                                          data: Uri.encodeFull(urlString),
                                          flags: <int>[
                                            Flag.FLAG_ACTIVITY_NEW_TASK
                                          ],
                                        );
                                        await intent.launch();
                                      } else {
                                        await launchUrlString(
                                          urlString,
                                        );
                                      }
                                    } on Exception catch (e) {
                                      print(e);
                                    }
                                  }
                                },
                                child: Container(
                                  width: 47,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: widget.isNightMode
                                          ? Color(0xFF262626)
                                          : appOpenBg,
                                      border: Border.all(
                                          width: 0.5,
                                          color: widget.isNightMode
                                              ? Color(0xFFFFFFFF)
                                              : doneBtnBg),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(12))),
                                  child: Text(
                                    '打开',
                                    style: TextStyle(
                                        color: widget.isNightMode
                                            ? Color(0xFFFFFFFF)
                                            : doneBtnBg,
                                        fontSize: 14,
                                        height:
                                            Platform.isAndroid ? 1.1 : null),
                                  ),
                                ),
                              )
                            : widget.app.task.status == 3
                                ? InkWell(
                                    onTap: throttle(() async {
                                      //  if(await File(Utils.getRecommendApkFileName(widget.app.aid, widget.app.aversion)).exists()) {
                                      bool result = await FlutterDownloader.open(
                                          taskId: widget.app.task.taskId,);
                                      if (!result) {
                                        myToast('安装包不存在，正在重新下载');
                                        await gotoDownload();
                                      }
                                    }),
                                    child: Container(
                                      width: 47,
                                      height: 24,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: widget.isNightMode
                                              ? Color(0xFF262626)
                                              : appOpenBg,
                                          border: Border.all(
                                              width: 0.5,
                                              color: widget.isNightMode
                                                  ? Color(0xFFA4A4A4)
                                                  : doneBtnBg),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12))),
                                      child: Text(
                                        '安装',
                                        style: TextStyle(
                                            color: widget.isNightMode
                                                ? lightBlackText
                                                : doneBtnBg,
                                            fontSize: 14,
                                            height: Platform.isAndroid
                                                ? 1.1
                                                : null),
                                      ),
                                    ),
                                  )
                                : _buttonType == RecommendAppType.needUpdate
                                    ? InkWell(
                                        onTap: throttle(() async {
                                          await gotoDownload();
                                        }),
                                        child: Container(
                                          width: 47,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: widget.isNightMode
                                                  ? Color(0xFF262626)
                                                  : appOpenBg,
                                              border: Border.all(
                                                  width: 0.5,
                                                  color: widget.isNightMode
                                                      ? Color(0xFFA4A4A4)
                                                      : doneBtnBg),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12))),
                                          child: Text(
                                            '更新',
                                            style: TextStyle(
                                                color: widget.isNightMode
                                                    ? Color(0xFFA4A4A4)
                                                    : doneBtnBg,
                                                fontSize: 14,
                                                height: Platform.isAndroid
                                                    ? 1.1
                                                    : null),
                                          ),
                                        ),
                                      )
                                    : InkWell(
                                        //下载按钮
                                        onTap: throttle(() async {
                                          await gotoDownload();
                                        }),
                                        child: Image.asset(
                                          widget.isNightMode
                                              ? 'images/app_download_dark.png'
                                              : 'images/app_download.png',
                                          package: 'app_recommend_package',
                                        ),
                                      ),
                SizedBox(
                  width: 12,
                ),
              ],
            ),
            Container(
                color: widget.isNightMode ? Color(0xFF262626) : Colors.white,
                padding: const EdgeInsets.only(left: 58.0, top: 9.5),
                child: Divider(
                    height: 0.5,
                    color: widget.isNightMode
                        ? Color(0xFFA4A4A4)
                        : Color(0xFFEEEEEE)))
          ],
        ),
      ),
    );
  }

  void showDownloadDialog(BuildContext context) {
    YYDialog dialog = YYDialog();
    dialog.build(context)
      // ..useRootNavigator = false
      ..width = 280.0
      ..borderRadius = 5.0
      ..backgroundColor = widget.isNightMode ? Color(0xFF1F1F1F) : Colors.white
      ..widget(Container(
        height: 130,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.5),
                  border: Border.all(width: 1, color: border)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.5),
                child: CachedNetworkImage(
                  imageUrl: widget.app.icon,
                  placeholder: (context, url) =>
                      Center(child: CupertinoActivityIndicator()),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              widget.app.title,
              style: TextStyle(
                  color: widget.isNightMode
                      ? Color(0xFFFFFFFF)
                      : Color(0xFF333333),
                  fontSize: 15),
            ),
          ],
        ),
      ))
      ..widget(SizedBox(
        height: 49,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              width: 0.5,
                              color: widget.isNightMode
                                  ? Color(0xFF555555)
                                  : Color(0xFFDDDDDD)))),
                  child: Text("取消",
                      style: TextStyle(
                        color: widget.isNightMode
                            ? Color(0xFF999999)
                            : Color(0xFF666666),
                        fontSize: 17.0,
                      )),
                ),
                onTap: () {
                  dialog.dismiss();
                },
              ),
            ),
            VerticalDivider(
                width: 0.5,
                color:
                    widget.isNightMode ? Color(0xFF555555) : Color(0xFFDDDDDD)),
            Expanded(
              child: InkWell(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                width: 0.5,
                                color: widget.isNightMode
                                    ? Color(0xFF555555)
                                    : Color(0xFFDDDDDD)))),
                    child: Text("下载安装",
                        style: TextStyle(
                          color: widget.isNightMode
                              ? Color(0xFFFFFFFF)
                              : Colors.red,
                          fontSize: 17.0,
                        )),
                  ),
                  onTap: () async {
                    dialog.dismiss();
                    await gotoDownload();
                  }),
            ),
          ],
        ),
      ))
      ..show();
  }

  void showBrowserDownloadDialog(BuildContext context, String url) {
    YYDialog dialog = YYDialog();
    dialog.build(context)
      // ..useRootNavigator = false
      ..width = 280.0
      ..borderRadius = 5.0
      ..backgroundColor = widget.isNightMode ? Color(0xFF1F1F1F) : Colors.white
      ..duration = Duration(milliseconds: 0)
      ..widget(Container(
        height: 130,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.5),
                  border: Border.all(width: 1, color: border)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.5),
                child: CachedNetworkImage(
                  imageUrl: widget.app.icon,
                  placeholder: (context, url) =>
                      Center(child: CupertinoActivityIndicator()),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "将前往默认浏览器下载APP",
              style: TextStyle(
                  color: widget.isNightMode
                      ? Color(0xFFFFFFFF)
                      : Color(0xFF333333),
                  fontSize: 15),
            ),
          ],
        ),
      ))
      ..widget(SizedBox(
        height: 49,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              width: 0.5,
                              color: widget.isNightMode
                                  ? Color(0xFF555555)
                                  : Color(0xFFDDDDDD)))),
                  child: Text("取消",
                      style: TextStyle(
                        color: widget.isNightMode
                            ? Color(0xFF999999)
                            : Color(0xFF666666),
                        fontSize: 17.0,
                      )),
                ),
                onTap: () {
                  dialog.dismiss();
                },
              ),
            ),
            VerticalDivider(
                width: 0.5,
                color:
                    widget.isNightMode ? Color(0xFF555555) : Color(0xFFDDDDDD)),
            Expanded(
              child: InkWell(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                width: 0.5,
                                color: widget.isNightMode
                                    ? Color(0xFF555555)
                                    : Color(0xFFDDDDDD)))),
                    child: Text("确定",
                        style: TextStyle(
                          color: widget.isNightMode
                              ? Color(0xFFFFFFFF)
                              : Colors.red,
                          fontSize: 17.0,
                        )),
                  ),
                  onTap: () async {
                    dialog.dismiss();
                    launch(url);
                    // launchUrl(Uri.parse(url));
                  }),
            ),
          ],
        ),
      ))
      ..show();
  }

  void Function() throttle(Future<void> Function() func) {
    bool enable = true;
    void Function() target = () {
      if (enable == true) {
        enable = false;
        func().then((_) {
          enable = true;
        });
      }
    };
    return target;
  }

  //android need
  Future<bool> checkPermission(Permission permissionGroup) async {
    //if (Platform.isAndroid) {
//    PermissionStatus permission = await PermissionHandler()
//        .checkPermissionStatus(permissionGroup);
    print('check permissions!!');
    var status = await permissionGroup.status;
    print(status);
    // PermissionStatus permission = await permissionGroup.request();

    print(permissionGroup);
    // print(permission.toString());
    if (status != PermissionStatus.restricted &&
        status != PermissionStatus.granted) {
      // if (permission != PermissionStatus.granted ) {
//      Map<PermissionGroup, PermissionStatus> permissions =
//      await PermissionHandler()
//          .requestPermissions([permissionGroup]);
      Map<Permission, PermissionStatus> permissions =
          await [permissionGroup].request();

      if (permissions[permissionGroup] == PermissionStatus.granted ||
          permissions[permissionGroup] == PermissionStatus.restricted) {
        return true;
      } else if (Platform.isAndroid &&
          permissions[permissionGroup] == PermissionStatus.permanentlyDenied) {
        //await openSetting();
        return false;
      } else if (Platform.isIOS) {
        return false;
      }
    } else {
      return true;
    }
    return false;
  }

  String getRecommendApkFileName(String aid, String aversion) {
    String apkName = aid.substring(aid.lastIndexOf('.') + 1, aid.length);
    apkName = '$apkName$aversion.apk';
    return apkName;
  }

//android need
  Future gotoDownload() async {
    if (Platform.isAndroid) {
      if (widget.isGoogle) {
        showBrowserDownloadDialog(context, widget.app.downurl);
      } else {
        // bool res = await checkPermission(Permission.storage);
        // if (!res) {
        //   return myToast('抱歉，尚未获得您的“存储”权限，请先授权');
        // }
        myToast('操作处理中...');
        var _localPath = (await findLocalPath())??"" + '/Download';
        final savedDir = Directory(_localPath);
        bool hasExisted = await savedDir.exists();
        if (!hasExisted) {
          savedDir.create();
        }

        String apkName =
            getRecommendApkFileName(widget.app.aid, widget.app.aversion);
        List<DownloadTask>? list = await FlutterDownloader.loadTasks();
        if (list != null) {
          for (DownloadTask task in list) {
            if (task.filename == apkName) {
              if (task.status == DownloadTaskStatus.running) {
                return;
              } else if (task.status == DownloadTaskStatus.paused) {
                // task.taskId = await FlutterDownloader.resume(taskId: task.taskId);
                return;
              }
            }
          }
        }

        //下载
        try {
          widget.app.task.taskId = await FlutterDownloader.enqueue(
            url: widget.app.downurl,
            fileName: apkName,
            savedDir: _localPath,
            showNotification: true,
            openFileFromNotification: true,
            headers: {'Mime-Type': 'application/vnd.android.package-archive'},
          )??"";
          widget.app.task.progress = 0;
          widget.app.task.status = 0;
          widget.app.task.filename = apkName;
        } on Exception catch (_) {
          myToast('下载错误，请重试！');
        }
      }
    } else {
      if (await canLaunchUrl(Uri.parse(widget.app.iapurl))) {
        await launchUrl(Uri.parse(widget.app.iapurl));
      }
    }
  }
}

//android need
enum SmallProcessControlButtonType { toPause, toPlay, toStop }

class SmallProcessControlButton extends StatelessWidget {
  final SmallProcessControlButtonType type;
  final VoidCallback onTap;
  final bool isNightMode;
  SmallProcessControlButton({
    Key? key,
    required this.type,
    required this.onTap,
    required this.isNightMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: this.onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.5),
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isNightMode ? Color(0xFF333333) : Color(0xFFF3F3F3),
            shape: BoxShape.circle,
          ),
          child: this.type == SmallProcessControlButtonType.toPause
              ? Icon(
                  Icons.pause_rounded,
                  color: Color(0xFF999999),
                  size: 14,
                )
              : this.type == SmallProcessControlButtonType.toPlay
                  ? Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF999999),
                      size: 14,
                    )
                  : Icon(
                      Icons.close_rounded,
                      color: Color(0xFF999999),
                      size: 14,
                    ),
        ),
      ),
    );
  }
}

void myToast(String msg) {
  Fluttertoast.showToast(
      msg: '$msg',
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black.withOpacity(0.5));
}

// android need
Future<String?> findLocalPath() async {
  //final directory = widget.platform == TargetPlatform.android
  final directory = Platform.isAndroid
      ? await getExternalStorageDirectory()
      : await getApplicationDocumentsDirectory();
  if (directory != null) {
    return directory.path;
  } else {
    return null;
  }
}
