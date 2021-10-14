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

  @observable
  String localeCode = '';

  @observable
  String network = 'polkadot';

  @observable
  Map liveModules = Map();

  @observable
  Map adBannerState = Map();

  Map _disabledCalls;

  Future<Map> getDisabledCalls(String pluginName) async {
    if (_disabledCalls == null) {
      _disabledCalls = await WalletApi.getDisabledCalls();
    }
    return _disabledCalls[pluginName];
  }

  @action
  Future<void> init() async {
    await loadLocalCode();
    await loadNetwork();
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
  void setNetwork(String value) {
    network = value;
    storage.write(localStorageNetworkKey, value);
  }

  @action
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

  @action
  void setAdBannerState(Map value) {
    adBannerState = value;
  }
}
