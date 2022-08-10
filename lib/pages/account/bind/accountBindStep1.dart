import 'package:app/pages/account/bind/accountBindEntryPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AccountBindStep1 extends StatefulWidget {
  AccountBindStep1(this.service, this.onNext, {Key key}) : super(key: key);
  final AppService service;
  Function onNext;

  @override
  State<AccountBindStep1> createState() => _AccountBindStep1State();
}

class _AccountBindStep1State extends State<AccountBindStep1> {
  final _viewKey = GlobalKey<FormState>();
  var _isShowSelect = false;
  KeyPairData _accountTo;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.bold);

    final dicPublic = I18n.of(context).getDic(i18n_full_dic_app, 'public');
    return Padding(
        padding: EdgeInsets.only(top: 33),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Substrate ${dicPublic['auction.address']}",
                  style: labelStyle),
              AddressFormItem(
                widget.service.keyring.current,
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text("Evm ${dicPublic['auction.address']}",
                      style: labelStyle)),
              AddressFormItem(
                _accountTo ?? widget.service.keyring.current,
                key: _viewKey,
                margin: EdgeInsets.zero,
                isGreyBg: false,
                rightIcon: Icon(
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
              Expanded(
                  child: Visibility(
                      visible: _isShowSelect,
                      child: Container(
                          padding: EdgeInsets.only(top: 8, bottom: 8),
                          child: Column(
                            children: [
                              Container(
                                  constraints: BoxConstraints(maxHeight: 195),
                                  child: RoundedCard(
                                    padding: EdgeInsets.zero,
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: widget.service.keyring
                                              .allAccounts.length +
                                          1,
                                      itemBuilder: ((context, index) {
                                        if (index <
                                            widget.service.keyring.allAccounts
                                                .length) {
                                          final account = widget.service.keyring
                                              .allAccounts[index];
                                          return GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                setState(() {
                                                  _accountTo = account;
                                                  _isShowSelect = false;
                                                });
                                              },
                                              child: Container(
                                                padding: EdgeInsets.only(
                                                    top: 7,
                                                    bottom: 9,
                                                    left: 17,
                                                    right: 17),
                                                child: Row(
                                                  children: <Widget>[
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                          right: 8),
                                                      child: AddressIcon(
                                                        account.address,
                                                        svg: account.icon,
                                                        size: 32,
                                                        tapToCopy: false,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(UI.accountName(
                                                              context,
                                                              account)),
                                                          Text(
                                                            Fmt.address(account
                                                                .address),
                                                            style: TextStyle(
                                                                fontSize: 14,
                                                                color: Theme.of(
                                                                        context)
                                                                    .unselectedWidgetColor),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ));
                                        }
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            setState(() {
                                              Navigator.of(context).pushNamed(
                                                  AccountBindEntryPage.route,
                                                  arguments:
                                                      1); //bind subStrate:0,bind Evm:1
                                              _isShowSelect = false;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                top: 6, bottom: 8, left: 17),
                                            child: Text(
                                              "Create/Import account",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline5
                                                  ?.copyWith(
                                                      color: Color(0xFF768FE1)),
                                            ),
                                          ),
                                        );
                                      }),
                                      separatorBuilder: (context, index) {
                                        return Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Divider(
                                              height: 0.5,
                                            ));
                                      },
                                    ),
                                  )),
                            ],
                          ))))
            ],
          )),
          Button(
            title: "Connect",
            onPressed: () => widget.onNext(),
          )
        ]));
  }
}
