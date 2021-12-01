import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ShowCustomAlterWidget extends StatefulWidget {
  final Function(String) confirmCallback;

  final String title;

  final String cancel;

  final List<String> options;

  const ShowCustomAlterWidget(
      this.confirmCallback, this.title, this.cancel, this.options);

  @override
  _ShowCustomAlterWidgetState createState() => _ShowCustomAlterWidgetState();
}

class _ShowCustomAlterWidgetState extends State<ShowCustomAlterWidget> {
  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(
        widget.title,
        style: TextStyle(fontSize: 22),
      ),
      actions: <Widget>[
        ...widget.options
            .map((e) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);

                    widget.confirmCallback(e);
                  },
                  child: Text(e),
                ))
            .toList(),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(widget.cancel),
      ),
    );
  }
}
