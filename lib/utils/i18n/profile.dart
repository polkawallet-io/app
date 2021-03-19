const Map<String, String> enProfile = {
  'title': 'Profile',
  'account': 'Manage Account',
  'sign': 'Sign and Verify',
  'sign.sign': 'Sign Message',
  'sign.data': 'Sign the following data',
  'sign.res': 'Signature',
  'sign.verify': 'Verify Signature',
  'sign.empty': 'Empty',
  'contact': 'Address Book',
  'contact.address': 'Address',
  'contact.address.error': 'Invalid address',
  'contact.name': 'Name',
  'contact.name.error': 'Name can not be empty',
  'contact.name.exist': 'Name exist',
  'contact.memo': 'Memo',
  'contact.save': 'Save',
  'contact.exist': 'Address exist',
  'contact.edit': 'Edit',
  'contact.delete': 'Delete',
  'contact.delete.warn': 'Are you sure you want to delete this address?',
  'setting': 'Settings',
  'setting.node': 'Remote Node',
  'setting.node.list': 'Available Nodes',
  'setting.prefix': 'Address Prefix',
  'setting.prefix.list': 'Available Prefixes',
  'setting.lang': 'Language',
  'setting.lang.auto': 'Auto Detect',
  'setting.network': 'Select Wallet',
  'about': 'About',
  'name.change': 'Change Name',
  'pass.change': 'Change Password',
  'pass.old': 'Current Password',
  'pass.new': 'New Password',
  'pass.new2': 'Confirm New Password',
  'pass.success': 'Success',
  'pass.success.txt': 'Password changed successfully',
  'pass.error': 'Wrong Password',
  'pass.error.txt': 'Failed to unlock account, please check password.',
  'export': 'Export Account',
  'export.warn': 'Write these words down on paper. Keep the backup paper safe. '
      'These words allows anyone to recover this account and access its funds.',
  'export.keystore.ok': 'Keystore was copied to clipboard.',
  'export.mnemonic.ok': 'Mnemonic was copied to clipboard.',
  'export.rawSeed.ok': 'Raw Seed was copied to clipboard.',
  'delete': 'Delete Account',
  'delete.confirm': 'Input your password to confirm',
  'about.brif': 'Mobile Wallet for Polkadot',
  'about.version': 'Version',
  'update': 'Check Update',
  'update.latest': 'Your App is the newest version.',
  'update.up': 'New version found, update now?',
  'update.start': 'Connecting...',
  'update.download': 'Downloading...',
  'update.install': 'Installing...',
  'update.error': 'Update Failed',
  'update.js.up': 'Metadata needs to be updated to continue.',
  'input.invalid': 'Invalid input',
  'recovery': 'Social Recovery',
  'recovery.brief':
      'Setup your account as recoverable with trusted social recovery helpers.\n\nThe recoverable account is protected against the loss of seed/access by a social process.',
  'recovery.create': 'Create Recovery',
  'recovery.modify': 'Modify',
  'recovery.remove': 'Delete',
  'recovery.remove.warn':
      'Active recoveries detected, you should close them to continue.',
  'recovery.friends': 'Friends',
  'recovery.friends.max': 'Max friends number is 9',
  'recovery.friends.vouched': 'Friends vouched for this',
  'recovery.threshold': 'Threshold',
  'recovery.delay': 'Delay Period',
  'recovery.delay.error': 'Invalid number',
  'recovery.delay.warn':
      'Recommended delay period is 30 days or longer, are you sure to use the customized value?',
  'recovery.custom': 'Custom',
  'recovery.day': 'Days',
  'recovery.deposit': 'Deposit',
  'recovery.deposit.base': 'ConfigDepositBase',
  'recovery.deposit.factor': 'FriendDepositFactor',
  'recovery.deposit.friends': 'NumberOfFriends',
  'recovery.make': 'Make Recoverable',
  'recovery.init': 'Initiate Recovery',
  'recovery.init.new': 'The account to recover to',
  'recovery.init.old': 'Recover this account',
  'recovery.help': 'Vouch for Friend',
  'recovery.help.old': 'recover this account',
  'recovery.help.new': 'the account to recover to',
  'recovery.history': 'History',
  'recovery.not.recoverable': 'is not recoverable',
  'recovery.no.active': 'need to initiate recovery',
  'recovery.process': 'Recovery Process',
  'recovery.time.start': 'Created Time',
  'recovery.close.info':
      '\nIf this recovery is not started by you,\nyou can close it and get the tokens\ndeposited with it.\n',
  'recovery.close': 'Close Recovery',
  'recovery.recoveries': 'My Recoveries',
  'recovery.actions': 'Actions',
  'recovery.claim': 'Claim Recovery',
  'recovery.cancel': 'Cancel Recovered',
  'recovery.recovered': 'Recovered Account',
  'recovery.proxy': 'Proxy Account',
};

