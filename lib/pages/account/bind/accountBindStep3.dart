import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';

class AccountBindStep3 extends StatefulWidget {
  AccountBindStep3(this.service, this.signMessage, this.onNext, {Key key})
      : super(key: key);
  final AppService service;
  final Map signMessage;
  Function onNext;

  @override
  State<AccountBindStep3> createState() => _AccountBindStep3State();
}

class _AccountBindStep3State extends State<AccountBindStep3> {
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
                widget.service.keyringEVM.current,
              ),
              Padding(
                  padding: EdgeInsets.only(bottom: 5, top: 21),
                  child: Text(
                    "Signature",
                    style: Theme.of(context)
                        .textTheme
                        .headline4
                        ?.copyWith(fontWeight: FontWeight.bold),
                  )),
              Text(
                widget.signMessage['signature'],
                style: Theme.of(context).textTheme.headline5,
              ),
            ],
          )),
          Button(
            title: "Bind",
            onPressed: () => widget.onNext(),
          )
        ]));
  }
}
