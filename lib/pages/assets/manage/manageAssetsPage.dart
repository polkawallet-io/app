import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';

class ManageAssetsPage extends StatefulWidget {
  const ManageAssetsPage(this.service);

  static final String route = '/assets/manage';
  final AppService service;

  @override
  _ManageAssetsPageState createState() => _ManageAssetsPageState();
}

class _ManageAssetsPageState extends State<ManageAssetsPage> {
  final TextEditingController _filterCtrl = new TextEditingController();

  String _filter = '';
  Map<String, bool> _tokenVisible = {};

  void _onSave() {
    widget.service.store.assets.setCustomAssets(
        Map<String, bool>.of(_tokenVisible), widget.service.plugin.basic.name);

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

    final List<TokenBalanceData> list = [
      TokenBalanceData(
          id: widget.service.plugin.networkState.tokenSymbol[0],
          symbol: widget.service.plugin.networkState.tokenSymbol[0],
          name: '${widget.service.plugin.basic.name} ${dic['manage.native']}')
    ];
    list.addAll(widget.service.plugin.noneNativeTokensAll);

    list.retainWhere((token) =>
        token.symbol.toUpperCase().contains(_filter) ||
        (token.name ?? '').toUpperCase().contains(_filter));

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
              margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: CupertinoTextField(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  border: Border.all(
                      width: 0.5, color: Theme.of(context).dividerColor),
                ),
                controller: _filterCtrl,
                placeholder: dic['manage.filter'],
                suffix: Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.search,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    _filter = _filterCtrl.text.trim().toUpperCase();
                  });
                },
              ),
            ),
            Expanded(
              child: _tokenVisible.keys.length == 0
                  ? Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.only(right: 16),
                                child: TokenIcon(list[i].id,
                                    widget.service.plugin.tokenIcons),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      list[i].symbol,
                                      style:
                                          Theme.of(context).textTheme.headline4,
                                    ),
                                    list[i].name != null
                                        ? Text(
                                            list[i].name,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .unselectedWidgetColor),
                                          )
                                        : Container()
                                  ],
                                ),
                              ),
                              CupertinoSwitch(
                                value: _tokenVisible[list[i].id] ?? false,
                                onChanged: (v) {
                                  if (i != 0) {
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
