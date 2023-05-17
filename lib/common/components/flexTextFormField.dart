import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlexTextFormField extends StatefulWidget {
  const FlexTextFormField(
      {this.controller,
      this.keyboardType,
      this.decoration = const InputDecoration(),
      this.initialValue,
      this.autovalidateMode = AutovalidateMode.onUserInteraction,
      this.inputFormatters,
      this.validator,
      this.bottom,
      Key key})
      : super(key: key);
  final TextEditingController controller;
  final String initialValue;
  final InputDecoration decoration;
  final TextInputType keyboardType;
  final AutovalidateMode autovalidateMode;
  final List<TextInputFormatter> inputFormatters;
  final String Function(String) validator;
  final Widget bottom;

  @override
  FlexTextFormFieldState createState() => FlexTextFormFieldState();
}

class FlexTextFormFieldState extends State<FlexTextFormField> {
  String _error;
  @override
  Widget build(BuildContext context) {
    final inputLength = widget.controller.text.trim().length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 132),
              child: Text(
                _error ?? '',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            Container(
                alignment: Alignment.center,
                width: 254,
                height: 128,
                padding: EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/public/flex_text_form_field_bg.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  controller: widget.controller,
                  initialValue: widget.initialValue,
                  decoration: widget.decoration,
                  keyboardType: widget.keyboardType,
                  autovalidateMode: widget.autovalidateMode,
                  inputFormatters: widget.inputFormatters,
                  validator: (v) {
                    Timer(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        setState(() {
                          _error = widget.validator(v);
                        });
                      }
                    });
                    return null;
                  },
                  style: Theme.of(context).textTheme.headline2.copyWith(
                      fontSize: inputLength < 7 ? 48 : 200 / inputLength * 1.5),
                )),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(top: 98),
              child: widget.bottom ?? Container(),
            ),
          ],
        ),
      ],
    );
  }
}
