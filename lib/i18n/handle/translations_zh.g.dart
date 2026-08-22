///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsZh = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  );

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$zh app = Translations$app$zh.internal(_root);
	late final Translations$common$zh common = Translations$common$zh.internal(_root);
	late final Translations$permission$zh permission = Translations$permission$zh.internal(_root);
	late final Translations$uploads$zh uploads = Translations$uploads$zh.internal(_root);
	late final Translations$tree$zh tree = Translations$tree$zh.internal(_root);
	late final Translations$json$zh json = Translations$json$zh.internal(_root);
	late final Translations$pageable$zh pageable = Translations$pageable$zh.internal(_root);
	late final Translations$pager$zh pager = Translations$pager$zh.internal(_root);
	late final Translations$tips$zh tips = Translations$tips$zh.internal(_root);
	late final Translations$tableColumn$zh tableColumn = Translations$tableColumn$zh.internal(_root);
	late final Translations$button$zh button = Translations$button$zh.internal(_root);
	late final Translations$checkbox$zh checkbox = Translations$checkbox$zh.internal(_root);
	late final Translations$TextField$zh TextField = Translations$TextField$zh.internal(_root);
	late final Translations$Form$zh Form = Translations$Form$zh.internal(_root);
	late final Translations$entity$zh entity = Translations$entity$zh.internal(_root);
	late final Translations$udp$zh udp = Translations$udp$zh.internal(_root);
	late final Translations$errorMiddle$zh errorMiddle = Translations$errorMiddle$zh.internal(_root);
	late final Translations$platform$zh platform = Translations$platform$zh.internal(_root);
	late final Translations$settings$zh settings = Translations$settings$zh.internal(_root);
	late final Translations$cpds$zh cpds = Translations$cpds$zh.internal(_root);
}

// Path: app
class Translations$app$zh {
	Translations$app$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '我的应用'
	String get title => '我的应用';

	late final Translations$app$appbar$zh appbar = Translations$app$appbar$zh.internal(_root);
}

// Path: common
class Translations$common$zh {
	Translations$common$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '确认'
	String get confirm => '确认';

	/// zh: '取消'
	String get cancel => '取消';

	/// zh: '无数据'
	String get noData => '无数据';

	/// zh: '操作成功'
	String get OperationSuccess => '操作成功';

	/// zh: '操作失败'
	String get OperationError => '操作失败';

	/// zh: '请求失败'
	String get requestError => '请求失败';

	/// zh: '请求取消'
	String get requestCancel => '请求取消';

	/// zh: '网络超时，请稍后重试'
	String get requestTimeout => '网络超时，请稍后重试';

	/// zh: '网络连接超时,'
	String get connectionTimeout => '网络连接超时,';

	/// zh: '发送超时'
	String get sendTimeout => '发送超时';

	/// zh: '服务器异常'
	String get serverError => '服务器异常';

	/// zh: '未知错误'
	String get UnknowError => '未知错误';

	/// zh: '预览'
	String get preview => '预览';
}

// Path: permission
class Translations$permission$zh {
	Translations$permission$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '暂无访问权限,是否立即前往【设置】？'
	String get no => '暂无访问权限,是否立即前往【设置】？';

	/// zh: '操作已取消'
	String get cancel => '操作已取消';
}

// Path: uploads
class Translations$uploads$zh {
	Translations$uploads$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '上传成功'
	String get success => '上传成功';

	/// zh: '上传成功; 路径：{path}!'
	String successWithPath({required Object path}) => '上传成功; 路径：${path}!';

	/// zh: '操作已取消'
	String get cancel => '操作已取消';

	/// zh: '上传失败'
	String get failed => '上传失败';

	/// zh: '文件路径不可为空'
	String get emptyPath => '文件路径不可为空';

	/// zh: '文件数据不可为空'
	String get emptyData => '文件数据不可为空';

	/// zh: '文件路径不存在'
	String get existPath => '文件路径不存在';

	/// zh: '请选择一个文件夹'
	String get selectedFolderDialogTitle => '请选择一个文件夹';

	/// zh: '当前仅支持 ZIP 和文件夹'
	String get selectedAllow => '当前仅支持 ZIP 和文件夹';
}

