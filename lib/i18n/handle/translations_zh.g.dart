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
	late final Translations$usb$zh usb = Translations$usb$zh.internal(_root);
	late final Translations$udp$zh udp = Translations$udp$zh.internal(_root);
	late final Translations$errorMiddle$zh errorMiddle = Translations$errorMiddle$zh.internal(_root);
	late final Translations$platform$zh platform = Translations$platform$zh.internal(_root);
	late final Translations$layout$zh layout = Translations$layout$zh.internal(_root);
	late final Translations$settings$zh settings = Translations$settings$zh.internal(_root);
	late final Translations$cpds$zh cpds = Translations$cpds$zh.internal(_root);
	late final Translations$selfUpdate$zh selfUpdate = Translations$selfUpdate$zh.internal(_root);
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

	/// zh: '关闭'
	String get close => '关闭';

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

	/// zh: '新增成功'
	String get addSuccess => '新增成功';

	/// zh: '请选择'
	String get pleaseSelect => '请选择';

	/// zh: '保存成功'
	String get saveSuccess => '保存成功';
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

	/// zh: '未来士兵'
	String get futureWarrior => '未来士兵';
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

// Path: usb
class Translations$usb$zh {
	Translations$usb$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'USB 设备插入: {address}'
	String deviceInserted({required Object address}) => 'USB 设备插入: ${address}';

	/// zh: 'USB 设备拔出: {address}'
	String deviceRemoved({required Object address}) => 'USB 设备拔出: ${address}';

	/// zh: '未找到 USB 设备: {address}'
	String deviceNotFound({required Object address}) => '未找到 USB 设备: ${address}';

	/// zh: '创建 USB 端口失败'
	String get createPortFailed => '创建 USB 端口失败';

	/// zh: '打开 USB 端口失败'
	String get openPortFailed => '打开 USB 端口失败';

	/// zh: 'USB 设备连接成功'
	String get deviceConnected => 'USB 设备连接成功';

	/// zh: '无可用的 USB 连接'
	String get noAvailableConnection => '无可用的 USB 连接';

	/// zh: '未找到 WinUSB 设备'
	String get winUsbNotFound => '未找到 WinUSB 设备';

	/// zh: '端点未找到: {epOut} {epIn}'
	String endpointNotFound({required Object epOut, required Object epIn}) => '端点未找到: ${epOut} ${epIn}';

	/// zh: 'WinUSB 设备连接成功'
	String get winUsbConnected => 'WinUSB 设备连接成功';

	/// zh: 'WinUSB 设备已断开'
	String get winUsbDisconnected => 'WinUSB 设备已断开';

	/// zh: 'WinUSB 未连接'
	String get winUsbNotConnected => 'WinUSB 未连接';

	/// zh: '无可用的 WinUSB 连接'
	String get noWinUsbConnection => '无可用的 WinUSB 连接';

	/// zh: '无可用的 OUT 管道'
	String get noOutPipe => '无可用的 OUT 管道';
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

// Path: layout
class Translations$layout$zh {
	Translations$layout$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '设置'
	String get settings => '设置';

	/// zh: '清除临时文件'
	String get clearTempFiles => '清除临时文件';

	/// zh: '清除缓存'
	String get clearCache => '清除缓存';

	/// zh: '确认退出'
	String get confirmExit => '确认退出';

	/// zh: '您确定要离开此页面吗？'
	String get leavePagePrompt => '您确定要离开此页面吗？';
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

	/// zh: '阿拉伯语（东）'
	String get arEg => '阿拉伯语（东）';

	/// zh: '阿拉伯语（西）'
	String get arMa => '阿拉伯语（西）';
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

	/// zh: '立即前往'
	String get goNow => '立即前往';

	/// zh: '解析'
	String get parse => '解析';

	/// zh: '请选择通信参数包'
	String get filePlaceholder => '请选择通信参数包';

	/// zh: '缺少通信参数包文件'
	String get packageFileMissing => '缺少通信参数包文件';

	/// zh: '文件字节为空'
	String get fileBytesEmpty => '文件字节为空';

	/// zh: '重新上传文件，将清除注钥枪绑定的通信参数包，确认是否继续？'
	String get browseConfirm => '重新上传文件，将清除注钥枪绑定的通信参数包，确认是否继续？';

