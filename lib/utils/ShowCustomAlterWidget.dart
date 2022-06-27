import 'package:flutter/cupertino.dart';
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
                  child: Text(e),
                ))
            .toList(),
      ],
      cancelButton: PolkawalletActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Text(widget.cancel),
      ),
    );
  }
}
