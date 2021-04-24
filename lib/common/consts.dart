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

/// app versions
enum BuildTargets { apk, playStore, dev }
const String app_beta_version = 'v2.0.4-beta.1';
const int app_beta_version_code = 2041;

const show_guide_status_key = 'show_guide_status';
const show_banner_status_key = 'show_banner_status';