const Map<String, String> zhProfile = {
  'title': '设置',
  'account': '账户管理',
  'sign': '签名&验签',
  'sign.sign': '签名信息',
  'sign.data': '签名以下信息',
  'sign.res': '签名结果',
  'sign.verify': '验证签名',
  'sign.empty': '不能为空',
  'contact': '地址簿',
  'contact.address': '地址',
  'contact.address.error': '无效地址',
  'contact.name': '名称',
  'contact.name.error': '名称不能为空',
  'contact.name.exist': '名称已存在',
  'contact.memo': '备注',
  'contact.save': '保存',
  'contact.exist': '地址已存在',
  'contact.edit': '编辑',
  'contact.delete': '删除',
  'contact.delete.warn': '确认删除该地址吗？',
  'setting': '设置',
  'setting.node': '远程节点',
  'setting.node.list': '可选节点',
  'setting.prefix': '地址前缀',
  'setting.prefix.list': '可选格式',
  'setting.lang': '语言',
  'setting.lang.auto': '自动检测',
  'setting.network': '选择钱包',
  'about': '关于',
  'name.change': '修改名称',
  'pass.change': '修改密码',
  'pass.old': '当前密码',
  'pass.new': '新密码',
  'pass.new2': '确认新密码',
  'pass.success': '操作成功',
  'pass.success.txt': '密码已修改',
  'pass.error': '密码错误',
  'pass.error.txt': '解锁账户失败，请检查密码',
  'export': '导出账户',
  'export.warn': '请把以下文字抄写到纸条上并妥善保存，以下文字允许任何人恢复当前账户并获取其中的数字资产。',
  'export.keystore.ok': 'Keystore 已经复制到剪切板',
  'export.mnemonic.ok': 'Mnemonic 已经复制到剪切板',
  'export.rawSeed.ok': 'Raw Seed 已经复制到剪切板',
  'delete': '删除账户',
  'delete.confirm': '输入密码确认操作',
  'about.brif': 'Mobile Wallet for Polkadot',
  'about.version': '版本',
  'update': '检查更新',
  'update.latest': '您的应用已是最新版本。',
  'update.up': '发现新版本，立即更新吗？',
  'update.start': '等待连接...',
  'update.download': '正在下载...',
  'update.install': '开始安装',
  'update.error': '更新失败',
  'update.js.up': '发现网络 Metadata 更新，需要下载才能继续使用。',
  'input.invalid': '输入格式错误',
  'recovery': '社交恢复',
  'recovery.brief':
      '通过设置可信的好友账户，将您的账户配置为可恢复账户。\n\n若您的私钥丢失，可通过社交恢复流程在好友账户的帮助下将该账户资产转移至新的账户。',
  'recovery.create': '创建配置',
  'recovery.modify': '修改配置',
  'recovery.remove': '删除配置',
  'recovery.remove.warn': '存在进行中的恢复请求，需要先将其关闭才能删除配置',
  'recovery.friends': '好友账户',
  'recovery.friends.max': '好友数量最多9个',
  'recovery.friends.vouched': '完成担保的好友',
  'recovery.threshold': '激活所需好友数',
  'recovery.delay': '延迟期',
  'recovery.delay.error': '输入格式错误',
  'recovery.delay.warn': '延迟期建议设置30天以上，确定使用当前设置吗？',
  'recovery.custom': '自定义',
  'recovery.day': '天',
  'recovery.deposit': '押金',
  'recovery.deposit.base': '基础押金',
  'recovery.deposit.factor': '好友押金',
  'recovery.deposit.friends': '好友数量',
  'recovery.make': '恢复配置',
  'recovery.init': '发起恢复',
  'recovery.init.new': '新地址',
  'recovery.init.old': '旧地址',
  'recovery.help': '帮朋友验证',
  'recovery.help.old': '朋友的旧地址',
  'recovery.help.new': '朋友的新地址',
  'recovery.history': '操作记录',
  'recovery.not.recoverable': '不是可恢复账户',
  'recovery.no.active': '需要先发起恢复',
  'recovery.process': '恢复进程',
  'recovery.time.start': '创建时间',
  'recovery.close.info': '\n如果该恢复操作不是您发起的，\n您可以将其关闭，并获得发起人\n为该操作质押的代币。\n',
  'recovery.close': '关闭进程',
  'recovery.recoveries': '我发起的恢复',
  'recovery.actions': '操作',
  'recovery.claim': '完成账户代理',
  'recovery.cancel': '取消账户代理',
  'recovery.recovered': '已恢复账户',
  'recovery.proxy': '代理账户',
};