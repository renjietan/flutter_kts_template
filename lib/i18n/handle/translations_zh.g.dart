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
	late final Translations$json$zh json = Translations$json$zh.internal(_root);
	late final Translations$pageable$zh pageable = Translations$pageable$zh.internal(_root);
	late final Translations$pager$zh pager = Translations$pager$zh.internal(_root);
	late final Translations$tableColumn$zh tableColumn = Translations$tableColumn$zh.internal(_root);
	late final Translations$button$zh button = Translations$button$zh.internal(_root);
	late final Translations$checkbox$zh checkbox = Translations$checkbox$zh.internal(_root);
	late final Translations$TextField$zh TextField = Translations$TextField$zh.internal(_root);
	late final Translations$Form$zh Form = Translations$Form$zh.internal(_root);
	late final Translations$errorMiddle$zh errorMiddle = Translations$errorMiddle$zh.internal(_root);
	late final Translations$platform$zh platform = Translations$platform$zh.internal(_root);
	late final Translations$settings$zh settings = Translations$settings$zh.internal(_root);
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
	late final Translations$pager$radioManager$zh radioManager = Translations$pager$radioManager$zh.internal(_root);
	late final Translations$pager$injectEncrypt$zh injectEncrypt = Translations$pager$injectEncrypt$zh.internal(_root);
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

// Path: Form.radioManager.alias
class Translations$Form$radioManager$alias$zh {
	Translations$Form$radioManager$alias$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '请输入电台别名'
	String get placeholder => '请输入电台别名';

	/// zh: '电台别名不可为空'
	String get validate => '电台别名不可为空';
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