	/// zh: '选择文件来源'
	String get browseSourceTitle => '选择文件来源';

	/// zh: '本地文件列表'
	String get browseSourceLocal => '本地文件列表';

	/// zh: '注钥枪文件列表'
	String get browseSourceKeyLoader => '注钥枪文件列表';

	/// zh: '未授予 USB 权限'
	String get keyLoaderPermissionDenied => '未授予 USB 权限';

	/// zh: '注钥枪连接成功'
	String get keyLoaderConnectSuccess => '注钥枪连接成功';

	/// zh: '注钥枪连接失败'
	String get keyLoaderConnectFailed => '注钥枪连接失败';

	/// zh: '连接注钥枪'
	String get keyLoaderStepConnect => '连接注钥枪';

	/// zh: '获取文件列表'
	String get keyLoaderStepList => '获取文件列表';

	/// zh: '文件选择'
	String get keyLoaderStepSelect => '文件选择';

	/// zh: '文件已选择'
	String get keyLoaderStepSelected => '文件已选择';

	/// zh: '暂无文件'
	String get keyLoaderListEmpty => '暂无文件';

	/// zh: '获取文件列表失败'
	String get keyLoaderListError => '获取文件列表失败';

	/// zh: '获取文件列表超时'
	String get keyLoaderListTimeout => '获取文件列表超时';

	/// zh: '密码校验'
	String get keyLoaderStepPassword => '密码校验';

	/// zh: '下载'
	String get keyLoaderStepDownload => '下载';

	/// zh: '就绪'
	String get keyLoaderStepReady => '就绪';

	/// zh: '完成'
	String get keyLoaderStepComplete => '完成';

	/// zh: '下一步'
	String get keyLoaderNext => '下一步';

	/// zh: '上一步'
	String get keyLoaderPrev => '上一步';

	/// zh: '已超时'
	String get keyLoaderDecryptTimeout => '已超时';

	/// zh: '校验失败'
	String get keyLoaderDecryptFail => '校验失败';

	/// zh: '密码错误，还剩下{n}次机会'
	String keyLoaderDecryptFailRemaining({required Object n}) => '密码错误，还剩下${n}次机会';

	/// zh: '密码多次错误，已毁钥'
	String get keyLoaderDecryptCleared => '密码多次错误，已毁钥';

	/// zh: '文件已损坏'
	String get keyLoaderDecryptErr => '文件已损坏';

	/// zh: '解密'
	String get keyLoaderStepDecrypt => '解密';

	/// zh: '解析'
	String get keyLoaderStepParse => '解析';

	/// zh: '文件不完整，已损坏'
	String get keyLoaderFileCorrupted => '文件不完整，已损坏';

	/// zh: '文件接收超时，重新插拔注钥枪'
	String get keyLoaderDownloadTimeout => '文件接收超时，重新插拔注钥枪';

	/// zh: 'USB 设备已断开'
	String get keyLoaderDeviceRemoved => 'USB 设备已断开';

	/// zh: '解密失败'
	String get keyLoaderDecryptFailed => '解密失败';

	/// zh: '下载完成'
	String get keyLoaderSuccess => '下载完成';

	/// zh: '响应超时'
	String get keyLoaderReadyTimeout => '响应超时';

	/// zh: '失败：校验失败'
	String get keyLoaderVerifyFailed => '失败：校验失败';

	/// zh: '文件不存在'
	String get keyLoaderFileNotFound => '文件不存在';

	/// zh: '接收到异常指令'
	String get keyLoaderUnexpectedReply => '接收到异常指令';

	/// zh: '解析成功'
	String get keyLoaderParseSuccess => '解析成功';

	/// zh: '解析失败'
	String get keyLoaderParseFailed => '解析失败';

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

	/// zh: '请选择网卡'
	String get networkInterfacePlaceholder => '请选择网卡';

	/// zh: '{name} · {ip}（{type}）'
	String networkInterfaceOption({required Object name, required Object ip, required Object type}) => '${name} · ${ip}（${type}）';

	/// zh: '有线'
	String get networkInterfaceWired => '有线';

	/// zh: '无线'
	String get networkInterfaceWireless => '无线';

