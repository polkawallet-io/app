import 'package:app/pages/account/bind/accountBindEntryPage.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AccountBindStep1 extends StatefulWidget {
  const AccountBindStep1(this.service, this.isPlugin, this.onNext, {Key key})
      : super(key: key);
  final AppService service;
  final bool isPlugin;
  final Function(EthWalletData) onNext;

  @override
  State<AccountBindStep1> createState() => _AccountBindStep1State();
}

class _AccountBindStep1State extends State<AccountBindStep1> {
  final _viewKey = GlobalKey<FormState>();
  var _isShowSelect = false;

  EthWalletData _ethWalletData;

  String _bindError;

  @override
  void initState() {
    super.initState();
    _ethWalletData = widget.service.keyringEVM.current;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      queryBindAddress();
    });
  }

  void queryBindAddress() async {
    final subAddress = _ethWalletData == null
        ? null
        : await widget.service.account
            .queryAccountWithEvmAddress(_ethWalletData.address);
    final evmAddress = widget.service.keyring.current == null
        ? null
        : await widget.service.account
            .queryEvmAddress(widget.service.keyring.current.address);

    if (subAddress == null && evmAddress == null) {
      setState(() {
        _bindError = null;
      });
      return;
    }
    String addressName;
    String address;
    if (subAddress != null && evmAddress != null) {
      addressName = "substrate/EVM";
      address = "${Fmt.address(evmAddress)}/${Fmt.address(subAddress)}";
    } else if (subAddress != null) {
      addressName = "EVM";
      address = Fmt.address(subAddress);
    } else if (evmAddress != null) {
      addressName = "substrate";
      address = Fmt.address(evmAddress);
    }
    if (subAddress != null || evmAddress != null) {
      setState(() {
        _bindError =
            "The above $addressName address has been bound to $address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.headline4?.copyWith(
        fontWeight: FontWeight.w600,
        color: widget.isPlugin
            ? Colors.white
            : Theme.of(context).textTheme.headline4?.color);
    final balanceStyle = Theme.of(context).textTheme.headline6?.copyWith(
        color: widget.isPlugin
            ? Colors.white.withOpacity(0.6)
            : Theme.of(context).textTheme.headline6?.color);

    final dicPublic = I18n.of(context).getDic(i18n_full_dic_app, 'public');

    return Observer(builder: (context) {
      final available = Fmt.balanceInt(
          (widget.service.plugin.balances.native?.availableBalance ?? 0)
              .toString());
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];

      // widget.service.store.assets
      return Padding(
          padding: const EdgeInsets.only(top: 33),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Substrate ${dicPublic['auction.address']}",
                    style: labelStyle),
                Text(
                    "${dicPublic["auction.balance"]}: ${Fmt.priceFloorBigInt(
                      available,
                      decimals,
                      lengthMax: 4,
                    )} $symbol",
                    style: balanceStyle),
              ],
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.isPlugin
                  ? [
                      ...[
                        AddressFormItem(
                          widget.service.keyring.current,
                          isDarkTheme: widget.isPlugin,
                        ),
                        Visibility(
                          visible: available <= BigInt.zero,
                          child: ErrorMessage(
                            "Some $symbol in Polkadot account is required",
                            margin: const EdgeInsets.only(top: 8),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text("Evm ${dicPublic['auction.address']}",
                                style: labelStyle)),
                        AddressFormItem(
                          _ethWalletData,
                          key: _viewKey,
                          isDarkTheme: widget.isPlugin,
                          margin: EdgeInsets.zero,
                          isGreyBg: false,
                          rightIcon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 22,
                            color: Color(0xFF9B9B9B),
                          ),
                          onTap: () async {
                            setState(() {
                              _isShowSelect = !_isShowSelect;
                            });
                          },
                        ),
                        Visibility(
                          visible: _bindError != null,
                          child: ErrorMessage(
                            _bindError,
                            margin: const EdgeInsets.only(top: 8),
                          ),
                        ),
                        Expanded(
                            child: Visibility(
                                visible: _isShowSelect,
                                child: Container(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: Column(
                                      children: [
                                        Container(
                                            constraints: const BoxConstraints(
                                                maxHeight: 195),
                                            child: RoundedCard(
                                              padding: EdgeInsets.zero,
                                              color: widget.isPlugin
                                                  ? const Color(0xFF353638)
                                                  : null,
                                              child: ListView.separated(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: widget
                                                        .service
                                                        .keyringEVM
                                                        .allAccounts
                                                        .length +
                                                    1,
                                                itemBuilder: ((context, index) {
                                                  if (index <
                                                      widget.service.keyringEVM
                                                          .allAccounts.length) {
                                                    final account = widget
                                                        .service
                                                        .keyringEVM
                                                        .allAccounts[index];
                                                    return GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          setState(() {
                                                            _ethWalletData =
                                                                account;
                                                            _isShowSelect =
                                                                false;
                                                            queryBindAddress();
                                                          });
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 7,
                                                                  bottom: 9,
                                                                  left: 17,
                                                                  right: 17),
                                                          child: Row(
                                                            children: <Widget>[
                                                              Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            8),
                                                                child:
                                                                    AddressIcon(
                                                                  account
                                                                      .address,
                                                                  svg: account
                                                                      .icon,
                                                                  size: 32,
                                                                  tapToCopy:
                                                                      false,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: <
                                                                      Widget>[
                                                                    Text(
                                                                        UI.accountName(
                                                                            context,
                                                                            account),
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline5
                                                                            .copyWith(color: Colors.white)),
                                                                    Text(
                                                                      Fmt.address(
                                                                          account
                                                                              .address),
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .headline6
                                                                          .copyWith(
                                                                              fontSize: 10,
                                                                              color: Colors.white),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ));
                                                  }
                                                  return GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onTap: () {
                                                      setState(() {
                                                        Navigator.of(context).pushNamed(
                                                            AccountBindEntryPage
                                                                .route,
                                                            arguments: widget
                                                                    .isPlugin
                                                                ? 1
                                                                : 0); //bind subStrate:0,bind Evm:1
                                                        _isShowSelect = false;
                                                      });
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6,
                                                              bottom: 8,
                                                              left: 17),
                                                      child: Text(
                                                        "Create/Import account",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headline5
                                                            ?.copyWith(
                                                                color: widget
                                                                        .isPlugin
                                                                    ? const Color(
                                                                        0xFFFFC952)
                                                                    : const Color(
                                                                        0xFF768FE1)),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                                separatorBuilder:
                                                    (context, index) {
                                                  return const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 6),
                                                      child: Divider(
                                                        height: 0.5,
                                                      ));
                                                },
                                              ),
                                            )),
                                      ],
                                    ))))
                      ]
                    ]
                  : [
                      ...[
                        AddressFormItem(
                          widget.service.keyring.current,
                          key: _viewKey,
                          margin: EdgeInsets.zero,
                          isGreyBg: false,
                          rightIcon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 22,
                            color: Color(0xFF9B9B9B),
                          ),
                          onTap: () async {
                            setState(() {
                              _isShowSelect = !_isShowSelect;
                            });
                          },
                        ),
                        Visibility(
                          visible: available <= BigInt.zero,
                          child: ErrorMessage(
                            "Some $symbol in Polkadot account is required",
                            margin: const EdgeInsets.only(top: 8),
                          ),
                        ),
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                        "Evm ${dicPublic['auction.address']}",
                                        style: labelStyle)),
                                AddressFormItem(_ethWalletData),
                                Visibility(
                                  visible: _bindError != null,
                                  child: ErrorMessage(
                                    _bindError,
                                    margin: const EdgeInsets.only(top: 8),
                                  ),
                                )
                              ],
                            ),
                            Visibility(
                                visible: _isShowSelect,
                                child: Container(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: Column(
                                      children: [
                                        Container(
                                            constraints: const BoxConstraints(
                                                maxHeight: 195),
                                            child: RoundedCard(
                                              padding: EdgeInsets.zero,
                                              child: ListView.separated(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: widget
                                                        .service
                                                        .keyring
                                                        .allAccounts
                                                        .length +
                                                    1,
                                                itemBuilder: ((context, index) {
                                                  if (index <
                                                      widget.service.keyring
                                                          .allAccounts.length) {
                                                    final account = widget
                                                        .service
                                                        .keyring
                                                        .allAccounts[index];
                                                    return GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          setState(() {
                                                            _isShowSelect =
                                                                false;
                                                            if (widget
                                                                    .service
                                                                    .keyring
                                                                    .current !=
                                                                account) {
                                                              widget.service
                                                                  .keyring
                                                                  .setCurrent(
                                                                      account);
                                                              widget.service
                                                                  .plugin
                                                                  .changeAccount(
                                                                      account);
                                                              widget.service
                                                                  .store.assets
                                                                  .loadCache(
                                                                      account,
                                                                      widget
                                                                          .service
                                                                          .plugin
                                                                          .basic
                                                                          .name);
                                                              queryBindAddress();
                                                            }
                                                          });
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  top: 7,
                                                                  bottom: 9,
                                                                  left: 17,
                                                                  right: 17),
                                                          child: Row(
                                                            children: <Widget>[
                                                              Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                            .only(
                                                                        right:
                                                                            8),
                                                                child:
                                                                    AddressIcon(
                                                                  account
                                                                      .address,
                                                                  svg: account
                                                                      .icon,
                                                                  size: 32,
                                                                  tapToCopy:
                                                                      false,
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: <
                                                                      Widget>[
                                                                    Text(
                                                                      UI.accountName(
                                                                          context,
                                                                          account),
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .headline5,
                                                                    ),
                                                                    Text(
                                                                      Fmt.address(
                                                                          account
                                                                              .address),
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              10,
                                                                          color:
                                                                              Theme.of(context).unselectedWidgetColor),
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ));
                                                  }
                                                  return GestureDetector(
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    onTap: () {
                                                      setState(() {
                                                        Navigator.of(context).pushNamed(
                                                            AccountBindEntryPage
                                                                .route,
                                                            arguments: widget
                                                                    .isPlugin
                                                                ? 1
                                                                : 0); //bind subStrate:0,bind Evm:1
                                                        _isShowSelect = false;
                                                      });
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6,
                                                              bottom: 8,
                                                              left: 17),
                                                      child: Text(
                                                        "Create/Import account",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headline5
                                                            ?.copyWith(
                                                                color: UI.isDarkTheme(
                                                                        context)
                                                                    ? const Color(
                                                                        0xFFFFC952)
                                                                    : const Color(
                                                                        0xFF768FE1)),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                                separatorBuilder:
                                                    (context, index) {
                                                  return const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 6),
                                                      child: Divider(
                                                        height: 0.5,
                                                      ));
                                                },
                                              ),
                                            )),
                                      ],
                                    )))
                          ],
                        )
                      ]
                    ],
            )),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 70),
              child: Button(
                isDarkTheme: widget.isPlugin,
                style: Theme.of(context).textTheme.button.copyWith(
                    color: widget.isPlugin
                        ? const Color(0xFF121212)
                        : Colors.white),
                title: "Connect",
                onPressed: () {
                  if (_bindError != null || available <= BigInt.zero) {
                    return;
                  }
                  widget.onNext(_ethWalletData);
                },
              ),
            )
          ]));
    });
  }
}
