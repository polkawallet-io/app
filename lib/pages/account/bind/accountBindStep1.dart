import 'package:app/common/consts.dart';
import 'package:app/pages/account/bind/accountBindEntryPage.dart';
import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/api/types/bridge/bridgeTokenBalance.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginPopLoadingWidget.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AccountBindStep1 extends StatefulWidget {
  const AccountBindStep1(
      this.service,
      this.isPlugin,
      this.tokenBalance,
      this.keyPairData,
      this.ethWalletData,
      this.bindError,
      this.onChange,
      this.onNext,
      {Key key})
      : super(key: key);
  final AppService service;
  final bool isPlugin;
  final KeyPairData keyPairData;
  final EthWalletData ethWalletData;
  final BridgeTokenBalance tokenBalance;
  final Function(KeyPairData, EthWalletData) onChange;
  final Function onNext;
  final String bindError;
  @override
  State<AccountBindStep1> createState() => _AccountBindStep1State();
}

class _AccountBindStep1State extends State<AccountBindStep1> {
  final _viewKey = GlobalKey<FormState>();
  var _isShowSelect = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // queryData();
    });
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

    final available =
        Fmt.balanceInt((widget.tokenBalance?.available ?? 0).toString());
    final decimals = widget.tokenBalance?.decimals ?? 12;
    final symbol = widget.tokenBalance?.token ?? '';

    // widget.service.store.assets
    return PluginPopLoadingContainer(
        isDarkTheme: widget.isPlugin,
        loading: widget.tokenBalance == null,
        child: Padding(
            padding: const EdgeInsets.only(top: 33),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Substrate ${dicPublic['auction.address']}",
                      style: labelStyle),
                  Visibility(
                    visible: widget.tokenBalance != null,
                    child: Text(
                        "${dicPublic["auction.balance"]}: ${Fmt.priceFloorBigInt(
                          available,
                          decimals,
                          lengthMax: 4,
                        )} $symbol",
                        style: balanceStyle),
                  ),
                ],
              ),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.isPlugin
                    ? [
                        ...[
                          AddressFormItem(
                            widget.keyPairData,
                            isDarkTheme: widget.isPlugin,
                          ),
                          Visibility(
                            visible: widget.tokenBalance != null &&
                                available <= BigInt.zero,
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
                            widget.ethWalletData,
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
                            visible: widget.bindError != null,
                            child: ErrorMessage(
                              widget.bindError,
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
                                                  itemBuilder:
                                                      ((context, index) {
                                                    if (index <
                                                        widget
                                                            .service
                                                            .keyringEVM
                                                            .allAccounts
                                                            .length) {
                                                      final account = widget
                                                          .service
                                                          .keyringEVM
                                                          .allAccounts[index];
                                                      return GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap: () {
                                                            _isShowSelect =
                                                                false;
                                                            widget.onChange(
                                                                widget
                                                                    .keyPairData,
                                                                account);
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
                                                              children: <
                                                                  Widget>[
                                                                Container(
                                                                  margin: const EdgeInsets
                                                                          .only(
                                                                      right: 8),
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
                                                                            account.address),
                                                                        style: Theme.of(context)
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
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: () async {
                                                        setState(() {
                                                          _isShowSelect = false;
                                                        });
                                                        await Navigator.of(
                                                                context)
                                                            .pushNamed(
                                                                AccountBindEntryPage
                                                                    .route,
                                                                arguments: widget
                                                                        .isPlugin
                                                                    ? 1
                                                                    : 0); //bind subStrate:0,bind Evm:1
                                                        setState(() {});
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 6,
                                                                bottom: 8,
                                                                left: 17),
                                                        child: Text(
                                                          "Create/Import account",
                                                          style: Theme.of(
                                                                  context)
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
                                                        padding: EdgeInsets
                                                            .symmetric(
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
                            widget.keyPairData,
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
                            visible: widget.tokenBalance != null &&
                                available <= BigInt.zero,
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
                                  AddressFormItem(widget.ethWalletData),
                                  Visibility(
                                    visible: widget.bindError != null,
                                    child: ErrorMessage(
                                      widget.bindError,
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
                                                  itemBuilder:
                                                      ((context, index) {
                                                    if (index <
                                                        widget
                                                            .service
                                                            .keyring
                                                            .allAccounts
                                                            .length) {
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
                                                              widget.onChange(
                                                                  account,
                                                                  widget
                                                                      .ethWalletData);
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
                                                              children: <
                                                                  Widget>[
                                                                Container(
                                                                  margin: const EdgeInsets
                                                                          .only(
                                                                      right: 8),
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
                                                                            .headline5,
                                                                      ),
                                                                      Text(
                                                                        Fmt.address(
                                                                            account.address),
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
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: () async {
                                                        setState(() {
                                                          _isShowSelect = false;
                                                        });
                                                        await Navigator.of(
                                                                context)
                                                            .pushNamed(
                                                                AccountBindEntryPage
                                                                    .route,
                                                                arguments: widget
                                                                        .isPlugin
                                                                    ? 1
                                                                    : 0); //bind subStrate:0,bind Evm:1
                                                        setState(() {});
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                top: 6,
                                                                bottom: 8,
                                                                left: 17),
                                                        child: Text(
                                                          "Create/Import account",
                                                          style: Theme.of(
                                                                  context)
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
                                                        padding: EdgeInsets
                                                            .symmetric(
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
                    if (widget.bindError != null || available <= BigInt.zero) {
                      return;
                    }
                    widget.onNext();
                  },
                ),
              )
            ])));
  }
}
