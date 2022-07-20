import 'package:app/common/consts.dart';
import 'package:app/pages/assets/index.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_acala/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';

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

  int _assetsTypeIndex = 0;

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
        return PolkawalletAlertDialog(
          title: Text('${dic['manage.save']} ${dic['manage.save.ok']}'),
          actions: [
            PolkawalletActionSheetAction(
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
        final defaultList = widget.service.plugin.defaultTokens.toList();
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
          name: widget.service.plugin.networkState.tokenSymbol[0],
          fullName:
              '${widget.service.plugin.basic.name} ${dic['manage.native']}')
    ];
    list.addAll(widget.service.plugin.noneNativeTokensAll);

    if (_assetsTypeIndex != 0) {
      var type = "Token";
      if (assetsType[_assetsTypeIndex] == "Cross-chain") {
        type = "ForeignAsset";
      } else if (assetsType[_assetsTypeIndex] == "Taiga token") {
        type = "TaigaAsset";
      } else if (assetsType[_assetsTypeIndex] == "LP Tokens") {
        type = "DexShare";
      } else if (assetsType[_assetsTypeIndex] == "ERC-20") {
        type = "Erc20";
      }
      list.retainWhere((element) => element.type == type);
    }

    list.retainWhere((token) =>
        token.symbol.toUpperCase().contains(_filter) ||
        (token.name ?? '').toUpperCase().contains(_filter) ||
        (token.id ?? '').toUpperCase().contains(_filter));

    if (_hide0) {
      list.removeWhere((token) => Fmt.balanceInt(token.amount) == BigInt.zero);
    }

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
                  margin: EdgeInsets.only(right: 14.w),
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
                      color: UI.isDarkTheme(context)
                          ? Theme.of(context).textTheme.headline5?.color
                          : Theme.of(context).cardColor,
                      fontSize: UI.getTextSize(12, context),
                      fontFamily: UI.getFontFamily('TitilliumWeb', context),
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
                margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: v3.TextInputWidget(
                  decoration: v3.InputDecorationV3(
                    contentPadding: EdgeInsets.zero,
                    hintText: dic['manage.filter'],
                    hintStyle: Theme.of(context).textTheme.headline4,
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).disabledColor,
                      size: 20,
                    ),
                  ),
                  controller: _filterCtrl,
                  style: Theme.of(context).textTheme.headline4,
                  onChanged: (v) {
                    setState(() {
                      _filter = _filterCtrl.text.trim().toUpperCase();
                    });
                  },
                )),
            Container(
              margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: _hide0
                              ? Theme.of(context).toggleableActiveColor
                              : Theme.of(context).disabledColor,
                          size: 14,
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 4, right: 16),
                          child: Text(
                            dic['manage.hide'],
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                .copyWith(
                                    fontFamily:
                                        UI.getFontFamily('SF_Pro', context),
                                    color: _hide0
                                        ? Theme.of(context)
                                            .toggleableActiveColor
                                        : Theme.of(context).disabledColor),
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
                  Visibility(
                      visible: widget.service.plugin.basic.name ==
                              plugin_name_karura ||
                          widget.service.plugin.basic.name == plugin_name_acala,
                      child: GestureDetector(
                        child: SvgPicture.asset(
                          'assets/images/icon_screening.svg',
                          color: Colors.white,
                          width: 22,
                        ),
                        onTap: () {
                          final dic = I18n.of(context)
                              .getDic(i18n_full_dic_ui, 'common');
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) {
                              return PolkawalletActionSheet(
                                actions: <Widget>[
                                  ...assetsType.map((element) {
                                    final index = assetsType.indexOf(element);
                                    return PolkawalletActionSheetAction(
                                      isDefaultAction:
                                          index == _assetsTypeIndex,
                                      onPressed: () {
                                        if (index != _assetsTypeIndex) {
                                          setState(() {
                                            _assetsTypeIndex = index;
                                          });
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: Text(element),
                                    );
                                  }).toList()
                                ],
                                cancelButton: PolkawalletActionSheetAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(dic['cancel']),
                                ),
                              );
                            },
                          );
                        },
                      ))
                ],
              ),
            ),
            Expanded(
              child: _tokenVisible.keys.length == 0
                  ? Center(
                      child: CupertinoActivityIndicator(
                          color: const Color(0xFF3C3C44)))
                  : Container(
                      color: UI.isDarkTheme(context)
                          ? Color(0xFF3D3D3D)
                          : Colors.transparent,
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 16),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final id = isStateMint ? '#${list[i].id} ' : '';
                          return Column(
                            children: [
                              Container(
                                color: Colors.transparent,
                                child: ListTile(
                                  dense: list[i].fullName != null,
                                  leading: TokenIcon(
                                    widget.service.plugin.basic.name ==
                                            para_chain_name_statemine
                                        ? list[i].id
                                        : list[i].symbol,
                                    widget.service.plugin.tokenIcons,
                                    symbol: list[i].symbol,
                                  ),
                                  title: Text(list[i].name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline4
                                          .copyWith(
                                              fontWeight: FontWeight.w600)),
                                  subtitle: list[i].fullName != null
                                      ? Text('$id${list[i].fullName}',
                                          maxLines: 2,
                                          style: TextStyle(
                                              fontSize:
                                                  UI.getTextSize(10, context),
                                              fontWeight: FontWeight.w300,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .headline1
                                                  ?.color,
                                              fontFamily: UI.getFontFamily(
                                                  'SF_Pro', context)))
                                      : null,
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
                                        "assets/images/${(_tokenVisible[list[i].symbol] ?? false) ? "icon_circle_select${UI.isDarkTheme(context) ? "_dark" : ""}.png" : "icon_circle_unselect${UI.isDarkTheme(context) ? "_dark" : ""}.png"}",
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
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