	/// zh: '无网络'
	String get networkInterfaceNoLink => '无网络';

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
	late final Translations$cpds$exportProgress$zh exportProgress = Translations$cpds$exportProgress$zh.internal(_root);
	/// zh: '注钥枪版本号：'
	String get versionLabel => '注钥枪版本号：';
	late final Translations$cpds$usbProgress$zh usbProgress = Translations$cpds$usbProgress$zh.internal(_root);
}

// Path: selfUpdate
class Translations$selfUpdate$zh {
	Translations$selfUpdate$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请先选择网卡'
	String get selectInterfaceFirst => '请先选择网卡';

	/// zh: '认证失败：设备认证数量为 {n}'
	String authFailedCount({required Object n}) => '认证失败：设备认证数量为 ${n}';

	/// zh: '版本校验失败：设备回复数量为 {n}'
	String versionFailedCount({required Object n}) => '版本校验失败：设备回复数量为 ${n}';

	/// zh: '校验失败：{fail} 台失败，{timeout} 台超时'
	String validFailedSummary({required Object fail, required Object timeout}) => '校验失败：${fail} 台失败，${timeout} 台超时';

	/// zh: '写入失败：{fail} 台失败，{timeout} 台超时'
	String writeFailedSummary({required Object fail, required Object timeout}) => '写入失败：${fail} 台失败，${timeout} 台超时';

	/// zh: '更新完成：成功 {success} 台，失败 {fail} 台，超时 {timeout} 台'
	String updateCompletedSummary({required Object success, required Object fail, required Object timeout}) => '更新完成：成功 ${success} 台，失败 ${fail} 台，超时 ${timeout} 台';

	/// zh: '重新校验'
	String get revalidate => '重新校验';

	/// zh: '重新写入'
	String get rewrite => '重新写入';

	/// zh: '未找到匹配的安装包'
	String get packageNotFound => '未找到匹配的安装包';

	/// zh: '传输前置指令超时'
	String get transferFileTimeout => '传输前置指令超时';

	/// zh: '传输分包超时'
	String get transferPacketTimeout => '传输分包超时';

	/// zh: '文件上传'
	String get fileUpload => '文件上传';

	/// zh: '暂无数据'
	String get emptyData => '暂无数据';

	/// zh: '版本号'
	String get version => '版本号';

	/// zh: '文件名称'
	String get fileName => '文件名称';

	/// zh: '备注'
	String get remark => '备注';

	/// zh: '创建时间'
	String get createdAt => '创建时间';

	/// zh: '操作'
	String get action => '操作';

	/// zh: '编辑'
	String get edit => '编辑';

	/// zh: '更新到设备'
	String get updateToDevice => '更新到设备';

	/// zh: '删除'
	String get delete => '删除';

	/// zh: '删除提示'
	String get deleteTitle => '删除提示';

	/// zh: '确认删除【{version}】吗？'
	String deleteConfirm({required Object version}) => '确认删除【${version}】吗？';

	/// zh: '取消'
	String get cancel => '取消';

	/// zh: '确认'
	String get confirm => '确认';

	/// zh: '提示'
	String get prompt => '提示';

	/// zh: '安装包不存在，是否立刻删除数据'
	String get packageMissing => '安装包不存在，是否立刻删除数据';

	/// zh: '确定'
	String get ok => '确定';

	/// zh: '未扫描到设备'
	String get noDevices => '未扫描到设备';

	/// zh: '没有需要更新的设备'
	String get noDevicesNeedUpdate => '没有需要更新的设备';

	/// zh: '第 {page} / {pageCount} 页 · 共 {total} 条'
	String pagination({required Object page, required Object pageCount, required Object total}) => '第 ${page} / ${pageCount} 页 · 共 ${total} 条';

	/// zh: '上传安装包'
	String get uploadTitle => '上传安装包';

	/// zh: '0.1.1.1'
	String get versionHint => '0.1.1.1';

	/// zh: '备注（选填）'
	String get remarkOptional => '备注（选填）';

	/// zh: '请输入备注'
	String get remarkHint => '请输入备注';

	/// zh: '安装包'
	String get packageLabel => '安装包';

