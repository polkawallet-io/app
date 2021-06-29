// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parachain.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$ParachainStore on _ParachainStore, Store {
  final _$auctionDataAtom = Atom(name: '_ParachainStore.auctionData');

  @override
  AuctionData get auctionData {
    _$auctionDataAtom.reportRead();
    return super.auctionData;
  }

  @override
  set auctionData(AuctionData value) {
    _$auctionDataAtom.reportWrite(value, super.auctionData, () {
      super.auctionData = value;
    });
  }

  final _$fundsVisibleAtom = Atom(name: '_ParachainStore.fundsVisible');

  @override
  Map<dynamic, dynamic> get fundsVisible {
    _$fundsVisibleAtom.reportRead();
    return super.fundsVisible;
  }

  @override
  set fundsVisible(Map<dynamic, dynamic> value) {
    _$fundsVisibleAtom.reportWrite(value, super.fundsVisible, () {
      super.fundsVisible = value;
    });
  }

  final _$userContributionsAtom =
      Atom(name: '_ParachainStore.userContributions');

  @override
  Map<dynamic, dynamic> get userContributions {
    _$userContributionsAtom.reportRead();
    return super.userContributions;
  }

  @override
  set userContributions(Map<dynamic, dynamic> value) {
    _$userContributionsAtom.reportWrite(value, super.userContributions, () {
      super.userContributions = value;
    });
  }

  final _$_ParachainStoreActionController =
      ActionController(name: '_ParachainStore');

  @override
  void setAuctionData(AuctionData data, Map<dynamic, dynamic> visible) {
    final _$actionInfo = _$_ParachainStoreActionController.startAction(
        name: '_ParachainStore.setAuctionData');
    try {
      return super.setAuctionData(data, visible);
    } finally {
      _$_ParachainStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setUserContributions(Map<dynamic, dynamic> data) {
    final _$actionInfo = _$_ParachainStoreActionController.startAction(
        name: '_ParachainStore.setUserContributions');
    try {
      return super.setUserContributions(data);
    } finally {
      _$_ParachainStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
auctionData: ${auctionData},
fundsVisible: ${fundsVisible},
userContributions: ${userContributions}
    ''';
  }
}