// Path: tree
class Translations$tree$zh {
	Translations$tree$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '<空>'
	String get empty => '<空>';

	/// zh: '未来战士'
	String get futureWarrior => '未来战士';
}

// Path: json
class Translations$json$zh {
	Translations$json$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '收到的信息格式有点陌生'
	String get serialization => '收到的信息格式有点陌生';
}

// Path: pageable
class Translations$pageable$zh {
	Translations$pageable$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'pageSize必须大于等于1'
	String get pageSizeMin => 'pageSize必须大于等于1';

	/// zh: 'pageSize不能超过100'
	String get pageSizeMax => 'pageSize不能超过100';

	/// zh: 'page 必须大于等于 1'
	String get pageMin => 'page 必须大于等于 1';

	/// zh: '参数验证失败: {errors}'
	String paramsValidateError({required Object errors}) => '参数验证失败: ${errors}';

	/// zh: '关键词文字不可超过{count}个字符'
	String keywordValidateError({required Object count}) => '关键词文字不可超过${count}个字符';
}

// Path: pager
class Translations$pager$zh {
	Translations$pager$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$pager$injectParams$zh injectParams = Translations$pager$injectParams$zh.internal(_root);
	late final Translations$pager$radioManager$zh radioManager = Translations$pager$radioManager$zh.internal(_root);
	late final Translations$pager$injectEncrypt$zh injectEncrypt = Translations$pager$injectEncrypt$zh.internal(_root);
}

// Path: tips
class Translations$tips$zh {
	Translations$tips$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '提示'
	String get title => '提示';

	/// zh: '取消'
	String get cancel => '取消';

	/// zh: '确定'
	String get ok => '确定';

	late final Translations$tips$paramsInject$zh paramsInject = Translations$tips$paramsInject$zh.internal(_root);
	late final Translations$tips$keyLoaders$zh keyLoaders = Translations$tips$keyLoaders$zh.internal(_root);
}

// Path: tableColumn
class Translations$tableColumn$zh {
	Translations$tableColumn$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$tableColumn$base$zh base = Translations$tableColumn$base$zh.internal(_root);
	late final Translations$tableColumn$radioManager$zh radioManager = Translations$tableColumn$radioManager$zh.internal(_root);
	late final Translations$tableColumn$injectEncrypt$zh injectEncrypt = Translations$tableColumn$injectEncrypt$zh.internal(_root);
}

// Path: button
class Translations$button$zh {
	Translations$button$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$button$radioManager$zh radioManager = Translations$button$radioManager$zh.internal(_root);
	late final Translations$button$paramsInject$zh paramsInject = Translations$button$paramsInject$zh.internal(_root);
	late final Translations$button$injectEncrypt$zh injectEncrypt = Translations$button$injectEncrypt$zh.internal(_root);
}

// Path: checkbox
class Translations$checkbox$zh {
	Translations$checkbox$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '取消全选'
	String get DeselectAll => '取消全选';

	/// zh: '全选 ({count})'
	String SelectAll({required Object count}) => '全选 (${count})';

	/// zh: '已选中'
	String get selected => '已选中';
}

// Path: TextField
class Translations$TextField$zh {
	Translations$TextField$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '搜索......'
	String get search => '搜索......';

	/// zh: '选择......'
	String get select => '选择......';
}

// Path: Form
class Translations$Form$zh {
	Translations$Form$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$Form$radioManager$zh radioManager = Translations$Form$radioManager$zh.internal(_root);
	late final Translations$Form$injectEncrypt$zh injectEncrypt = Translations$Form$injectEncrypt$zh.internal(_root);
	late final Translations$Form$paramsInject$zh paramsInject = Translations$Form$paramsInject$zh.internal(_root);
}

// Path: entity
class Translations$entity$zh {
	Translations$entity$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '名称不可重复'
	String get sameName => '名称不可重复';

	/// zh: '电台别名已存在'
	String get aliasDuplicate => '电台别名已存在';

	/// zh: '使用人已存在'
	String get consumerDuplicate => '使用人已存在';

	/// zh: 'SN已存在'
	String get snDuplicate => 'SN已存在';
}

// Path: udp
class Translations$udp$zh {
	Translations$udp$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '身份认证失败'
	String get loginFail => '身份认证失败';

