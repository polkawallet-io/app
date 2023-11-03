class AppFmt {
  static String tokenView(String symbol) {
    String view = symbol;
    if (symbol == 'KUSD' ||
        symbol == 'AUSD' ||
        symbol == 'aUSD' ||
        symbol == 'ASEED') {
      view = 'aSEED';
    }
    return view;
  }

  static bool checkPassword(String pass) {
    var reg = RegExp(r'^(?![0-9]+$)(?![a-zA-Z]+$)[\S]{6,32}$');
    return reg.hasMatch(pass);
  }

  static String pluginNameDisplay(String pluginName) {
    if (pluginName.isEmpty) return pluginName;

    return pluginName == 'statemine'
        ? 'Asset Hub KSM'
        : pluginName == 'statemint'
            ? 'Asset Hub'
            : pluginName.substring(0, 1).toUpperCase() +
                pluginName.substring(1);
  }

  static int convertToInt(dynamic value) {
    if (value is double) {
      try {
        return value.toInt();
      } catch (e) {
        return 0;
      }
    }

    if (value is int) {
      return value;
    }

    try {
      return int.parse(value.toString());
    } catch (e) {
      return 0;
    }
  }
}
