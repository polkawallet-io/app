import 'dart:convert';

import 'package:app/common/consts.dart';
import 'package:app/service/walletApi.dart';
import 'package:app/store/types/dappData.dart';
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
  final String localStorageDAppAuthUrlsKey = 'dAppAuthUrls';

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
  Map<String, List<MessageData>> communityMessages =
      Map<String, List<MessageData>>();

  @observable
  List<MessageData> systemMessages = [];

  @observable
  Map<String, int> communityUnreadNumber = Map<String, int>();

  @observable
  int systemUnreadNumber = 0;

  @observable
  List<dynamic> dappAllTags = [];

  @observable
  List<dynamic> dapps = [];

  Map<dynamic, dynamic> tokenStakingConfig = {
    "onStart": {"KSM": true, "DOT": false},
    "KSM": ["kusama", "bifrost", "parallel heiko"],
    "LKSM": ["parallel heiko"],
    "DOT": ["polkadot"],
    "LDOT": []
  };

  Future<void> initDapps() async {
    final dappConfig = await WalletApi.getDappsConfig();
    dappAllTags = dappConfig["allTag"];
    dapps = dappConfig["datas"];
  }

  @action
  Future<void> setTokenStakingConfig(Map data) async {
    if (data != null) {
      tokenStakingConfig = data;
    }
  }

  Future<void> initMessage(String _languageCode) async {
    final dataCommunity = await WalletApi.getMessage("contents", _languageCode);
    final dataSystem = await WalletApi.getMessage("announces", _languageCode);
    final stored = storage.read(localStorageMessageKey);
    if (dataCommunity != null && dataCommunity.length > 0) {
      final all = List.of(dataCommunity)
          .map((element) => MessageData.fromJson(element))
          .toList();
      final Map<String, List<MessageData>> map =
          Map<String, List<MessageData>>();
      all.forEach((element) {
        if (map[element.network] == null) {
          map[element.network] = [element];
        } else {
          map[element.network].add(element);
        }
      });
      setCommunityMessages(map);
    }
    if (dataSystem != null && dataSystem.length > 0) {
      final all = List.of(dataSystem)
          .map((element) => MessageData.fromJson(element))
          .toList();
      setSystemMessages(all);
    }
    if (stored != null) {
      final Map<String, String> storedMap =
          new Map<String, String>.from(json.decode(stored));
      final Map<String, int> map = Map<String, int>();
      communityMessages.forEach((key, value) {
        map[key] = value
            .where((element) => storedMap[element.file] == null)
            .toList()
            .length;
      });
      setCommunityUnreadNumber(map);

      final int system = systemMessages
          .where((element) => storedMap[element.file] == null)
          .toList()
          .length;
      setSystemUnreadNumber(system);
    } else {
      final Map<String, int> map = Map<String, int>();
      communityMessages.forEach((key, value) {
        map[key] = value.length;
      });
      setCommunityUnreadNumber(map);

      setSystemUnreadNumber(systemMessages.length);
    }
  }

  Map<String, String> getReadMessage() {
    var stored = storage.read(localStorageMessageKey);
    if (stored != null) {
      return new Map<String, String>.from(json.decode(stored));
    }
    return Map<String, String>();
  }

  Future<void> readSystmeMessage(
      List<MessageData> datas, String network) async {
    final storedMap = getReadMessage();
    var isNew = false;
    datas.forEach((element) {
      if (storedMap[element.file] == null) {
        isNew = true;
        storedMap[element.file] = element.network;
      }
    });
    if (!isNew) {
      return;
    }
    storage.write(localStorageMessageKey, json.encode(storedMap));

    final system = systemMessages
        .where((element) => storedMap[element.file] == null)
        .toList()
        .length;
    setSystemUnreadNumber(system);
  }

  Future<void> readCommunityMessage(
      List<MessageData> datas, String network) async {
    final storedMap = getReadMessage();
    var isNew = false;
    datas.forEach((element) {
      if (storedMap[element.file] == null) {
        isNew = true;
        storedMap[element.file] = element.network;
      }
    });
    if (!isNew) {
      return;
    }
    storage.write(localStorageMessageKey, json.encode(storedMap));

    final map = this.communityUnreadNumber;
    map[network] = (communityMessages[network] ?? [])
        .where((element) => storedMap[element.file] == null)
        .toList()
        .length;
    map['all'] = (communityMessages['all'] ?? [])
        .where((element) => storedMap[element.file] == null)
        .toList()
        .length;
    setCommunityUnreadNumber(map);
  }

  @action
  Future<void> setCommunityMessages(Map<String, List<MessageData>> data) async {
    communityMessages = data;
  }

  @action
  Future<void> setSystemMessages(List<MessageData> data) async {
    systemMessages = data;
  }

  @action
  Future<void> setCommunityUnreadNumber(Map<String, int> data) async {
    communityUnreadNumber = data;
  }

  @action
  Future<void> setSystemUnreadNumber(int data) async {
    systemUnreadNumber = data;
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
    if (pluginName == relay_chain_name_dot) {
      return _xcmEnabledChains['$pluginName-xcm'] ?? [];
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

  void updateDAppAuth(String url) {
    final authed = (storage.read(localStorageDAppAuthUrlsKey) as Map) ?? {};
    authed[url] = true;
    storage.write(localStorageDAppAuthUrlsKey, authed);
  }

  bool checkDAppAuth(String url) {
    final authed = storage.read(localStorageDAppAuthUrlsKey) as Map;
    if (authed != null) {
      return authed[url] ?? false;
    }
    return false;
  }
}