	/// zh: '请选择 ZIP 安装包'
	String get packageHint => '请选择 ZIP 安装包';

	/// zh: '上传'
	String get upload => '上传';

	/// zh: '请输入版本号'
	String get versionRequired => '请输入版本号';

	/// zh: '格式应为 0.1.1.1'
	String get versionFormat => '格式应为 0.1.1.1';

	/// zh: '请先上传安装包'
	String get packageRequired => '请先上传安装包';

	/// zh: '编辑安装包'
	String get editTitle => '编辑安装包';

	/// zh: '扫描设备'
	String get scanTitle => '扫描设备';

	/// zh: '扫描中....'
	String get scanning => '扫描中....';

	/// zh: '已扫描到 {n} 个设备'
	String scannedCount({required Object n}) => '已扫描到 ${n} 个设备';

	/// zh: '剩余 {n} 秒'
	String remainingSeconds({required Object n}) => '剩余 ${n} 秒';

	/// zh: '下一步'
	String get next => '下一步';

	/// zh: '发现'
	String get stepDiscovery => '发现';

	/// zh: '认证'
	String get stepAuth => '认证';

	/// zh: '版本校验'
	String get stepVersion => '版本校验';

	/// zh: '传输'
	String get stepTransfer => '传输';

	/// zh: '校验'
	String get stepValidation => '校验';

	/// zh: '写入'
	String get stepWrite => '写入';

	/// zh: '回执'
	String get stepReceipt => '回执';

	/// zh: '正在扫描网络中的 CPDC 设备…'
	String get descDiscovery => '正在扫描网络中的 CPDC 设备…';

	/// zh: '正在对设备进行认证…'
	String get descAuth => '正在对设备进行认证…';

	/// zh: '正在比对设备当前版本与目标版本…'
	String get descVersion => '正在比对设备当前版本与目标版本…';

	/// zh: '正在向认证成功的设备分发安装包…'
	String get descTransfer => '正在向认证成功的设备分发安装包…';

	/// zh: '设备正在校验安装包完整性…'
	String get descValidation => '设备正在校验安装包完整性…';

	/// zh: '设备正在替换程序并写入配置…'
	String get descWrite => '设备正在替换程序并写入配置…';

	/// zh: '等待设备回传更新结果…'
	String get descReceipt => '等待设备回传更新结果…';

	/// zh: 'IP 地址'
	String get colIp => 'IP 地址';

	/// zh: '类型'
	String get colType => '类型';

	/// zh: '当前版本'
	String get colCurrentVersion => '当前版本';

	/// zh: '新版本'
	String get colNewVersion => '新版本';

	/// zh: '状态'
	String get colStatus => '状态';

	/// zh: '进度'
	String get colProgress => '进度';

	/// zh: '结果'
	String get colResult => '结果';

	/// zh: '开始'
	String get start => '开始';

	/// zh: '暂停'
	String get pause => '暂停';

	/// zh: '继续'
	String get resume => '继续';

	/// zh: '关闭'
	String get close => '关闭';

	/// zh: '重新认证'
	String get reAuth => '重新认证';

	/// zh: '重新版本校验'
	String get reVersion => '重新版本校验';

	/// zh: '认证成功'
	String get authSuccess => '认证成功';

	/// zh: '认证失败'
	String get authFailedStatus => '认证失败';

	/// zh: '认证超时'
	String get authTimeout => '认证超时';

	/// zh: '已最新'
	String get latest => '已最新';

	/// zh: '需更新'
	String get needsUpdate => '需更新';

	/// zh: '无法获取'
	String get unableToFetch => '无法获取';

	/// zh: '版本校验失败'
	String get versionFailedStatus => '版本校验失败';

	/// zh: '版本校验超时'
	String get versionTimeout => '版本校验超时';

	/// zh: '校验通过'
	String get validationPassed => '校验通过';

	/// zh: '校验失败'
	String get validationFailedStatus => '校验失败';

	/// zh: '校验超时'
	String get validationTimeout => '校验超时';

	/// zh: '写入成功'
	String get writeSuccess => '写入成功';

	/// zh: '写入失败'
	String get writeFailedStatus => '写入失败';

	/// zh: '写入超时'
	String get writeTimeout => '写入超时';

