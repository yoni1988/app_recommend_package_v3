import 'dart:convert';

import 'enums.dart';

class RacommendAppV2Model {
  late List<RacommendApp> items;
  late Map tops;
  RacommendAppV2Model({required this.items, required this.tops});

  RacommendAppV2Model.fromJson(Map<String, dynamic> json) {
    print(json);
    items = <RacommendApp>[];
    json['items'].forEach((v) {
      items.add(RacommendApp.fromJson(v));
    });
    tops = json['tops'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['items'] = this.items.map((v) => v.toJson()).toList();
    data['tops'] = this.tops;
    return data;
  }
}

class RacommendApp {
  late int id;
  late String icon;
  late String title;
  late String summary;
  late int sorts;
  late String aid;
  late String aversion;
  late String aprotocal;
  late String apath;
  late String downurl;
  late String iid;
  late String iapid;
  late String iapurl;
  late String iversion;
  late String iprotocal;
  late String ipath;
  RecommendAppType? type;
  late AppDownloadTask task;


  RacommendApp(
      {required this.id,
      required this.icon,
      required this.title,
      required this.summary,
      required this.sorts,
      required this.aid,
      required this.aversion,
      required this.aprotocal,
      required this.apath,
      required this.downurl,
      required this.iid,
      required this.iapid,
      required this.iapurl,
      required this.iversion,
      required this.iprotocal,
      required this.ipath,
      this.type,
      required this.task});

  RacommendApp.fromJson(Map<String, dynamic> json) {
    print(json);
    id = json['id'];
    icon = json['icon'];
    title = json['title'];
    summary = json['summary'];
    sorts = json['sorts'];
    aid = json['aid'];
    aversion = json['aversion'];
    aprotocal = json['aprotocal'];
    apath = json['apath'];
    downurl = json['downurl'];
    iid = json['iid'];
    iapid = json['iapid'];
    iapurl = json['iapurl'];
    iversion = json['iversion'];
    iprotocal = json['iprotocal'];
    ipath = json['ipath'];
    task = AppDownloadTask();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['icon'] = this.icon;
    data['title'] = this.title;
    data['summary'] = this.summary;
    data['sorts'] = this.sorts;
    data['aid'] = this.aid;
    data['aversion'] = this.aversion;
    data['aprotocal'] = this.aprotocal;
    data['apath'] = this.apath;
    data['downurl'] = this.downurl;
    data['iid'] = this.iid;
    data['iapid'] = this.iapid;
    data['iapurl'] = this.iapurl;
    data['iversion'] = this.iversion;
    data['iprotocal'] = this.iprotocal;
    data['ipath'] = this.ipath;
    return data;
  }
}

class AppDownloadTask {
  late String taskId;
  late int status;
  late int progress;
  late String filename;

  AppDownloadTask({
    this.taskId = '',
    this.status = 0,
    this.progress = 0,
    this.filename = '',
  });
}

class HostGetModel {
  late int id;
  late String title;
  late int sorts;
  late String host;
  late int seconds;

  HostGetModel(this.id, this.title, this.sorts, this.host);

  HostGetModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    sorts = json['sorts'];
    host = String.fromCharCodes(base64.decode(String.fromCharCodes(base64.decode(json['host']))));//json['host'];
  }
     //String.fromCharCodes(base64.decode(String.fromCharCodes(base64.decode(json['host']))));
}

//推荐应用里的分享
class AppRecommendShareUrl{
  late int shows;
  late String links;
  late String icon;
  late String title;
  late String summary;
  late String moments;


  AppRecommendShareUrl({
    required this.shows,
    required this.links,
    required this.icon,
    required this.title,
    required this.summary,
    required this.moments,
  });


  AppRecommendShareUrl.fromJson(Map<String, dynamic> json) {
    shows = json['shows'];
    links = json['links'];
    icon = json['icon'];
    title = json['title'];
    summary = json['summary'];
    moments = json['moments'];

  }
}