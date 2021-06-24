import 'package:get_storage/get_storage.dart';
import 'package:mobx/mobx.dart';
import 'package:polkawallet_sdk/api/types/parachain/auctionData.dart';

part 'parachain.g.dart';

class ParachainStore extends _ParachainStore with _$ParachainStore {
  ParachainStore(GetStorage storage) : super(storage);
}

abstract class _ParachainStore with Store {
  _ParachainStore(this.storage);

  final GetStorage storage;

  @observable
  AuctionData auctionData = AuctionData();

  @observable
  Map fundsVisible = {};

  @observable
  Map userContributions = {};

  @action
  void setAuctionData(AuctionData data, Map visible) {
    auctionData = data;
    fundsVisible = visible;
  }

  @action
  void setUserContributions(Map data) {
    userContributions = data;
  }
}
