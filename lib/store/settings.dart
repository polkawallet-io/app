import 'package:app/service/walletApi.dart';
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

  @observable
  String localeCode = '';

  @observable
  bool isHideBalance = false;

  String priceCurrency = 'USD';

  String network = 'polkadot';

  @observable
  Map liveModules = Map();

  Map pluginsConfig = Map();

  Map adBanners = Map();

  Map claimState = Map();

  Map _disabledCalls;

  Map _xcmEnabledChains;

  double _rate = -1;

  Future<double> getRate() async {
    if (_rate < 0) {
      final data = await WalletApi.getRate();
      if (data != null && data['code'] == 1) {
        _rate = data['data']['rate'];
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

  @action
  void setLiveModules(Map value) {
    liveModules = value;
  }

  void setAdBannerState(Map value) {
    adBanners = value ?? {};
  }

  void setPluginsConfig(Map value) {
    pluginsConfig = value ?? {};
  }
}