	/// zh: '写入中'
	String get writeWriting => '写入中';

	/// zh: '更新成功'
	String get updateSuccess => '更新成功';

	/// zh: '回执失败'
	String get receiptFailedStatus => '回执失败';

	/// zh: '回执超时'
	String get receiptTimeout => '回执超时';

	/// zh: '传输失败'
	String get transferFailedStatus => '传输失败';

	/// zh: '传输超时'
	String get transferTimeout => '传输超时';

	/// zh: '传输中'
	String get transferring => '传输中';

	/// zh: '传输完成'
	String get transferDone => '传输完成';

	late final Translations$selfUpdate$failReason$zh failReason = Translations$selfUpdate$failReason$zh.internal(_root);
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

	/// zh: '更新CPDC'
	String get updateCpdc => '更新CPDC';
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

	/// zh: '当前无可选的电台, 请前往添加后再试'
	String get noRadio => '当前无可选的电台, 请前往添加后再试';

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

	/// zh: '电台类型'
	String get radioType => '电台类型';

	/// zh: '电台类型'
	String get radioType_desc => '电台类型';

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

	/// zh: '编辑电台'
	String get editRadio => '编辑电台';

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

	/// zh: '新增'
	String get create => '新增';

	/// zh: '添加注钥枪'
	String get createKeyLoader => '添加注钥枪';
}

// Path: Form.radioManager
class Translations$Form$radioManager$zh {
	Translations$Form$radioManager$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$Form$radioManager$alias$zh alias = Translations$Form$radioManager$alias$zh.internal(_root);
	late final Translations$Form$radioManager$sn$zh sn = Translations$Form$radioManager$sn$zh.internal(_root);
	late final Translations$Form$radioManager$location$zh location = Translations$Form$radioManager$location$zh.internal(_root);
	late final Translations$Form$radioManager$radioType$zh radioType = Translations$Form$radioManager$radioType$zh.internal(_root);
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

	/// zh: '下发IP(down)'
	String get downCurrentIp => '下发IP(down)';

	/// zh: '下发IP(down1)'
	String get downCurrentIp1 => '下发IP(down1)';

	/// zh: '下发IP(down2)'
	String get downCurrentIp2 => '下发IP(down2)';

	/// zh: '子网IP'
	String get subnetIp => '子网IP';

	/// zh: '--'
	String get emptyValue => '--';
}

// Path: cpds.deviceTypes
class Translations$cpds$deviceTypes$zh {
	Translations$cpds$deviceTypes$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: 'TEDS'
	String get teds => 'TEDS';

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

	/// zh: 'VehInter'
	String get vehInter => 'VehInter';

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

	/// zh: '密码长度至少8位'
	String get minLength => '密码长度至少8位';

	/// zh: '密码长度不能超过20位'
	String get maxLength => '密码长度不能超过20位';

	/// zh: '只允许输入八位数字'
	String get invalid => '只允许输入八位数字';

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

	/// zh: '请先勾选需要导出的行'
	String get noSelection => '请先勾选需要导出的行';
}

// Path: cpds.exportProgress
class Translations$cpds$exportProgress$zh {
	Translations$cpds$exportProgress$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '开始'
	String get stepStart => '开始';

	/// zh: '打包'
	String get stepPack => '打包';

	/// zh: '整合'
	String get stepMerge => '整合';

	/// zh: '加密'
	String get stepEncrypt => '加密';

	/// zh: '开始'
	String get detailStart => '开始';

	/// zh: '开始压缩为 tar 包'
	String get detailStartPack => '开始压缩为 tar 包';

	/// zh: '第 {index} 个压缩包打包成功'
	String detailPackSuccess({required Object index}) => '第 ${index} 个压缩包打包成功';

	/// zh: '第 {index} 个压缩包打包失败'
	String detailPackFail({required Object index}) => '第 ${index} 个压缩包打包失败';

	/// zh: '开始整合，将多个压缩包合并为 ZIP 包'
	String get detailMerge => '开始整合，将多个压缩包合并为 ZIP 包';

	/// zh: '对 ZIP 包进行加密'
	String get detailEncrypt => '对 ZIP 包进行加密';
}

// Path: cpds.usbProgress
class Translations$cpds$usbProgress$zh {
	Translations$cpds$usbProgress$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '权限'
	String get stepPermission => '权限';

