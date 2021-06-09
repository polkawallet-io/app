const int SECONDS_OF_DAY = 24 * 60 * 60; // seconds of one day
const int SECONDS_OF_YEAR = 365 * 24 * 60 * 60;

const default_ss58_prefix = {
  'info': 'default',
  'text': 'Default for the connected node',
  'value': 42,
};
const prefixList = [
  default_ss58_prefix,
  {'info': 'substrate', 'text': 'Substrate (development)', 'value': 42},
  {'info': 'kusama', 'text': 'Kusama (canary)', 'value': 2},
  {'info': 'polkadot', 'text': 'Polkadot (live)', 'value': 0}
];

/// use this storage to display un-finalized tx
const local_tx_store_key = 'local_tx_store';

/// app versions
enum BuildTargets { apk, playStore, dev }
const String app_beta_version = 'v2.0.8-beta.1';
const int app_beta_version_code = 2081;
const plugin_github_links = {
  'kusama': 'https://github.com/polkawallet-io/app/issues',
  'polkadot': 'https://github.com/polkawallet-io/app/issues',
  'acala-tc6':
      'https://github.com/AcalaNetwork/polkawallet_plugin_acala/issues',
  'laminar-tc3':
      'https://github.com/polkawallet-io/polkawallet_plugin_laminar/issues',
  'chainx': 'https://github.com/true-eye/polkawallet_plugin_chainx/issues',
  'edgeware': 'https://github.com/remzrn/polkawallet_plugin_edgeware/issues',
};
const plugin_from_community = ['chainx', 'edgeware'];

const show_guide_status_key = 'show_guide_status';
const show_banner_status_key = 'show_banner_status';
