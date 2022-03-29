import 'dart:convert';

import 'package:app/service/walletApi.dart';
import 'package:app/store/types/messageData.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobx/mobx.dart';

part 'settings.g.dart';

class SettingsStore extends _SettingsStore with _$SettingsStore {
  SettingsStore(GetStorage storage) : super(storage);
}

abstract class _SettingsStore with Store {
  _SettingsStore(this.storage);

  final GetStorage storage;

  final String localStorageLocaleKey = 'locale';
  final String localStorageNetworkKey = 'network';
  final String localStorageHideBalanceKey = 'hideBalance';
  final String localStoragePriceCurrencyKey = 'priceCurrency';
  final String localStorageMessageKey = 'message';

  @observable
  String localeCode = '';

  @observable
  bool isHideBalance = false;

  String priceCurrency = 'USD';

  String network = 'polkadot';

  Map pluginsConfig = Map();

  Map adBanners = Map();

  Map _disabledCalls;

  Map _xcmEnabledChains;

  double _rate = -1;

  @observable
  List<MessageData> communityMessages = [];

  @observable
  List<MessageData> systemMessages = [];

  @observable
  int communityUnreadNumber = 0;

  @observable
  int systemUnreadNumber = 0;

  Future<void> initMessage() async {
    final data = await WalletApi.getMessage();
    if (data == null) {
      return;
    }
    final stored = storage.read(localStorageMessageKey);
    if (data['community'].length > 0) {
      setCommunityMessages(List.of(data['community'])
          .map((element) => MessageData.fromJson(element))
          .toList());
    }
    if (data['system'].length > 0) {
      setSystemMessages(List.of(data['system'])
          .map((element) => MessageData.fromJson(element))
          .toList());
    }
    if (stored != null) {
      Map<String, String> storedMap =
          new Map<String, String>.from(json.decode(stored));
      print(storedMap.toString());
      var communityUnreadNumber = 0;
      communityMessages.forEach((element) {
        if (storedMap["${element.id}"] == null) {
          communityUnreadNumber++;
        }
      });
      setCommunityUnreadNumber(communityUnreadNumber);

      var systemUnreadNumber = 0;
      systemMessages.forEach((element) {
        if (storedMap["${element.id}"] == null) {
          systemUnreadNumber++;
        }
      });
      setSystemUnreadNumber(systemUnreadNumber);
    } else {
      setCommunityUnreadNumber(communityMessages.length);
      setSystemUnreadNumber(systemMessages.length);
    }
  }

  Future<void> readMessage(List<MessageData> datas) async {
    var stored = storage.read(localStorageMessageKey);
    Map<String, String> storedMap =
        new Map<String, String>.from(json.decode(stored));
    var isNew = false;
    datas.forEach((element) {
      if (storedMap["${element.id}"] == null) {
        isNew = true;
        storedMap.addAll({"${element.id}": "1"});
      }
    });
    if (!isNew) {
      return;
    }
    storage.write(localStorageMessageKey, json.encode(storedMap));

    var communityUnreadNumber = 0;
    communityMessages.forEach((element) {
      if (storedMap["${element.id}"] == null) {
        communityUnreadNumber++;
      }
    });
    setCommunityUnreadNumber(communityUnreadNumber);

    var systemUnreadNumber = 0;
    systemMessages.forEach((element) {
      if (storedMap["${element.id}"] == null) {
        systemUnreadNumber++;
      }
    });
    setSystemUnreadNumber(systemUnreadNumber);
  }

  @action
  Future<void> setCommunityMessages(List<MessageData> data) async {
    communityMessages = data;
  }

  @action
  Future<void> setSystemMessages(List<MessageData> data) async {
    systemMessages = data;
  }

  @action
  Future<void> setCommunityUnreadNumber(int number) async {
    communityUnreadNumber = number;
  }

  @action
  Future<void> setSystemUnreadNumber(int number) async {
    systemUnreadNumber = number;
  }

  Future<double> getRate() async {
    if (_rate < 0) {
      final data = await WalletApi.getTokenPrices();
      if (data != null && data['rate'] != null) {
        _rate = (data['rate'] as num).toDouble();
      } else {
        _rate = 1;
      }
    }
    return _rate;
  }

  Future<Map> getDisabledCalls(String pluginName) async {
    if (_disabledCalls == null) {
      _disabledCalls = await WalletApi.getDisabledCalls();
    }
    return _disabledCalls[pluginName];
  }

  Future<List> getXcmEnabledChains(String pluginName) async {
    if (_xcmEnabledChains == null) {
      _xcmEnabledChains = await WalletApi.getXcmEnabledConfig();
    }
    return _xcmEnabledChains[pluginName] ?? [];
  }

  @action
  Future<void> init() async {
    await Future.wait([
      loadLocalCode(),
      loadNetwork(),
      loadPriceCurrency(),
      loadIsHideBalance(),
    ]);
    initMessage();
  }

  @action
  Future<void> setLocalCode(String code) async {
    localeCode = code;
    storage.write(localStorageLocaleKey, code);
  }

  @action
  Future<void> loadLocalCode() async {
    final stored = storage.read(localStorageLocaleKey);
    if (stored != null) {
      localeCode = stored;
    }
  }

  @action
  Future<void> setIsHideBalance(bool hide) async {
    isHideBalance = hide;
    storage.write(localStorageHideBalanceKey, hide);
  }

  @action
  Future<void> loadIsHideBalance() async {
    final stored = storage.read(localStorageHideBalanceKey);
    if (stored != null) {
      isHideBalance = stored;
    }
  }

  void setPriceCurrency(String value) {
    priceCurrency = value;
    storage.write(localStoragePriceCurrencyKey, value);
  }

  Future<void> loadPriceCurrency() async {
    final value = await storage.read(localStoragePriceCurrencyKey);
    if (value != null) {
      priceCurrency = value;
    }
  }

  void setNetwork(String value) {
    network = value;
    storage.write(localStorageNetworkKey, value);
  }

  Future<void> loadNetwork() async {
    final value = await storage.read(localStorageNetworkKey);
    if (value != null) {
      network = value;
    }
  }

  void setAdBannerState(Map value) {
    adBanners = value ?? {};
  }

  void setPluginsConfig(Map value) {
    pluginsConfig = value ?? {};
  }
}