	/// zh: '连接'
	String get stepConnect => '连接';

	/// zh: '握手'
	String get stepHandshake => '握手';

	/// zh: '准备'
	String get stepReady => '准备';

	/// zh: '传输'
	String get stepTransfer => '传输';

	/// zh: '完成'
	String get stepComplete => '完成';

	/// zh: '注钥枪'
	String get stepUsb => '注钥枪';

	/// zh: '已完成'
	String get completed => '已完成';

	/// zh: '已终止'
	String get terminated => '已终止';

	/// zh: '检查 USB 权限'
	String get detailPermissionStart => '检查 USB 权限';

	/// zh: '连接注钥枪'
	String get detailConnectStart => '连接注钥枪';

	/// zh: '连接成功'
	String get detailConnectSuccess => '连接成功';

	/// zh: '连接失败'
	String get detailConnectFail => '连接失败';

	/// zh: '发送 LIGHT_GREEN，等待 FILE_OK'
	String get detailHandshakeStart => '发送 LIGHT_GREEN，等待 FILE_OK';

	/// zh: '握手成功'
	String get detailHandshakeSuccess => '握手成功';

	/// zh: '握手超时'
	String get detailHandshakeTimeout => '握手超时';

	/// zh: '握手失败'
	String get detailHandshakeFail => '握手失败';

	/// zh: '发送 GET_VERSION，等待版本号'
	String get detailVersionStart => '发送 GET_VERSION，等待版本号';

	/// zh: '获取版本成功'
	String get detailVersionSuccess => '获取版本成功';

	/// zh: '获取版本超时'
	String get detailVersionTimeout => '获取版本超时';

	/// zh: '获取版本失败'
	String get detailVersionFail => '获取版本失败';

	/// zh: '发送 FILE_CPD_CLEAR，等待 FILE_OK'
	String get detailClearStart => '发送 FILE_CPD_CLEAR，等待 FILE_OK';

	/// zh: '清空完成'
	String get detailClearSuccess => '清空完成';

	/// zh: '清空超时'
	String get detailClearTimeout => '清空超时';

	/// zh: '发送 FILE_UPLOAD，等待 READY'
	String get detailReadyStart => '发送 FILE_UPLOAD，等待 READY';

	/// zh: '设备已就绪'
	String get detailReadySuccess => '设备已就绪';

	/// zh: '准备超时'
	String get detailReadyTimeout => '准备超时';

	/// zh: '准备失败'
	String get detailReadyFail => '准备失败';

	/// zh: '发送 LIGHT_GREEN_BLINK，等待 FILE_OK'
	String get detailBlinkStart => '发送 LIGHT_GREEN_BLINK，等待 FILE_OK';

	/// zh: '指示灯已闪烁'
	String get detailBlinkSuccess => '指示灯已闪烁';

	/// zh: '指示灯闪烁超时'
	String get detailBlinkTimeout => '指示灯闪烁超时';

	/// zh: '发送 LIGHT_GREEN，等待 FILE_OK'
	String get detailGreenStart => '发送 LIGHT_GREEN，等待 FILE_OK';

	/// zh: '指示灯已常亮'
	String get detailGreenSuccess => '指示灯已常亮';

	/// zh: '指示灯常亮超时'
	String get detailGreenTimeout => '指示灯常亮超时';

	/// zh: '分包发送'
	String get detailTransferStart => '分包发送';

	/// zh: '文件接收超时，重新插拔注钥枪'
	String get detailTransferTimeout => '文件接收超时，重新插拔注钥枪';

	/// zh: '注钥枪接收成功'
	String get detailComplete => '注钥枪接收成功';

	/// zh: '校验超时'
	String get detailVerifyTimeout => '校验超时';

	/// zh: '校验失败'
	String get detailVerifyFail => '校验失败';

	/// zh: '写入失败'
	String get detailVerifySaveFail => '写入失败';

	/// zh: '完成：文件已导出'
	String get detailExportComplete => '完成：文件已导出';

	/// zh: '第 {index} 包 发送成功'
	String detailPacketSuccess({required Object index}) => '第 ${index} 包 发送成功';

