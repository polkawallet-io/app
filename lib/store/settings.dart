import 'package:app/common/consts.dart';
import 'package:mobx/mobx.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/types/networkStateData.dart';

part 'settings.g.dart';

class SettingsStore extends _SettingsStore with _$SettingsStore {
  SettingsStore(GetStorage storage) : super(storage);
}

abstract class _SettingsStore with Store {
  _SettingsStore(this.storage);

  final GetStorage storage;

  final String localStorageLocaleKey = 'locale';
  final String localStorageEndpointKey = 'endpoint';
  final String localStorageSS58Key = 'custom_ss58';

  final String cacheNetworkStateKey = 'network';
  final String cacheNetworkConstKey = 'network_const';

  String _getCacheKeyOfNetwork(String key) {
    return '${networkName}_$key';
  }

  @observable
  bool loading = true;

  @observable
  String localeCode = '';

  @observable
  String network = 'kusama';

  @observable
  Map<String, dynamic> customSS58Format = Map<String, dynamic>();

  @observable
  String networkName = '';

  @observable
  NetworkStateData networkState = NetworkStateData();

  @observable
  Map networkConst = Map();

  @observable
  Map liveModules = Map();

  @action
  Future<void> init() async {
    await loadLocalCode();
    await loadNetwork();
    await Future.wait([
      loadCustomSS58Format(),
      // loadNetworkStateCache(),
    ]);
  }

  @action
  Future<void> setLocalCode(String code) async {
    await storage.write(localStorageLocaleKey, code);
    localeCode = code;
  }

  @action
  Future<void> loadLocalCode() async {
    String stored = await storage.read(localStorageLocaleKey);
    if (stored != null) {
      localeCode = stored;
    }
  }

  @action
  void setNetworkLoading(bool isLoading) {
    loading = isLoading;
  }

  @action
  void setNetworkName(String name) {
    networkName = name;
    loading = false;
  }

  @action
  Future<void> setNetworkState(
    Map<String, dynamic> data, {
    bool needCache = true,
  }) async {
    networkState = NetworkStateData.fromJson(data);

    if (needCache) {
      storage.write(
        _getCacheKeyOfNetwork(cacheNetworkStateKey),
        data,
      );
    }
  }

  @action
  Future<void> loadNetworkStateCache() async {
    final List data = await Future.wait([
      storage.read(_getCacheKeyOfNetwork(cacheNetworkStateKey)),
      storage.read(_getCacheKeyOfNetwork(cacheNetworkConstKey)),
    ]);
    print(data);
    if (data[0] != null) {
      setNetworkState(Map<String, dynamic>.of(data[0]), needCache: false);
    } else {
      setNetworkState({}, needCache: false);
    }

    if (data[1] != null) {
      setNetworkConst(Map<String, dynamic>.of(data[1]), needCache: false);
    } else {
      setNetworkConst({}, needCache: false);
    }
  }

  @action
  Future<void> setNetworkConst(
    Map<String, dynamic> data, {
    bool needCache = true,
  }) async {
    networkConst = data;

    if (needCache) {
      storage.write(
        _getCacheKeyOfNetwork(cacheNetworkConstKey),
        data,
      );
    }
  }

  @action
  void setNetwork(String value) {
    network = value;
    storage.write(localStorageEndpointKey, value);
  }

  @action
  Future<void> loadNetwork() async {
    final value = await storage.read(localStorageEndpointKey);
    if (value != null) {
      network = value;
    }
  }

  @action
  void setCustomSS58Format(Map<String, dynamic> value) {
    customSS58Format = value;
    storage.write(localStorageSS58Key, value);
  }

  @action
  Future<void> loadCustomSS58Format() async {
    Map<String, dynamic> ss58 = await storage.read(localStorageSS58Key);

    customSS58Format = ss58 ?? default_ss58_prefix;
  }

  @action
  void setLiveModules(Map value) {
    liveModules = value;
  }
}
