import 'package:flutter/cupertino.dart';
import 'package:polkawallet_ui/utils/index.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';

class ShowCustomAlterWidget extends StatefulWidget {
  final Function(String) confirmCallback;

  final String cancel;

  final List<String> options;

  const ShowCustomAlterWidget(
      {@required this.confirmCallback,
      @required this.cancel,
      @required this.options});

  @override
  _ShowCustomAlterWidgetState createState() => _ShowCustomAlterWidgetState();
}

class _ShowCustomAlterWidgetState extends State<ShowCustomAlterWidget> {
  @override
  Widget build(BuildContext context) {
    return PolkawalletActionSheet(
      actions: <Widget>[
        ...widget.options
            .map((e) => PolkawalletActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);

                    widget.confirmCallback(e);
                  },
                  child: Text(e,
                      style: TextStyle(
                          color: Color(0xFF007AFE),
                          fontSize: UI.getTextSize(17, context),
                          fontWeight: FontWeight.w400,
                          fontFamily: UI.getFontFamily('SF_Pro', context))),
                ))
            .toList(),
      ],
      cancelButton: PolkawalletActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(widget.cancel,
            style: TextStyle(
                color: Color(0xFF007AFE),
                fontSize: UI.getTextSize(17, context),
                fontWeight: FontWeight.w500,
                fontFamily: UI.getFontFamily('SF_Pro', context))),
      ),
    );
  }
}
