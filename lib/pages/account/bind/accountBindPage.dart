import 'package:app/pages/account/bind/accountBindStep1.dart';
import 'package:app/pages/account/bind/accountBindStep2.dart';
import 'package:app/pages/account/bind/accountBindStep3.dart';
import 'package:app/service/index.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/button.dart';

class AccountBindPage extends StatefulWidget {
  AccountBindPage(this.service, {Key key}) : super(key: key);
  final AppService service;

  static final String route = '/account/accountBind';

  @override
  State<AccountBindPage> createState() => _AccountBindPageState();
}

class _AccountBindPageState extends State<AccountBindPage> {
  int _step = 0;

  showStep2() {
    final controller =
        BottomSheet.createAnimationController(Navigator.of(context));
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _step == 1) {
        setState(() {
          _step = _step - 1;
        });
      }
    });
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      transitionAnimationController: controller,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          ),
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight -
              130,
          width: double.infinity,
          child: AccountBindStep2(widget.service),
        );
      },
      context: context,
    ).then((value) {
      if (value != null) {
        setState(() {
          _step = 2;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          if (_step == 0) {
            return Future.value(true);
          } else {
            setState(() {
              _step = _step - 1;
              if (_step == 1) {
                showStep2();
              }
            });
          }
          return Future.value(false);
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text('Acala EVM+ Claim'),
                centerTitle: true,
                leading: BackBtn(
                  onBack: () {
                    if (_step == 0) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        _step = _step - 1;
                        if (_step == 1) {
                          showStep2();
                        }
                      });
                    }
                  },
                ),
                elevation: 0),
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return index == _step
                            ? Container(
                                width: 144,
                                child: Button(
                                    child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 1, 10, 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Padding(
                                        child: Text(
                                          "${index + 1}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .button
                                              ?.copyWith(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.0),
                                        ),
                                        padding:
                                            EdgeInsets.only(right: 5, top: 2),
                                      ),
                                      Expanded(
                                          child: Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 5),
                                              child: Text(
                                                index == 0
                                                    ? "Binding EVM/substrate account"
                                                    : index == 1
                                                        ? "Create Claim signature"
                                                        : "Claim account",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .button
                                                    ?.copyWith(
                                                        fontSize: 12,
                                                        height: 1.2),
                                              )))
                                    ],
                                  ),
                                )),
                              )
                            : Container(
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Color(0xFFDDDDDD),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFA7A7A7),
                                      blurRadius: 2.0,
                                      spreadRadius: 0,
                                      offset: Offset(
                                        1.0,
                                        1.0,
                                      ),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .button
                                        ?.copyWith(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFFA9A9A9),
                                            height: 1.3),
                                  ),
                                ),
                              );
                      },
                      itemCount: 3,
                      separatorBuilder: (context, index) => Container(
                        width: 8,
                      ),
                    ),
                  ),
                  Expanded(
                      child: _step == 2
                          ? AccountBindStep3(widget.service, () {
                              Navigator.of(context).pop();
                            })
                          : AccountBindStep1(widget.service, () {
                              setState(() {
                                _step = _step + 1;
                                if (_step == 1) {
                                  showStep2();
                                }
                              });
                            }))
                ],
              ),
            )));
  }
}
