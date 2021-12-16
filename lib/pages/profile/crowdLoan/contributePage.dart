import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_sdk/api/types/parachain/fundData.dart';
import 'package:polkawallet_sdk/api/types/txInfoData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/addressFormItem.dart';
import 'package:polkawallet_ui/components/v3/txButton.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/back.dart';

class ContributePage extends StatefulWidget {
  const ContributePage(this.service);

  static final String route = '/paras/fund/contribute';
  final AppService service;

  @override
  _ContributePageState createState() => _ContributePageState();
}

class _ContributePageState extends State<ContributePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = new TextEditingController();

  TxFeeEstimateResult _fee;

  Future<TxConfirmParams> _getTxParams() async {
    if (_formKey.currentState.validate()) {
      final FundData fund = ModalRoute.of(context).settings.arguments;
      final symbol =
          (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
      final decimals =
          (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];
      return TxConfirmParams(
        txTitle: 'Contribute',
        module: 'crowdloan',
        call: 'contribute',
        txDisplay: {
          "destination": fund.paraId,
          "currency": symbol,
          "amount": _amountCtrl.text.trim(),
        },
        params: [
          // params.to
          fund.paraId,
          // params.amount
          Fmt.tokenInt(_amountCtrl.text.trim(), decimals).toString(),
          null,
        ],
      );
    }
    return null;
  }

  Future<String> _getTxFee({bool reload = false}) async {
    if (_fee?.partialFee != null && !reload) {
      return _fee.partialFee.toString();
    }

    final sender = TxSenderData(widget.service.keyring.current.address,
        widget.service.keyring.current.pubKey);
    final txInfo = TxInfoData('balances', 'transfer', sender);
    final fee = await widget.service.plugin.sdk.api.tx.estimateFees(
        txInfo, [widget.service.keyring.current.address, '10000000000']);
    if (mounted) {
      setState(() {
        _fee = fee;
      });
    }
    return fee.partialFee.toString();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTxFee();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final dic = I18n.of(context).getDic(i18n_full_dic_app, 'assets');
        final symbol =
            (widget.service.plugin.networkState.tokenSymbol ?? [''])[0];
        final decimals =
            (widget.service.plugin.networkState.tokenDecimals ?? [12])[0];

        final available = Fmt.balanceInt(
            (widget.service.plugin.balances.native?.availableBalance ?? 0)
                .toString());

        final FundData fund = ModalRoute.of(context).settings.arguments;
        final logoUri = widget.service.store.parachain.fundsVisible[fund.paraId]
            ['logo'] as String;
        return Scaffold(
          appBar: AppBar(
              title: Text('Contribute'), centerTitle: true, leading: BackBtn()),
          body: Column(
            children: <Widget>[
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.all(16),
                    children: <Widget>[
                      Text('Crowdloan',
                          style: TextStyle(
                              color: Theme.of(context).unselectedWidgetColor,
                              fontSize: 14)),
                      Container(
                        margin: EdgeInsets.only(top: 4, bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          border: Border.all(
                              color: Theme.of(context).disabledColor,
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: logoUri.contains('.svg')
                                    ? SvgPicture.network(logoUri,
                                        height: 32, width: 32)
                                    : Image.network(logoUri,
                                        height: 32, width: 32),
                              ),
                            ),
                            Expanded(
                                child: Text(
                              widget.service.store.parachain
                                  .fundsVisible[fund.paraId]['name'],
                              style: Theme.of(context).textTheme.headline4,
                            ))
                          ],
                        ),
                      ),
                      AddressFormItem(
                        widget.service.keyring.current,
                        label: dic['from'],
                      ),
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          hintText: dic['amount'],
                          labelText:
                              '${dic['amount']} (${dic['balance']}: ${Fmt.priceFloorBigInt(
                            available,
                            decimals,
                            lengthMax: 6,
                          )} $symbol)',
                        ),
                        inputFormatters: [UI.decimalInputFormatter(decimals)],
                        controller: _amountCtrl,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final error = Fmt.validatePrice(v, context);
                          if (error != null) {
                            return error;
                          }
                          final feeLeft = available - Fmt.tokenInt(v, decimals);
                          BigInt fee = BigInt.zero;
                          if (feeLeft < Fmt.tokenInt('0.02', decimals) &&
                              _fee?.partialFee != null) {
                            fee = Fmt.balanceInt(_fee.partialFee.toString());
                          }
                          if (feeLeft - fee < BigInt.zero) {
                            return dic['amount.low'];
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: TxButton(
                  text: 'Contribute',
                  getTxParams: _getTxParams,
                  onFinish: (res) {
                    if (res != null) {
                      Navigator.of(context).pop(res);
                    }
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
