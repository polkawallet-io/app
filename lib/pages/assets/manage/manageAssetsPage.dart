import 'package:app/common/consts.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
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
          config[e.symbol] = false;
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
            widget.service.plugin.balances.tokens.map((e) => e.symbol).toList();
        defaultList.forEach((token) {
          defaultVisibleMap[token] = true;
        });

        widget.service.plugin.noneNativeTokensAll.forEach((token) {
          if (defaultVisibleMap[token.symbol] == null) {
            defaultVisibleMap[token.symbol] = false;
          }
        });
      } else {
        widget.service.plugin.noneNativeTokensAll.forEach((token) {
          defaultVisibleMap[token.symbol] =
              widget.service.store.assets.customAssets[token.symbol];
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
          amount:
              widget.service.plugin.balances.native?.freeBalance?.toString() ??
                  "",
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
          elevation: 1.5,
          actions: [
            GestureDetector(
                onTap: _onSave,
                child: Container(
                  padding: EdgeInsets.fromLTRB(15.h, 0, 15.h, 4),
                  margin: EdgeInsets.only(right: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    image: DecorationImage(
                        image: AssetImage("assets/images/icon_bg.png"),
                        fit: BoxFit.contain),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dic['manage.save'],
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontSize: 12,
                      fontFamily: 'TitilliumWeb',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ))
          ],
          leading: BackBtn()),
      body: SafeArea(
        child: Column(
          children: [
            Container(
                margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                height: 52,
                child: v3.TextInputWidget(
                  decoration: v3.InputDecorationV3(
                    contentPadding: EdgeInsets.zero,
                    hintText: dic['manage.filter'],
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).disabledColor,
                      size: 20,
                    ),
                  ),
                  controller: _filterCtrl,
                  style: Theme.of(context).textTheme.headline5,
                  onChanged: (v) {
                    setState(() {
                      _filter = _filterCtrl.text.trim().toUpperCase();
                    });
                  },
                )),
            Container(
              margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GestureDetector(
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _hide0
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor,
                      size: 14,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 4, right: 16),
                      child: Text(
                        dic['manage.hide'],
                        style: Theme.of(context).textTheme.headline5.copyWith(
                            fontFamily: 'SF_Pro',
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
              child: _tokenVisible.keys.length == 0
                  ? Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final id = isStateMint ? '#${list[i].id} ' : '';
                        return Column(
                          children: [
                            Container(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: TokenIcon(
                                  list[i].symbol,
                                  widget.service.plugin.tokenIcons,
                                  symbol: list[i].symbol,
                                ),
                                // todo: fix me
                                // we should use token name here,
                                // for old cache data, it use token symbol as token name.
                                title: Text(
                                    (list[i].name ?? '').toUpperCase() ==
                                                list[i].symbol.toUpperCase() ||
                                            (list[i].name ?? '').contains('-')
                                        ? list[i].name
                                        : list[i].symbol,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline4
                                        .copyWith(fontWeight: FontWeight.w600)),
                                subtitle: Visibility(
                                    visible: list[i].name != null,
                                    child: Text('$id${list[i].name}',
                                        maxLines: 2,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w300,
                                            color: Color(0xFF565554),
                                            fontFamily: "SF_Pro"))),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                        padding: EdgeInsets.only(right: 18.w),
                                        child: Text(
                                          Fmt.priceFloorBigInt(
                                              Fmt.balanceInt(list[i].amount),
                                              list[i].decimals,
                                              lengthMax: 4),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.6),
                                        )),
                                    Image.asset(
                                      "assets/images/${(_tokenVisible[list[i].id] ?? false) ? "icon_circle_select.png" : "icon_circle_unselect.png"}",
                                      fit: BoxFit.contain,
                                      width: 16.w,
                                    )
                                  ],
                                ),
                                onTap: () {
                                  if (list[i].symbol !=
                                      widget.service.plugin.networkState
                                          .tokenSymbol[0]) {
                                    setState(() {
                                      _tokenVisible[list[i].symbol] =
                                          !(_tokenVisible[list[i].symbol] ??
                                              false);
                                    });
                                  }
                                },
                              ),
                            ),
                            Divider(
                              height: 1,
                            )
                          ],
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