	/// zh: '第 {index} 包 发送失败'
	String detailPacketFail({required Object index}) => '第 ${index} 包 发送失败';

	/// zh: '第 {index} 包 发送超时'
	String detailPacketTimeout({required Object index}) => '第 ${index} 包 发送超时';

	/// zh: '第 {index} 包 MD5 校验失败'
	String detailMd5Error({required Object index}) => '第 ${index} 包 MD5 校验失败';

	/// zh: '第 {index} 包 保存失败'
	String detailSaveError({required Object index}) => '第 ${index} 包 保存失败';

	/// zh: 'USB 传输异常'
	String get detailError => 'USB 传输异常';

	/// zh: 'USB 设备已断开'
	String get detailDeviceRemoved => 'USB 设备已断开';

	/// zh: '接收到异常指令'
	String get detailUnexpectedReply => '接收到异常指令';

	/// zh: '注钥成功'
	String get detailKeyLoadSuccess => '注钥成功';
}

// Path: selfUpdate.failReason
class Translations$selfUpdate$failReason$zh {
	Translations$selfUpdate$failReason$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '版本号格式非法'
	String get format => '版本号格式非法';

	/// zh: '分包长度错误'
	String get length => '分包长度错误';

	/// zh: '校验失败（CRC）'
	String get crc => '校验失败（CRC）';

	/// zh: '分包顺序错误，缺少第 {n} 包'
	String sequence({required Object n}) => '分包顺序错误，缺少第 ${n} 包';

	/// zh: '未收到文件头'
	String get noHeader => '未收到文件头';

	/// zh: '缺少分包'
	String get missingPacket => '缺少分包';

	/// zh: '文件大小不符'
	String get size => '文件大小不符';

	/// zh: '解压失败'
	String get zip => '解压失败';

	/// zh: '版本不匹配'
	String get versionMismatch => '版本不匹配';

	/// zh: '解压 ZIP 失败'
	String get unzipFail => '解压 ZIP 失败';

	/// zh: '找不到设备类型文件夹'
	String get typeDirNotFound => '找不到设备类型文件夹';

	/// zh: '找不到安装文件'
	String get installFileNotFound => '找不到安装文件';

	/// zh: '存在多个安装文件'
	String get installFileMultiple => '存在多个安装文件';

	/// zh: '读取配置失败'
	String get readConfigFail => '读取配置失败';

	/// zh: '获取运行程序路径失败'
	String get executablePathFail => '获取运行程序路径失败';

	/// zh: '覆盖二进制：打开源文件失败'
	String get overwriteBinaryOpenFail => '覆盖二进制：打开源文件失败';

	/// zh: '覆盖二进制：写临时文件失败'
	String get overwriteBinaryTempFail => '覆盖二进制：写临时文件失败';

	/// zh: '覆盖二进制：改名替换失败'
	String get overwriteBinaryRenameFail => '覆盖二进制：改名替换失败';

	/// zh: '覆盖配置：打开源文件失败'
	String get overwriteConfigOpenFail => '覆盖配置：打开源文件失败';

	/// zh: '覆盖配置：写临时文件失败'
	String get overwriteConfigTempFail => '覆盖配置：写临时文件失败';

	/// zh: '覆盖配置：改名替换失败'
	String get overwriteConfigRenameFail => '覆盖配置：改名替换失败';

	/// zh: '覆盖 ini：打开源文件失败'
	String get overwriteIniOpenFail => '覆盖 ini：打开源文件失败';

	/// zh: '覆盖 ini：写临时文件失败'
	String get overwriteIniTempFail => '覆盖 ini：写临时文件失败';

	/// zh: '覆盖 ini：改名替换失败'
	String get overwriteIniRenameFail => '覆盖 ini：改名替换失败';

	/// zh: '写回执标记失败'
	String get writeMarkerFail => '写回执标记失败';

	/// zh: '回填版本失败'
	String get versionWriteFail => '回填版本失败';

	/// zh: '启动命令行为空'
	String get emptyCommand => '启动命令行为空';

	/// zh: '创建目录失败'
	String get mkdirFail => '创建目录失败';

	/// zh: '写重启脚本失败'
	String get writeScriptFail => '写重启脚本失败';

