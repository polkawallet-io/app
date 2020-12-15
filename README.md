# app

Polkawallet built with Flutter.

## Getting Started

Dependencies
 - Flutter 1.22.x statble
 - Dart 2.10.x

To get started
 1. Clone the repo locally, via git clone https://github.com/polkawallet-io/app.git `<optional local path>`.
 2. Install the dependencies by running `flutter pub get`.
 3. In AndroidStudio, run `lib/main.dart` with arguments `--flavor=prod` on Android Devices,
 or just run `lib/main.dart` with no arguments on IOS.

## Contribute

This app was built with several repos, developers of other substrate based chain
may create their own plugin and put it into polkawallet app:

```
__ polkawallet-io/app
    |
    |__ polkawallet-io/ui
    |    |__ polkawallet-io/sdk
    |         |__ polkawallet-io/js_api
    |
    |__ polkawallet-io/polkawallet_plugin_kusama
    |    |__ polkawallet-io/sdk
    |    |__ polkawallet-io/ui
    |
    |__ polkawallet-io/polkawallet_plugin_acala
    |    |__ polkawallet-io/sdk
    |    |__ polkawallet-io/ui
    |
    |__ <plugin of another substrate based chain>
    |__ <another plugin ...>
    |__ <...>
```

### 1. polkawallet-io/js_api
This is a `polkadot-js/api` wrapper which will be built into a single `main.js` file
to run in a hidden webView inside the App. So the App will connect to a substrate node
with `polkadot-js`.

And we wrapped `polkadot-js/keyring` in it, so the App can manage keyPairs.

### 2. polkawallet-io/sdk
This is a `polkawallet-io/js_api` wrapper dart package, it contains:

 1. Keyring. Managing keyPairs.
 2. PolkawalletSDK. Connect to remote node and call `polkadot-js/api` methods.
 3. PolkawalletPlugin. A base plugin class, defined the data and life-circle methods
 which will be used in the App.

A polkawallet plugin can get users' keyPairs in the App from Keyring instance.

A polkawallet plugin implementation should extend the `PolkawalletPlugin` class and
define it's own data & life-circle methods.

### 3. polkawallet-io/ui
The common used flutter widgets for `polkawallet-io/app`, like:
 - AddressInputForm
 - TxConfirmPage
 - ScanPage
 - ...

### 4. polkawallet-io/polkawallet_plugin_xxx
Examples:
 1. [polkawallet-io/polkawallet_plugin_kusama](https://github.com/polkawallet-io/polkawallet_plugin_kusama)
 2. [polkawallet-io/polkawallet_plugin_acala](https://github.com/polkawallet-io/polkawallet_plugin_acala)

### 5. App state management
We use [https://pub.dev/packages/mobx](https://pub.dev/packages/mobx).
so the directories in a plugin looks like this:
```
__ lib
    |__ pages (the UI)
    |__ store (the MobX store)
    |__ service (the Actions fired by UI to mutate the store)
    |__ ...
```