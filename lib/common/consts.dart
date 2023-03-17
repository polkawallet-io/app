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

/// para-chains
const relay_chain_name_ksm = 'kusama';
const relay_chain_name_dot = 'polkadot';
const para_chain_name_statemine = 'statemine';
const para_chain_name_statemint = 'statemint';
const para_chain_name_karura = 'karura';
const para_chain_name_acala = 'acala';
const para_chain_name_bifrost = 'bifrost';
const chain_name_chainx = 'chainx';
const chain_name_edgeware = 'edgeware';
const chain_name_dbc = 'dbc';
const chain_name_robonomics = 'Robonomics';
const plugin_github_links = {
  relay_chain_name_ksm: 'https://github.com/polkawallet-io/app/issues',
  relay_chain_name_dot: 'https://github.com/polkawallet-io/app/issues',
  'acala-tc6':
      'https://github.com/AcalaNetwork/polkawallet_plugin_acala/issues',
  para_chain_name_karura:
      'https://github.com/AcalaNetwork/polkawallet_plugin_karura/issues',
  para_chain_name_statemine:
      'https://github.com/AcalaNetwork/polkawallet_plugin_statemine/issues',
  'laminar-tc3':
      'https://github.com/polkawallet-io/polkawallet_plugin_laminar/issues',
  chain_name_chainx:
      'https://github.com/chainx-org/polkawallet_plugin_chainx/issues',
  chain_name_edgeware:
      'https://github.com/remzrn/polkawallet_plugin_edgeware/issues',
  para_chain_name_bifrost:
      'https://github.com/bifrost-finance/polkawallet_plugin_bifrost/issues',
  chain_name_dbc:
      'https://github.com/DeepBrainChain/PolkaWallet_Plugin_DBC/issues',
  chain_name_robonomics:
      'https://github.com/Multi-Agent-io/polkawallet_plugin_robonomics/issues',
};
const plugin_from_community = [
  chain_name_chainx,
  chain_name_edgeware,
  para_chain_name_bifrost,
  chain_name_dbc,
  chain_name_robonomics
];

const bridge_account = {
  'mandala': '5G9VH1qNxbPE39SW9SWmDDhePxt1zxLScJ7ync57MFhJSh1v',
  'acala': '13YMK2eYoAvStnzReuxBjMrAvPXmmdsURwZvc62PrdXimbNy'
};

const bridge_sdk_version = 34201;

const show_guide_status_key = 'show_guide_status';

const JPUSH_APP_KEY = 'dfa60080aa05c5c7b7dc7aa0';
