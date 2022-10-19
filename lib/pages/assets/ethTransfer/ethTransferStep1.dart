import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_plugin_evm/polkawallet_plugin_evm.dart';
import 'package:polkawallet_sdk/plugin/store/balances.dart';
import 'package:polkawallet_sdk/storage/types/ethWalletData.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/addressTextFormField.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/index.dart' as v3;
import 'package:polkawallet_ui/pages/scanPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class EthTransferPageParams {
  EthTransferPageParams({
    this.token,
    this.address,
  });
  final TokenBalanceData token;
  String address;
}

class EthTransferStep1 extends StatefulWidget {
  const EthTransferStep1(this.service, {Key key}) : super(key: key);

  static const String route = '/eth/assets/transfer';
  final AppService service;

  @override
  EthTransferStep1State createState() => EthTransferStep1State();
}

class EthTransferStep1State extends State<EthTransferStep1> {
  EthTransferPageParams pageParams;
  EthWalletData _accountTo;

  String _accountToError;
  String _accountWarn;

  Future<void> _onScan() async {
    final to =
        (await Navigator.of(context).pushNamed(ScanPage.route) as QRCodeResult);
    if (to == null) return;

    _updateAccountTo(to.address.address, name: to.address.name);
  }

  Future<void> _updateAccountTo(String address, {String name}) async {
    final acc = EthWalletData()..address = address;
    if (name != null) {
      acc.name = name;
    }

    try {
      final plugin = widget.service.plugin as PluginEvm;
      final res = await Future.wait([
        plugin.sdk.api.service.eth.account.getAddress(address),
        plugin.sdk.api.service.eth.account.getAddressIcons([address])
      ]);
      if (res[1] != null) {
        acc.icon = (res[1] as List)[0][1];
      }

      setState(() {
        _accountTo = acc;
      });
    } catch (err) {
      setState(() {
        _accountToError = err.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final argsObj = (ModalRoute.of(context).settings.arguments as Map) ?? {};
      pageParams = EthTransferPageParams(
          token: TokenBalanceData(
              symbol: argsObj['symbol'] ?? widget.service.pluginEvm.nativeToken,
              id: argsObj['id'],
              decimals: argsObj['decimals']),
          address: argsObj['address']);
      if (pageParams.address != null) {
        _updateAccountTo(pageParams.address);
      } else {
        setState(() {
          _accountTo = widget.service.keyringEVM.current;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plugin = widget.service.plugin as PluginEvm;
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
    final dicUI = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final symbol = pageParams?.token?.symbol ?? 'ACA';
    final decimals = pageParams?.token?.decimals ?? 18;

    final connected = plugin.sdk.api.connectedNode != null;

    final available = Fmt.balanceInt(
        (plugin.balances.native?.availableBalance ?? 0).toString());

    final labelStyle = Theme.of(context)
        .textTheme
        .headline4
        ?.copyWith(fontWeight: FontWeight.bold);
    final subTitleStyle = Theme.of(context).textTheme.headline5?.copyWith(
        height: 1,
        fontWeight: FontWeight.w300,
        fontSize: 12,
        color:
            UI.isDarkTheme(context) ? Colors.white : const Color(0xBF565554));
    final infoValueStyle = Theme.of(context)
        .textTheme
        .headline5
        .copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      appBar: AppBar(
          systemOverlayStyle: UI.isDarkTheme(context)
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          title: Text(dic['evm.send.0']),
          centerTitle: true,
          actions: <Widget>[
            v3.IconButton(
                margin: const EdgeInsets.only(right: 8),
                icon: SvgPicture.asset(
                  'assets/images/scan.svg',
                  color: Theme.of(context).cardColor,
                  width: 24,
                ),
                onPressed: _onScan,
                isBlueBg: true)
          ],
          leading: const BackBtn()),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// step0: send to
                    Text(dic['from'], style: labelStyle),
                    Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 8),
                        child:
                            AddressFormItem(widget.service.keyringEVM.current)),
                    AddressTextFormField(
                      widget.service.plugin.sdk.api,
                      const [],
                      localEthAccounts:
                          widget.service.keyringEVM.allWithContacts.toList(),
                      labelText: dic['to'],
                      labelStyle: labelStyle,
                      hintText: dic['address'],
                      initialValue: _accountTo?.toKeyPairData(),
                      onChanged: (KeyPairData acc) {
                        setState(() {
                          _accountTo = EthWalletData()
                            ..address = acc.address
                            ..name = acc.name
                            ..icon = acc.icon;
                        });
                      },
                      sdk: widget.service.plugin.sdk,
                      key: ValueKey<EthWalletData>(_accountTo),
                    ),
                    Visibility(
                        visible: _accountToError != null,
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: ToAddressWarning(_accountToError),
                        )),
                    Visibility(
                        visible:
                            _accountWarn != null && _accountToError == null,
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: ToAddressWarning(_accountWarn),
                        )),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: v3.Button(
                title: connected ? dicUI['next'] : 'connecting...',
                onPressed: connected
                    ? () {
                        pageParams.address = _accountTo.address;
                        Navigator.of(context).pushNamed(EthTransferStep1.route,
                            arguments: pageParams);
                      }
                    : () => null,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ToAddressWarning extends StatelessWidget {
  const ToAddressWarning(this.message, {Key key}) : super(key: key);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: const Color(0x18FF7847),
          border: Border.all(color: const Color(0xFFFF7847)),
          borderRadius: const BorderRadius.all(Radius.circular(4))),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Image.asset('assets/images/icons/warning.png', width: 32),
          ),
          Flexible(
              child: Text(
            message,
            style: Theme.of(context).textTheme.headline5.copyWith(
                fontSize: UI.getTextSize(13, context),
                fontWeight: FontWeight.bold,
                height: 1.1),
          ))
        ],
      ),
    );
  }
}