	/// zh: '身份认证超时'
	String get loginTimeout => '身份认证超时';

	/// zh: '本地服务已关闭'
	String get closed => '本地服务已关闭';

	/// zh: '心跳应答失败'
	String get pingFail => '心跳应答失败';

	/// zh: '心跳请求超时'
	String get pingTimeout => '心跳请求超时';

	/// zh: '文件传输失败'
	String get fileFail => '文件传输失败';
}

// Path: errorMiddle
class Translations$errorMiddle$zh {
	Translations$errorMiddle$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '发生意外错误，请稍后再试'
	String get error500 => '发生意外错误，请稍后再试';

	/// zh: '无效参数,{error}'
	String errorArg({required Object error}) => '无效参数,${error}';
}

// Path: platform
class Translations$platform$zh {
	Translations$platform$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'The current page isn’t set up for file handling'
	String get webNotReadFile => 'The current page isn’t set up for file handling';
}

// Path: settings
class Translations$settings$zh {
	Translations$settings$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '中文'
	String get zh => '中文';

	/// zh: '英文'
	String get en => '英文';
}

// Path: cpds
class Translations$cpds$zh {
	Translations$cpds$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '文件解析'
	String get fileTitle => '文件解析';

	/// zh: '浏览'
	String get browse => '浏览';

	/// zh: '解析'
	String get parse => '解析';

	/// zh: '请选择通信参数包'
	String get filePlaceholder => '请选择通信参数包';

	/// zh: '网络节点'
	String get nodesTitle => '网络节点';

	/// zh: '解析通信包后显示节点'
	String get nodesEmpty => '解析通信包后显示节点';

	/// zh: '当前节点'
	String get currentTitle => '当前节点';

	/// zh: '已上线 {online}/{expected}'
	String online({required Object online, required Object expected}) => '已上线 ${online}/${expected}';

	/// zh: '请选择一个网络节点'
	String get noSelection => '请选择一个网络节点';

	/// zh: '业务网卡'
	String get networkInterfaceLabel => '业务网卡';

	/// zh: '请选择有线网卡'
	String get networkInterfacePlaceholder => '请选择有线网卡';

	/// zh: '{name} · {ip}'
	String networkInterfaceOption({required Object name, required Object ip}) => '${name} · ${ip}';

	/// zh: '自动选中'
	String get automatic => '自动选中';

	/// zh: '刷新'
	String get refresh => '刷新';

	/// zh: '下发'
	String get distribute => '下发';

	/// zh: '完整下发状态机将在下一阶段实现'
	String get unsupported => '完整下发状态机将在下一阶段实现';

	late final Translations$cpds$stages$zh stages = Translations$cpds$stages$zh.internal(_root);
	late final Translations$cpds$statuses$zh statuses = Translations$cpds$statuses$zh.internal(_root);
	late final Translations$cpds$device$zh device = Translations$cpds$device$zh.internal(_root);
	late final Translations$cpds$deviceTypes$zh deviceTypes = Translations$cpds$deviceTypes$zh.internal(_root);
	late final Translations$cpds$saveDialog$zh saveDialog = Translations$cpds$saveDialog$zh.internal(_root);
	late final Translations$cpds$setPassword$zh setPassword = Translations$cpds$setPassword$zh.internal(_root);
	late final Translations$cpds$export$zh export = Translations$cpds$export$zh.internal(_root);
}

// Path: app.appbar
class Translations$app$appbar$zh {
	Translations$app$appbar$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '参数加注'
	String get paramsInject => '参数加注';

	/// zh: '电台管理'
	String get radioManager => '电台管理';

	/// zh: '注钥管理'
	String get keyManager => '注钥管理';
}

// Path: pager.injectParams
class Translations$pager$injectParams$zh {
	Translations$pager$injectParams$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '未来战士'
	String get futureSoldier => '未来战士';

	/// zh: '业务网卡'
	String get networkCard => '业务网卡';

	late final Translations$pager$injectParams$steps$zh steps = Translations$pager$injectParams$steps$zh.internal(_root);
}

// Path: pager.radioManager
class Translations$pager$radioManager$zh {
	Translations$pager$radioManager$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '电台管理'
	String get title => '电台管理';

