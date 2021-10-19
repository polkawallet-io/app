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
const String app_beta_version = 'v2.3.9-beta.2';
const int app_beta_version_code = 2392;

/// para-chains
const relay_chain_name_ksm = 'kusama';
const relay_chain_name_dot = 'polkadot';
const para_chain_name_statemine = 'statemine';
const para_chain_name_statemint = 'statemint';
const para_chain_name_karura = 'karura';
const para_chain_name_bifrost = 'bifrost';
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
  'chainx': 'https://github.com/chainx-org/polkawallet_plugin_chainx/issues',
  'edgeware': 'https://github.com/remzrn/polkawallet_plugin_edgeware/issues',
  para_chain_name_bifrost:
      'https://github.com/bifrost-finance/polkawallet_plugin_bifrost/issues',
};
const plugin_from_community = ['chainx', 'edgeware', para_chain_name_bifrost];

const xcm_base_weight = 1000000000;
const xcm_dest_weight_ksm = 3 * xcm_base_weight;
const xcm_dest_weight_bifrost = 600000000;

const xcm_send_fees = {
  relay_chain_name_ksm: {
    'fee': '30000000000',
    'existentialDeposit': '333333333',
  },
  para_chain_name_statemine: {
    'fee': '3000000000',
    'existentialDeposit': '33333333',
  },
  para_chain_name_karura: {
    'fee': '160000000',
    'existentialDeposit': '100000000',
  },
  para_chain_name_bifrost: {
    'fee': '4800000000',
    'existentialDeposit': '100000000',
  },
};

const xcm_support_dest_chains = {
  relay_chain_name_ksm: [
    relay_chain_name_ksm,
    para_chain_name_statemine,
    para_chain_name_karura,
  ],
  // todo: KSM from statemine to kusasma has bug
  // para_chain_name_statemine: [
  //   para_chain_name_statemine,
  //   relay_chain_name_ksm,
  // ],
  // todo: transfer KAR to bifrost is not open yet
  // para_chain_name_karura: [
  //   para_chain_name_karura,
  //   para_chain_name_bifrost,
  // ],
};

const show_guide_status_key = 'show_guide_status';
const show_banner_status_key = 'show_banner_status';

const JPUSH_APP_KEY = 'dfa60080aa05c5c7b7dc7aa0';
