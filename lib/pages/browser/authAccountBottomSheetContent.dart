import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/components/v3/plugin/pluginOutlinedButtonSmall.dart';
import 'package:polkawallet_ui/components/v3/plugin/roundedPluginCard.dart';
import 'package:polkawallet_ui/utils/consts.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class AuthAccountBottomSheetContent extends StatefulWidget {
  const AuthAccountBottomSheetContent(this.uri, this.accountList,
      {this.isEvm, this.onChanged, this.onCancel, this.onConfirm, Key key})
      : super(key: key);

  final Uri uri;
  final List<KeyPairData> accountList;
  final bool isEvm;
  final Function(List<KeyPairData>) onChanged;
  final Function() onCancel;
  final Function() onConfirm;

  @override
  AuthAccountBottomSheetContentState createState() =>
      AuthAccountBottomSheetContentState();
}

class AuthAccountBottomSheetContentState
    extends State<AuthAccountBottomSheetContent> {
  List<KeyPairData> _authedAccounts = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _authedAccounts = [widget.accountList[0]];
      });

      widget.onChanged(_authedAccounts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 24, bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              '${widget.uri.scheme}://${widget.uri.host}/favicon.ico',
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                if ((ModalRoute.of(context).settings.arguments is Map) &&
                    (ModalRoute.of(context).settings.arguments
                            as Map)["icon"] !=
                        null) {
                  return ((ModalRoute.of(context).settings.arguments
                              as Map)["icon"] as String)
                          .contains('.svg')
                      ? SvgPicture.network((ModalRoute.of(context)
                          .settings
                          .arguments as Map)["icon"])
                      : Image.network((ModalRoute.of(context).settings.arguments
                          as Map)["icon"]);
                }
                return Container();
              },
            ),
          ),
        ),
        Text(
          widget.uri.host,
          style: TextStyle(
              color: Colors.white,
              fontSize: UI.getTextSize(18, context),
              fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          child: Text(
            dic['dApp.connect.tip'],
            style: TextStyle(
                fontSize: UI.getTextSize(14, context), color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
            child: SingleChildScrollView(
          child: RoundedPluginCard(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: widget.accountList.map((e) {
                final shouldAdd = _authedAccounts
                        .indexWhere((authed) => authed.pubKey == e.pubKey) ==
                    -1;
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (shouldAdd) {
                        _authedAccounts.add(e);
                      } else {
                        _authedAccounts.remove(e);
                      }
                    });

                    widget.onChanged(_authedAccounts.toList());
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        v3.Checkbox(
                          value: !shouldAdd,
                          onChanged: (v) {
                            setState(() {
                              if (v) {
                                _authedAccounts.add(e);
                              } else {
                                _authedAccounts.remove(e);
                              }
                            });

                            widget.onChanged(_authedAccounts.toList());
                          },
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8, right: 16),
                          child: AddressIcon(e.address,
                              svg: e.icon, tapToCopy: false),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4
                                  .copyWith(color: Colors.white),
                            ),
                            Text(
                              Fmt.address(e.address),
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  .copyWith(color: Colors.white),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        )),
        Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Row(
            children: [
              Expanded(
                child: PluginOutlinedButtonSmall(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  content: dic['dApp.connect.reject'],
                  fontSize: UI.getTextSize(16, context),
                  color: const Color(0xFFD8D8D8),
                  active: true,
                  onPressed: widget.onCancel,
                ),
              ),
              Expanded(
                child: PluginOutlinedButtonSmall(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  content: dic['dApp.connect.allow'],
                  fontSize: UI.getTextSize(16, context),
                  color: PluginColorsDark.primary,
                  active: _authedAccounts.isNotEmpty,
                  onPressed: _authedAccounts.isNotEmpty
                      ? widget.onConfirm
                      : () => null,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
