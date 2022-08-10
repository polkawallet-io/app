import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/button.dart';
import 'package:polkawallet_ui/utils/format.dart';

class AccountBindStep2 extends StatefulWidget {
  AccountBindStep2(this.service, {Key key}) : super(key: key);
  final AppService service;

  @override
  State<AccountBindStep2> createState() => _AccountBindStep2State();
}

class _AccountBindStep2State extends State<AccountBindStep2> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 1.0,
            spreadRadius: 0.0,
            offset: Offset(
              0.0,
              1.0,
            ),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 1.0,
                  spreadRadius: 1.5,
                  offset: Offset(
                    1.0,
                    1.0,
                  ),
                )
              ],
            ),
            child: Padding(
                padding: EdgeInsets.only(left: 12, right: 12),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context).disabledColor,
                            size: 18,
                          )),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text("Create Claim signature",
                          style: Theme.of(context)
                              .textTheme
                              .headline4
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    )
                  ],
                )),
          ),
          Expanded(
              child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 39, bottom: 32),
                  child: Image.asset(
                    "assets/images/complete_ecosystem.png",
                    width: 213,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Text(
                            "Address",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(fontWeight: FontWeight.bold),
                          )),
                      Text(
                        Fmt.address(widget.service.keyring.current.address),
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 21),
                          child: Text(
                            "Message",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(fontWeight: FontWeight.bold),
                          )),
                      Padding(
                          padding: EdgeInsets.only(bottom: 21),
                          child: Text(
                            "Welcome to Acala EVM+!",
                            style: Theme.of(context).textTheme.headline5,
                          )),
                      Text(
                        "Click “sign” to continue \nThis signature will cost 0 gas",
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      Padding(
                          padding: EdgeInsets.only(bottom: 5, top: 21),
                          child: Text(
                            "Substrate Address",
                            style: Theme.of(context)
                                .textTheme
                                .headline4
                                ?.copyWith(fontWeight: FontWeight.bold),
                          )),
                      Text(
                        Fmt.address(widget.service.keyring.current.address),
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )),
          Container(
            margin: EdgeInsets.only(top: 10, bottom: 60),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: Button(
                  title: "Cancel",
                  isBlueBg: false,
                  style: Theme.of(context).textTheme.button?.copyWith(
                      color:
                          Theme.of(context).appBarTheme.titleTextStyle.color),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )),
                Container(
                  width: 38,
                ),
                Expanded(
                    child: Button(
                  title: "Comfirm",
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ))
              ],
            ),
          )
        ],
      ),
    );
  }
}