	/// zh: '网络节点'
	String get netNode => '网络节点';

	/// zh: '文件分析'
	String get fileParse => '文件分析';
}

// Path: pager.injectEncrypt
class Translations$pager$injectEncrypt$zh {
	Translations$pager$injectEncrypt$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '参数配对'
	String get paramPairing => '参数配对';

	/// zh: '注钥枪管理'
	String get keyLoaderManager => '注钥枪管理';
}

// Path: tips.paramsInject
class Translations$tips$paramsInject$zh {
	Translations$tips$paramsInject$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '当前无可选的密钥枪, 请前往添加后再试'
	String get noKeyLoader => '当前无可选的密钥枪, 请前往添加后再试';

	/// zh: '请勾选电台'
	String get selectRadios => '请勾选电台';

	/// zh: '绑定已完成，是否现在前往配置？'
	String get gotoConfig => '绑定已完成，是否现在前往配置？';
}

// Path: tips.keyLoaders
class Translations$tips$keyLoaders$zh {
	Translations$tips$keyLoaders$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '删除'
	String get delete => '删除';

	/// zh: '确认删除吗'
	String get confirmDelete => '确认删除吗';
}

// Path: tableColumn.base
class Translations$tableColumn$base$zh {
	Translations$tableColumn$base$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '操作'
	String get actions => '操作';
}

// Path: tableColumn.radioManager
class Translations$tableColumn$radioManager$zh {
	Translations$tableColumn$radioManager$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '电台别名'
	String get alias => '电台别名';

	/// zh: '自定义的电台别名'
	String get alias_desc => '自定义的电台别名';

	/// zh: '使用人'
	String get consumer => '使用人';

	/// zh: '电台的使用人'
	String get consumer_desc => '电台的使用人';

	/// zh: '位置'
	String get location => '位置';

	/// zh: '电台位置'
	String get location_desc => '电台位置';

	/// zh: 'SN'
	String get sn => 'SN';

	/// zh: '电台SN号'
	String get sn_desc => '电台SN号';

	/// zh: '展示列信息'
	String get columnInfo => '展示列信息';
}

// Path: tableColumn.injectEncrypt
class Translations$tableColumn$injectEncrypt$zh {
	Translations$tableColumn$injectEncrypt$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '通信参数包'
	String get parameterPacket => '通信参数包';

	/// zh: '配对电台'
	String get radio => '配对电台';

	/// zh: '使用人'
	String get consumer => '使用人';

	/// zh: '位置'
	String get location => '位置';

	/// zh: 'SN'
	String get SN => 'SN';
}

// Path: button.radioManager
class Translations$button$radioManager$zh {
	Translations$button$radioManager$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '添加电台'
	String get createRadio => '添加电台';

	/// zh: '重置'
	String get resetRadio => '重置';

	/// zh: '编辑'
	String get edit => '编辑';

	/// zh: '删除'
	String get delete => '删除';

	/// zh: '清除'
	String get clear => '清除';

	/// zh: '搜索'
	String get search => '搜索';

	/// zh: '保存'
	String get save => '保存';

	/// zh: '浏览'
	String get browse => '浏览';

	/// zh: '分析'
	String get parse => '分析';
}

// Path: button.paramsInject
class Translations$button$paramsInject$zh {
	Translations$button$paramsInject$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '注入'
	String get inject => '注入';

	/// zh: '绑定'
	String get bind => '绑定';

	/// zh: '刷新'
	String get refresh => '刷新';

	/// zh: '下发'
	String get issue => '下发';
}

// Path: button.injectEncrypt
class Translations$button$injectEncrypt$zh {
	Translations$button$injectEncrypt$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '导出'
	String get export => '导出';
}

// Path: Form.radioManager
class Translations$Form$radioManager$zh {
	Translations$Form$radioManager$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$Form$radioManager$alias$zh alias = Translations$Form$radioManager$alias$zh.internal(_root);
	late final Translations$Form$radioManager$sn$zh sn = Translations$Form$radioManager$sn$zh.internal(_root);
	late final Translations$Form$radioManager$location$zh location = Translations$Form$radioManager$location$zh.internal(_root);
	late final Translations$Form$radioManager$consumer$zh consumer = Translations$Form$radioManager$consumer$zh.internal(_root);
}

