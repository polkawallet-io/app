import 'dart:convert';

import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/pages/dAppWrapperPage.dart';

class BrowserApi {
  static final _dappLatestKey = 'dapp_latest';
  static final _dappSearchKey = 'dapp_search';

  static addDappSearchHistory(AppService service, String searchString) {
    if (searchString.trim().isNotEmpty) {
      final dappSearch = getDappSearchHistory(service);
      dappSearch.remove(searchString);
      dappSearch.add(searchString);
      service.store.storage.write(_dappSearchKey, dappSearch);
    }
  }

  static deleteAllSearchHistory(AppService service) {
    service.store.storage.write(_dappSearchKey, []);
  }

  static List<String> getDappSearchHistory(AppService service) {
    final dappSearch = service.store.storage.read(_dappSearchKey);
    if (dappSearch != null) {
      return List<String>.from(dappSearch).reversed.toList();
    }
    return [];
  }

  static Future openBrowser(
      BuildContext context, dynamic dapp, AppService service) async {
    var dappLatest = getDappLatestStore(service);
    dappLatest.addAll({dapp["name"]: DateTime.now().toString()});
    service.store.storage.write(_dappLatestKey, dappLatest);

    return await Navigator.of(context).pushNamed(
      DAppWrapperPage.route,
      arguments: {
        "url": dapp['detailUrl'],
        "isPlugin": true,
        "icon": dapp["icon"],
        "name": dapp["name"]
      },
    );
  }

  static deleteLatest(dynamic dapp, AppService service) {
    var dappLatest = getDappLatestStore(service);
    dappLatest.remove(dapp["name"]);
    service.store.storage.write(_dappLatestKey, dappLatest);
  }

  static deleteAllLatest(AppService service) {
    service.store.storage.write(_dappLatestKey, Map<String, String>());
  }

  static Map<String, String> getDappLatestStore(AppService service) {
    final dappLatest = service.store.storage.read(_dappLatestKey);
    if (dappLatest != null) {
      return new Map<String, String>.from(dappLatest);
    }
    return Map<String, String>();
  }

  static List<dynamic> getDappLatest(AppService service) {
    var dappLatest = getDappLatestStore(service);
    List<dynamic> datas = [];
    dappLatest.forEach((key, value) {
      var data = service.store.settings.dapps
          .firstWhere((element) => element["name"] == key);
      data["time"] = DateTime.parse(value);
      datas.add(data);
    });
    datas.sort((left, right) => right["time"].compareTo(left["time"]));
    return datas;
  }
}
