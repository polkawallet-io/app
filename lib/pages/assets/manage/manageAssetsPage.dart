import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';

class ManageAssetsPage extends StatefulWidget {
  const ManageAssetsPage(this.service);

  static final String route = '/assets/manage';
  final AppService service;

  @override
  _ManageAssetsPageState createState() => _ManageAssetsPageState();
}

class _ManageAssetsPageState extends State<ManageAssetsPage> {
  final TextEditingController _filterCtrl = new TextEditingController();

  bool _hide0 = false;
  String _filter = '';
  Map<String, bool> _tokenVisible = {};

  Future<void> _onSave() async {
    final config = Map<String, bool>.of(_tokenVisible);
    if (_hide0) {
      widget.service.plugin.noneNativeTokensAll.forEach((e) {
        if (Fmt.balanceInt(e.amount) == BigInt.zero) {
          config[e.id] = false;
        }
      });
    }
    widget.service.store.assets.setCustomAssets(widget.service.keyring.current,
        widget.service.plugin.basic.name, config);

    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    await showCupertinoDialog(
      context: context,
      builder: (BuildContext ctx) {
        return CupertinoAlertDialog(
          title: Icon(Icons.check_circle, color: Colors.lightGreen, size: 32),
          content: Text('${dic['manage.save']} ${dic['manage.save.ok']}'),
          actions: [
            CupertinoButton(
              child: Text(
                  I18n.of(context).getDic(i18n_full_dic_ui, 'common')['ok']),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    );

    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nativeToken = widget.service.plugin.networkState.tokenSymbol[0];
      final Map<String, bool> defaultVisibleMap = {nativeToken: true};

      if (widget.service.store.assets.customAssets.keys.length == 0) {
        final defaultList =
            widget.service.plugin.balances.tokens.map((e) => e.id).toList();
        defaultList.forEach((token) {
          defaultVisibleMap[token] = true;
        });

        widget.service.plugin.noneNativeTokensAll.forEach((token) {
          if (defaultVisibleMap[token.id] == null) {
            defaultVisibleMap[token.id] = false;
          }
        });
      } else {
        widget.service.plugin.noneNativeTokensAll.forEach((token) {
          defaultVisibleMap[token.id] =
              widget.service.store.assets.customAssets[token.id];
        });
      }

      setState(() {
        _tokenVisible = defaultVisibleMap;
      });
    });
  }

  @override
  void dispose() {
    _filterCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');

    final isStateMint =
        widget.service.plugin.basic.name == para_chain_name_statemine ||
            widget.service.plugin.basic.name == para_chain_name_statemint;

    final List<TokenBalanceData> list = [
      TokenBalanceData(
          amount: widget.service.plugin.balances.native.freeBalance.toString(),
          decimals: widget.service.plugin.networkState.tokenDecimals[0],
          id: widget.service.plugin.networkState.tokenSymbol[0],
          symbol: widget.service.plugin.networkState.tokenSymbol[0],
          name: '${widget.service.plugin.basic.name} ${dic['manage.native']}')
    ];
    list.addAll(widget.service.plugin.noneNativeTokensAll);

    list.retainWhere((token) =>
        token.symbol.toUpperCase().contains(_filter) ||
        (token.name ?? '').toUpperCase().contains(_filter) ||
        (token.id ?? '').toUpperCase().contains(_filter));

    if (_hide0) {
      list.removeWhere((token) => Fmt.balanceInt(token.amount) == BigInt.zero);
    }

    final colorGrey = Theme.of(context).unselectedWidgetColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(dic['manage']),
        centerTitle: true,
        actions: [
          TextButton(
              onPressed: _onSave,
              child: Text(
                dic['manage.save'],
                style: TextStyle(color: Theme.of(context).cardColor),
              ))
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 0,
                    child: GestureDetector(
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _hide0
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor,
                            size: 16,
                          ),
                          Container(
                            margin: EdgeInsets.only(left: 4, right: 16),
                            child: Text(
                              dic['manage.hide'],
                              style: TextStyle(
                                  fontSize: 14,
                                  color: _hide0
                                      ? Theme.of(context).primaryColor
                                      : colorGrey),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _hide0 = !_hide0;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CupertinoTextField(
                      padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        border: Border.all(
                            width: 0.5, color: Theme.of(context).dividerColor),
                      ),
                      controller: _filterCtrl,
                      placeholder: dic['manage.filter'],
                      placeholderStyle: TextStyle(
                          fontSize: 14, color: Theme.of(context).disabledColor),
                      cursorHeight: 14,
                      style: TextStyle(fontSize: 14),
                      suffix: Container(
                        margin: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.search,
                          color: Theme.of(context).disabledColor,
                          size: 20,
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _filter = _filterCtrl.text.trim().toUpperCase();
                        });
                      },
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: _tokenVisible.keys.length == 0
                  ? Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final id = isStateMint ? '#${list[i].id} ' : '';
                        return Container(
                          margin: EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.only(right: 16),
                                child: TokenIcon(
                                  list[i].id,
                                  widget.service.plugin.tokenIcons,
                                  symbol: list[i].symbol,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      list[i].symbol,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: colorGrey),
                                    ),
                                    Visibility(
                                        visible: list[i].name != null,
                                        child: Text(
                                          '$id${list[i].name}',
                                          style: TextStyle(
                                              fontSize: 12, color: colorGrey),
                                        ))
                                  ],
                                ),
                              ),
                              Text(
                                Fmt.priceFloorBigInt(
                                    Fmt.balanceInt(list[i].amount),
                                    list[i].decimals,
                                    lengthMax: 4),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.6),
                              ),
                              CupertinoSwitch(
                                value: _tokenVisible[list[i].id] ?? false,
                                onChanged: (v) {
                                  if (list[i].id !=
                                      widget.service.plugin.networkState
                                          .tokenSymbol[0]) {
                                    setState(() {
                                      _tokenVisible[list[i].id] = v;
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
