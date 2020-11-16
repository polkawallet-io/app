import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

const int tx_list_page_size = 10;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class SubScanRequestParams {
  SubScanRequestParams({
    this.sendPort,
    this.network,
    this.address,
    this.page,
    this.row,
    this.module,
    this.call,
  });

  /// exec in isolate with a message send port
  SendPort sendPort;

  String network;
  String address;
  int page;
  int row;
  String module;
  String call;
}

class SubScanApi {
  final String moduleBalances = 'Balances';
  final String moduleStaking = 'Staking';
  final String moduleDemocracy = 'Democracy';
  final String moduleRecovery = 'Recovery';

  static String getSnEndpoint(String network) {
    if (network.contains('polkadot')) {
      network = 'polkadot';
    }
    if (network.contains('acala')) {
      network = 'acala-testnet';
    }
    return 'https://$network.subscan.io/api/scan';
  }

  /// do the request in an isolate to avoid UI stall
  /// in IOS due to https issue: https://github.com/dart-lang/sdk/issues/41519
  Future<Map> fetchTransfersAsync(
    String address,
    int page, {
    String network = 'kusama',
  }) async {
    Completer completer = new Completer<Map>();

    ReceivePort receivePort = ReceivePort();
    Isolate isolateIns = await Isolate.spawn(
        SubScanApi.fetchTransfers,
        SubScanRequestParams(
          sendPort: receivePort.sendPort,
          network: network,
          address: address,
          page: page,
          row: tx_list_page_size,
        ));
    receivePort.listen((msg) {
      receivePort.close();
      isolateIns.kill(priority: Isolate.immediate);
      completer.complete(msg);
    });
    return completer.future;
  }

  Future<Map> fetchTxsAsync(
    String module, {
    String call,
    int page = 0,
    int size = tx_list_page_size,
    String sender,
    String network = 'kusama',
  }) async {
    Completer completer = new Completer<Map>();

    ReceivePort receivePort = ReceivePort();
    Isolate isolateIns = await Isolate.spawn(
        SubScanApi.fetchTxs,
        SubScanRequestParams(
          sendPort: receivePort.sendPort,
          network: network,
          module: module,
          address: sender,
          page: page,
          row: tx_list_page_size,
        ));
    receivePort.listen((msg) {
      receivePort.close();
      isolateIns.kill(priority: Isolate.immediate);
      completer.complete(msg);
    });
    return completer.future;
  }

  Future<Map> fetchRewardTxsAsync({
    int page = 0,
    int size = tx_list_page_size,
    String sender,
    String network = 'kusama',
  }) async {
    Completer completer = new Completer<Map>();

    ReceivePort receivePort = ReceivePort();
    Isolate isolateIns = await Isolate.spawn(
        SubScanApi.fetchRewardTxs,
        SubScanRequestParams(
          sendPort: receivePort.sendPort,
          network: network,
          address: sender,
          page: page,
          row: tx_list_page_size,
        ));
    receivePort.listen((msg) {
      receivePort.close();
      isolateIns.kill(priority: Isolate.immediate);
      completer.complete(msg);
    });
    return completer.future;
  }

  static Future<Map> fetchTransfers(SubScanRequestParams params) async {
    String url = '${getSnEndpoint(params.network)}/transfers';
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Accept": "*/*"
    };
    String body = jsonEncode({
      "page": params.page,
      "row": params.row,
      "address": params.address,
    });
    Response res = await post(url, headers: headers, body: body);
    if (res.body != null) {
      final obj = await compute(jsonDecode, res.body);
      if (params.sendPort != null) {
        params.sendPort.send(obj['data']);
      }
      return obj['data'];
    }
    if (params.sendPort != null) {
      params.sendPort.send({});
    }
    return {};
  }

  static Future<Map> fetchTxs(SubScanRequestParams para) async {
    String url = '${getSnEndpoint(para.network)}/extrinsics';
    Map<String, String> headers = {"Content-type": "application/json"};
    Map params = {
      "page": para.page,
      "row": para.row,
      "module": para.module,
    };
    if (para.address != null) {
      params['address'] = para.address;
    }
    if (para.call != null) {
      params['call'] = para.call;
    }
    String body = jsonEncode(params);
    Response res = await post(url, headers: headers, body: body);
    if (res.body != null) {
      final obj = await compute(jsonDecode, res.body);
      if (para.sendPort != null) {
        para.sendPort.send(obj['data']);
      }
      return obj['data'];
    }
    if (para.sendPort != null) {
      para.sendPort.send({});
    }
    return {};
  }

  static Future<Map> fetchRewardTxs(SubScanRequestParams para) async {
    String url = '${getSnEndpoint(para.network)}/account/reward_slash';
    Map<String, String> headers = {"Content-type": "application/json"};
    Map params = {
      "address": para.address,
      "page": para.page,
      "row": para.row,
    };
    String body = jsonEncode(params);
    Response res = await post(url, headers: headers, body: body);
    if (res.body != null) {
      final obj = await compute(jsonDecode, res.body);
      if (para.sendPort != null) {
        para.sendPort.send(obj['data']);
      }
      return obj['data'];
    }
    if (para.sendPort != null) {
      para.sendPort.send({});
    }
    return {};
  }

  Future<Map> fetchTokenPriceAsync(String network) async {
    Completer completer = new Completer<Map>();
    ReceivePort receivePort = ReceivePort();
    Isolate isolateIns = await Isolate.spawn(
        SubScanApi.fetchTokenPrice,
        SubScanRequestParams(
          sendPort: receivePort.sendPort,
          network: network,
        ));
    receivePort.listen((msg) {
      receivePort.close();
      isolateIns.kill(priority: Isolate.immediate);
      completer.complete(msg);
    });
    return completer.future;
  }

  static Future<Map> fetchTokenPrice(SubScanRequestParams para) async {
    String url = '${getSnEndpoint(para.network)}/token';
    Map<String, String> headers = {"Content-type": "application/json"};

    Response res = await post(url, headers: headers);
    if (res.body != null) {
      try {
        final obj = await compute(jsonDecode, res.body);
        if (para.sendPort != null) {
          para.sendPort.send(obj['data']);
        }
        return obj['data'];
      } catch (err) {
        // ignore error
      }
    }
    if (para.sendPort != null) {
      para.sendPort.send({});
    }
    return {};
  }
}