// Path: Form.injectEncrypt
class Translations$Form$injectEncrypt$zh {
	Translations$Form$injectEncrypt$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$Form$injectEncrypt$name$zh name = Translations$Form$injectEncrypt$name$zh.internal(_root);
}

// Path: Form.paramsInject
class Translations$Form$paramsInject$zh {
	Translations$Form$paramsInject$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '注钥'
	String get text => '注钥';

	late final Translations$Form$paramsInject$deviceType$zh deviceType = Translations$Form$paramsInject$deviceType$zh.internal(_root);
	late final Translations$Form$paramsInject$deviceIp$zh deviceIp = Translations$Form$paramsInject$deviceIp$zh.internal(_root);
	late final Translations$Form$paramsInject$selectKeyLoader$zh selectKeyLoader = Translations$Form$paramsInject$selectKeyLoader$zh.internal(_root);
}

// Path: cpds.stages
class Translations$cpds$stages$zh {
	Translations$cpds$stages$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '发现'
	String get discovery => '发现';

	/// zh: '认证'
	String get authentication => '认证';

	/// zh: '传输'
	String get transfer => '传输';

	/// zh: '解析'
	String get parse => '解析';

	/// zh: '完成'
	String get complete => '完成';
}

// Path: cpds.statuses
class Translations$cpds$statuses$zh {
	Translations$cpds$statuses$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '未开始'
	String get pending => '未开始';

	/// zh: '已发现'
	String get discovered => '已发现';

	/// zh: '已认证'
	String get authenticated => '已认证';

	/// zh: '接收中'
	String get receiving => '接收中';

	/// zh: '等待解析结果'
	String get waitingParse => '等待解析结果';

	/// zh: '已完成'
	String get completed => '已完成';

	/// zh: '失败'
	String get failed => '失败';

	/// zh: '已忽略'
	String get ignored => '已忽略';
}

// Path: cpds.device
class Translations$cpds$device$zh {
	Translations$cpds$device$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'ESN'
	String get esn => 'ESN';

	/// zh: '当前 IP'
	String get ip => '当前 IP';

	/// zh: '--'
	String get emptyValue => '--';
}

// Path: cpds.deviceTypes
class Translations$cpds$deviceTypes$zh {
	Translations$cpds$deviceTypes$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'Server'
	String get server => 'Server';

	/// zh: 'HF'
	String get hf => 'HF';

	/// zh: 'MMR200'
	String get multiBandRadio => 'MMR200';

	/// zh: 'PMR200'
	String get multiBandHandheld => 'PMR200';

	/// zh: 'CCU-Main'
	String get ccu => 'CCU-Main';

	/// zh: 'CCU-Audio'
	String get ccuAudio => 'CCU-Audio';

	/// zh: 'CCU'
	String get ccuGroup => 'CCU';

	/// zh: 'IEC'
	String get iec => 'IEC';

	/// zh: 'Small Handheld'
	String get smallHandheld => 'Small Handheld';

	/// zh: '未知设备'
	String get unknown => '未知设备';
}

// Path: cpds.saveDialog
class Translations$cpds$saveDialog$zh {
	Translations$cpds$saveDialog$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '名称'
	String get nameLabel => '名称';

	/// zh: '请输入名称'
	String get nameHint => '请输入名称';

	/// zh: '请输入名称'
	String get nameRequired => '请输入名称';

	/// zh: '名称包含非法字符'
	String get nameInvalid => '名称包含非法字符';

	/// zh: '请选择'
	String get selectPlaceholder => '请选择';
}

// Path: cpds.setPassword
class Translations$cpds$setPassword$zh {
	Translations$cpds$setPassword$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '设置密码'
	String get title => '设置密码';

	/// zh: '密码'
	String get label => '密码';

	/// zh: '输入密码'
	String get placeholder => '输入密码';

	/// zh: '请输入密码'
	String get required => '请输入密码';

	/// zh: '密码长度至少6位'
	String get minLength => '密码长度至少6位';

	/// zh: '密码长度不能超过20位'
	String get maxLength => '密码长度不能超过20位';