	/// zh: '文件头不匹配'
	String get mismatch => '文件头不匹配';

	/// zh: '安装/写盘失败'
	String get installError => '安装/写盘失败';

	/// zh: '重启失败'
	String get restartError => '重启失败';

	/// zh: '读取版本失败'
	String get versionReadError => '读取版本失败';

	/// zh: '启动脚本失败'
	String get restartSpawnFail => '启动脚本失败';

	/// zh: '替换可执行文件失败'
	String get finalizeFail => '替换可执行文件失败';

	/// zh: '启动替换器失败'
	String get finalizeStartFail => '启动替换器失败';

	/// zh: '替换器参数无效'
	String get finalizeInvalidParams => '替换器参数无效';

	/// zh: '等待旧进程退出超时'
	String get finalizeOldExitTimeout => '等待旧进程退出超时';

	/// zh: '终止旧进程失败'
	String get finalizeTerminateFail => '终止旧进程失败';

	/// zh: '重命名旧可执行文件失败'
	String get finalizeRenameOldFail => '重命名旧可执行文件失败';

	/// zh: '重命名新可执行文件失败'
	String get finalizeRenameNewFail => '重命名新可执行文件失败';

	/// zh: '打开新进程日志文件失败'
	String get finalizeOpenLogFail => '打开新进程日志文件失败';

	/// zh: '启动新进程失败'
	String get finalizeStartNewFail => '启动新进程失败';

	/// zh: '打开替换器日志文件失败'
	String get finalizeSelfLogFail => '打开替换器日志文件失败';

	/// zh: '写重启参数失败'
	String get writeParamsFail => '写重启参数失败';
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

	/// zh: '50个字符：英文字母、阿拉伯语、数字、半角标点及符号、空格'
	String get placeholder => '50个字符：英文字母、阿拉伯语、数字、半角标点及符号、空格';

	/// zh: '请输入电台别名'
	String get validate => '请输入电台别名';

	/// zh: '别名包含不支持的字符'
	String get invalid => '别名包含不支持的字符';

	/// zh: '别名长度不能超过50个字符'
	String get invalidLength => '别名长度不能超过50个字符';

	/// zh: '1、最多50个字符，可输入英文字母、阿拉伯语、数字、半角标点及符号、空格。 2、不能以空格或点结尾。 3、不能包含 \ / : * ? " < > |。 '
	String get help => '1、最多50个字符，可输入英文字母、阿拉伯语、数字、半角标点及符号、空格。\n2、不能以空格或点结尾。\n3、不能包含 \ / : * ? " < > |。\n';
}

// Path: Form.radioManager.sn
class Translations$Form$radioManager$sn$zh {
	Translations$Form$radioManager$sn$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '10位英文字母或数字'
	String get placeholder => '10位英文字母或数字';

	/// zh: '请输入SN号'
	String get validate => '请输入SN号';

	/// zh: 'SN必须为10位字母或数字'
	String get invalid => 'SN必须为10位字母或数字';
}

// Path: Form.radioManager.location
class Translations$Form$radioManager$location$zh {
	Translations$Form$radioManager$location$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '不超出50位的英文字母、数字、空格、符号"_"'
	String get placeholder => '不超出50位的英文字母、数字、空格、符号"_"';

	/// zh: '电台位置不可为空'
	String get validate => '电台位置不可为空';

	/// zh: '不超出50位的英文字母、数字、空格、符号"_"'
	String get invalid => '不超出50位的英文字母、数字、空格、符号"_"';
}

// Path: Form.radioManager.radioType
class Translations$Form$radioManager$radioType$zh {
	Translations$Form$radioManager$radioType$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请选择电台类型'
	String get validate => '请选择电台类型';
}

// Path: Form.radioManager.consumer
class Translations$Form$radioManager$consumer$zh {
	Translations$Form$radioManager$consumer$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '5-30位英文字母、数字、空格、符号"_"'
	String get placeholder => '5-30位英文字母、数字、空格、符号"_"';

	/// zh: '电台使用人不可为空'
	String get validate => '电台使用人不可为空';

	/// zh: '5-30位英文字母、数字、空格、符号"_"'
	String get invalid => '5-30位英文字母、数字、空格、符号"_"';
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
