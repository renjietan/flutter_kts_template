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
	late final Translations$errorMiddle$zh errorMiddle = Translations$errorMiddle$zh.internal(_root);
	late final Translations$platform$zh platform = Translations$platform$zh.internal(_root);
	late final Translations$home$zh home = Translations$home$zh.internal(_root);
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

	/// zh: '网络连接失败，请检查网络,'
	String get requestConnectionError => '网络连接失败，请检查网络,';

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

// Path: home
class Translations$home$zh {
	Translations$home$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '首页'
	String get title => '首页';

	/// zh: '欢迎回来，{name}！'
	String greeting({required Object name}) => '欢迎回来，${name}！';

	/// zh: '上次登录时间：{date}'
	String lastLogin({required Object date}) => '上次登录时间：${date}';
}

// Path: settings
class Translations$settings$zh {
	Translations$settings$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '设置'
	String get title => '设置';

	/// zh: '语言'
	String get language => '语言';

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
