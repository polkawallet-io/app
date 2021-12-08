import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      // title: Text(
      //   widget.title,
      //   style: TextStyle(
      //       color: Theme.of(context).textSelectionColor,
      //       fontSize: 16,
      //       fontWeight: FontWeight.w600,
      //       fontFamily: "TitilliumWeb"),
      // ),
      actions: <Widget>[
        ...widget.options
            .map((e) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);

                    widget.confirmCallback(e);
                  },
                  child: Text(e,
                      style: TextStyle(
                          color: Color(0xFF007AFE),
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          fontFamily: "SF_Pro")),
                ))
            .toList(),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(widget.cancel,
            style: TextStyle(
                color: Color(0xFF007AFE),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                fontFamily: "SF_Pro")),
      ),
    );
  }
}
