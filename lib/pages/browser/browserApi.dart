import 'package:app/pages/browser/dAppEthWrapperPage.dart';
import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';

class BrowserApi {
  static const _dappLatestKey = 'dapp_latest';
  static const _dappSearchKey = 'dapp_search';
  static const _dappEvmLatestKey = 'dapp_evm_latest';
  static const _dappEvmSearchKey = 'dapp_evm_search';

  static addDappSearchHistory(AppService service, String searchString) {
    if (searchString.trim().isNotEmpty) {
      final dappSearch = getDappSearchHistory(service);
      dappSearch.remove(searchString);
      dappSearch.add(searchString);
      service.store.storage.write(
          service.plugin is PluginEvm ? _dappEvmSearchKey : _dappSearchKey,
          dappSearch);
    }
  }

  static deleteAllSearchHistory(AppService service) {
    service.store.storage.write(
        service.plugin is PluginEvm ? _dappEvmSearchKey : _dappSearchKey, []);
  }

  static List<String> getDappSearchHistory(AppService service) {
    final dappSearch = service.store.storage
        .read(service.plugin is PluginEvm ? _dappEvmSearchKey : _dappSearchKey);
    if (dappSearch != null) {
      return List<String>.from(dappSearch).reversed.toList();
    }
    return [];
  }

  static Future openBrowser(
      BuildContext context, dynamic dapp, AppService service) async {
    var dappLatest = getDappLatestStore(service);
    dappLatest.addAll({dapp["name"]: DateTime.now().toString()});
    service.store.storage.write(
        service.plugin is PluginEvm ? _dappEvmLatestKey : _dappLatestKey,
        dappLatest);
    return await Navigator.of(context).pushNamed(
      DAppEthWrapperPage.route,
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
    service.store.storage.write(
        service.plugin is PluginEvm ? _dappEvmLatestKey : _dappLatestKey,
        dappLatest);
  }

  static deleteAllLatest(AppService service) {
    service.store.storage.write(
        service.plugin is PluginEvm ? _dappEvmLatestKey : _dappLatestKey,
        <String, String>{});
  }

  static Map<String, String> getDappLatestStore(AppService service) {
    final dappLatest = service.store.storage
        .read(service.plugin is PluginEvm ? _dappEvmLatestKey : _dappLatestKey);
    if (dappLatest != null) {
      return Map<String, String>.from(dappLatest);
    }
    return <String, String>{};
  }

  static List<dynamic> getDappLatest(AppService service) {
    var dappLatest = getDappLatestStore(service);
    List<dynamic> datas = [];
    dappLatest.forEach((key, value) {
      try {
        var data = service.store.settings.dapps
            .firstWhere((element) => element["name"] == key);
        data["time"] = DateTime.parse(value);
        datas.add(data);
      } catch (_) {}
    });
    datas.sort((left, right) => right["time"].compareTo(left["time"]));
    return datas;
  }
}
