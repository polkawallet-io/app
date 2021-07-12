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
const String app_beta_version = 'v2.1.2-beta.1';
const int app_beta_version_code = 2121;
const plugin_github_links = {
  'kusama': 'https://github.com/polkawallet-io/app/issues',
  'polkadot': 'https://github.com/polkawallet-io/app/issues',
  'acala-tc6':
      'https://github.com/AcalaNetwork/polkawallet_plugin_acala/issues',
  'karura': 'https://github.com/AcalaNetwork/polkawallet_plugin_acala/issues',
  'laminar-tc3':
      'https://github.com/polkawallet-io/polkawallet_plugin_laminar/issues',
  'chainx': 'https://github.com/true-eye/polkawallet_plugin_chainx/issues',
  'edgeware': 'https://github.com/remzrn/polkawallet_plugin_edgeware/issues',
};
const plugin_from_community = ['chainx', 'edgeware'];

const relay_chain_name_ksm = 'kusama';
const relay_chain_name_dot = 'polkadot';
const xcm_base_weight = 1000000000;
const xcm_dest_weight_ksm = 3 * xcm_base_weight;

const xcm_send_fees = {
  'statemine': {
    'fee': '3000000000',
    'existentialDeposit': '33333333',
  },
  'karura': {
    'fee': '3000000000',
    'existentialDeposit': '100000000',
  },
};

const show_guide_status_key = 'show_guide_status';
const show_banner_status_key = 'show_banner_status';
