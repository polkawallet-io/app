import 'package:app/pages/ecosystem/converToPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_sdk/api/api.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/plugin/pluginTextTag.dart';
import 'package:polkawallet_ui/pages/v3/accountListPage.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/addressIcon.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';

class BridgeAddressTextFormField extends StatefulWidget {
  const BridgeAddressTextFormField(this.api, this.localAccounts,
      {this.initialValue,
      this.onChanged,
      this.hintText,
      this.hintStyle,
      this.errorStyle,
      this.tag,
      this.onFocusChange,
      this.isClean = false,
      Key key})
      : super(key: key);
  final PolkawalletApi api;
  final List<KeyPairData> localAccounts;
  final KeyPairData initialValue;
  final Function(KeyPairData) onChanged;

  final String hintText;
  final TextStyle hintStyle;
  final TextStyle errorStyle;
  final String tag;

  final void Function(bool) onFocusChange;
  final bool isClean;

  @override
  createState() => _BridgeAddressTextFormFieldState();
}

class _BridgeAddressTextFormFieldState
    extends State<BridgeAddressTextFormField> {
  final TextEditingController _controller = TextEditingController();
  final Map _addressIndexMap = {};
  final Map _addressIconsMap = {};
  String validatorError;
  bool hasFocus = false;
  final FocusNode _commentFocus = FocusNode();

  Future<KeyPairData> _getAccountFromInput(String input) async {
    // return local account list if input empty
    if (input.isEmpty || input.trim().length < 3) {
      return null;
    }

    // check if user input is valid address or indices
    final checkAddress = await widget.api.account.decodeAddress([input]);
    if (checkAddress == null) {
      return null;
    }

    final acc = KeyPairData();
    acc.address = input;
    acc.pubKey = checkAddress.keys.toList()[0];
    if (input.length < 47) {
      // check if input indices in local account list
      final int indicesIndex = widget.localAccounts.indexWhere((e) {
        final Map accInfo = e.indexInfo;
        return accInfo != null && accInfo['accountIndex'] == input;
      });
      if (indicesIndex >= 0) {
        return widget.localAccounts[indicesIndex];
      }
      // query account address with account indices
      final queryRes =
          await widget.api.account.queryAddressWithAccountIndex(input);
      if (queryRes != null) {
        acc.address = queryRes;
        acc.name = input;
      }
    } else {
      // check if input address in local account list
      final int addressIndex = widget.localAccounts
          .indexWhere((e) => _itemAsString(e).contains(input));
      if (addressIndex >= 0) {
        return widget.localAccounts[addressIndex];
      }
    }

    // fetch address info if it's a new address
    final res = await widget.api.account.getAddressIcons([acc.address]);
    if (res != null) {
      if (res.isNotEmpty) {
        acc.icon = res[0][1];
        setState(() {
          _addressIconsMap.addAll({acc.address: res[0][1]});
        });
      }

      // The indices query too slow, so we use address as account name
      acc.name ??= Fmt.address(acc.address);
    }
    return acc;
  }

  String _itemAsString(KeyPairData item) {
    final Map accInfo = _getAddressInfo(item);
    String idx = '';
    if (accInfo != null && accInfo['accountIndex'] != null) {
      idx = accInfo['accountIndex'];
    }
    if (item.name != null) {
      return '${item.name} $idx ${item.address}';
    }
    return '${UI.accountDisplayNameString(item.address, accInfo)} $idx ${item.address}';
  }

  Map _getAddressInfo(KeyPairData acc) {
    return acc.indexInfo ?? _addressIndexMap[acc.address];
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    final dicAcala = I18n.of(context).getDic(i18n_full_dic_karura, 'acala');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      widget.tag != null ? PluginTextTag(title: widget.tag) : Container(),
      Focus(
        onFocusChange: (hasFocus) async {
          if (!hasFocus) {
            if (_controller.text.trim().isNotEmpty) {
              final data = await _getAccountFromInput(_controller.text);
              setState(() {
                validatorError = data == null ? dic['address.error'] : null;
              });
              if (data != null && widget.onChanged != null) {
                widget.onChanged(data);
              }
            } else {
              setState(() {
                validatorError = null;
              });
            }
            setState(() {
              this.hasFocus = hasFocus;
            });
            if (widget.onFocusChange != null) {
              widget.onFocusChange(hasFocus);
            }
          }
        },
        child: !hasFocus &&
                widget.initialValue != null &&
                validatorError == null
            ? Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(left: 8),
                      height: 48,
                      decoration: const BoxDecoration(
                          color: Color(0x24FFFFFF),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              bottomLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4))),
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: AddressIcon(
                              widget.initialValue.address,
                              svg: widget.initialValue.icon,
                              size: 30,
                              tapToCopy: false,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  UI.accountName(context, widget.initialValue),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline4
                                      ?.copyWith(
                                          fontFamily: 'Titillium Web SemiBold',
                                          fontSize: UI.getTextSize(14, context),
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFFFFFFF)),
                                ),
                                Text(
                                  Fmt.address(widget.initialValue.address),
                                  style: TextStyle(
                                      fontFamily: 'Titillium Web Regular',
                                      fontSize: UI.getTextSize(10, context),
                                      color: const Color(0xFFFFFFFF)),
                                )
                              ],
                            ),
                          ),
                          GestureDetector(
                            child: const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                )),
                            onTap: () {
                              setState(() {
                                validatorError = dicAcala['cross.warn.info'];
                                hasFocus = true;
                              });
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                FocusScope.of(context)
                                    .requestFocus(_commentFocus);
                              });
                              if (widget.onFocusChange != null) {
                                widget.onFocusChange(hasFocus);
                              }
                            },
                          )
                        ],
                      )),
                ],
              )
            : Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        color: Color(0x24FFFFFF),
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4))),
                    child: TextField(
                      controller: _controller,
                      focusNode: _commentFocus,
                      onChanged: (value) {
                        if (validatorError != null &&
                            _controller.text.trim().toString().isEmpty) {
                          setState(() {
                            validatorError = null;
                          });
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      maxLines: 1,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.only(left: 16, right: 8),
                        hintText: widget.hintText,
                        hintStyle: widget.hintStyle,
                        focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFFF7849), width: 2)),
                        border: InputBorder.none,
                        // suffix:
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        _controller.clear();
                        setState(() {
                          hasFocus = false;
                        });
                        Future.delayed(const Duration(milliseconds: 100), () {
                          FocusScope.of(context).unfocus;
                        });
                        var res = await Navigator.of(context).pushNamed(
                          AccountListPage.route,
                          arguments:
                              AccountListPageParams(list: widget.localAccounts),
                        );
                        if (res != null && widget.onChanged != null) {
                          widget.onChanged(res as KeyPairData);
                        }
                      },
                      child: SizedBox(
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SvgPicture.asset(
                            "packages/polkawallet_ui/assets/images/icon_user.svg",
                            height: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      ErrorMessage(
        validatorError,
        margin: EdgeInsets.zero,
      )
    ]);
  }
}