	/// zh: '密码包含非法字符'
	String get invalid => '密码包含非法字符';

	/// zh: '密码不能包含中文'
	String get noChinese => '密码不能包含中文';
}

// Path: cpds.export
class Translations$cpds$export$zh {
	Translations$cpds$export$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '【{path}】找不到 ZIP 包'
	String zipNotFound({required Object path}) => '【${path}】找不到 ZIP 包';

	/// zh: '【{path}】找不到'
	String fileNotFound({required Object path}) => '【${path}】找不到';

	/// zh: '【导出失败】{error}'
	String failed({required Object error}) => '【导出失败】${error}';

	/// zh: '勾选的行中存在未选择配对电台，请先选择'
	String get radioRequired => '勾选的行中存在未选择配对电台，请先选择';
}

// Path: pager.injectParams.steps
class Translations$pager$injectParams$steps$zh {
	Translations$pager$injectParams$steps$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '发现'
	String get discovery => '发现';

	/// zh: '认证'
	String get authentication => '认证';

	/// zh: '传输'
	String get transfer => '传输';

	/// zh: '解析'
	String get parse => '解析';

	/// zh: '完成'
	String get finish => '完成';
}

// Path: Form.radioManager.alias
class Translations$Form$radioManager$alias$zh {
	Translations$Form$radioManager$alias$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请输入电台别名'
	String get placeholder => '请输入电台别名';

	/// zh: '电台别名不可为空'
	String get validate => '电台别名不可为空';

	/// zh: '仅允许输入中英文字符和数字'
	String get invalid => '仅允许输入中英文字符和数字';
}

// Path: Form.radioManager.sn
class Translations$Form$radioManager$sn$zh {
	Translations$Form$radioManager$sn$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请输入电台SN号'
	String get placeholder => '请输入电台SN号';

	/// zh: '电台SN号不可为空'
	String get validate => '电台SN号不可为空';

	/// zh: '仅允许输入中英文字符和数字'
	String get invalid => '仅允许输入中英文字符和数字';

	/// zh: 'SN不可超过50个字符'
	String get maxLength => 'SN不可超过50个字符';
}

// Path: Form.radioManager.location
class Translations$Form$radioManager$location$zh {
	Translations$Form$radioManager$location$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请输入电台位置'
	String get placeholder => '请输入电台位置';

	/// zh: '电台位置不可为空'
	String get validate => '电台位置不可为空';
}

// Path: Form.radioManager.consumer
class Translations$Form$radioManager$consumer$zh {
	Translations$Form$radioManager$consumer$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请输入电台使用人'
	String get placeholder => '请输入电台使用人';

	/// zh: '电台使用人不可为空'
	String get validate => '电台使用人不可为空';

	/// zh: '仅允许输入中英文字符和数字'
	String get invalid => '仅允许输入中英文字符和数字';

	/// zh: '使用人不可超过8个字符'
	String get maxLength => '使用人不可超过8个字符';
}

// Path: Form.injectEncrypt.name
class Translations$Form$injectEncrypt$name$zh {
	Translations$Form$injectEncrypt$name$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '名称'
	String get label => '名称';

	/// zh: '请输入注钥名称'
	String get placeholder => '请输入注钥名称';

	/// zh: '请输入注钥名称'
	String get validate => '请输入注钥名称';
}

// Path: Form.paramsInject.deviceType
class Translations$Form$paramsInject$deviceType$zh {
	Translations$Form$paramsInject$deviceType$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '设备类型'
	String get text => '设备类型';

	/// zh: '请输入设备类型'
	String get validatorText => '请输入设备类型';
}

// Path: Form.paramsInject.deviceIp
class Translations$Form$paramsInject$deviceIp$zh {
	Translations$Form$paramsInject$deviceIp$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '设备IP'
	String get text => '设备IP';

	/// zh: '请输入有效的IP地址'
	String get validatorText => '请输入有效的IP地址';
}

// Path: Form.paramsInject.selectKeyLoader
class Translations$Form$paramsInject$selectKeyLoader$zh {
	Translations$Form$paramsInject$selectKeyLoader$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '注钥枪'
	String get text => '注钥枪';

	/// zh: '请选择'
	String get placeholder => '请选择';
}
