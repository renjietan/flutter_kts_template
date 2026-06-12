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
}

// Path: common
class Translations$common$zh {
	Translations$common$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '你好'
	String get hello => '你好';

	/// zh: 'Welcome to {appName}'
	String welcome({required Object appName}) => 'Welcome to ${appName}';

	/// zh: '(zero) {空} (one) {1个} (other) {{count}个}'
	String itemCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		zero: '空',
		one: '1个',
		other: '${count}个',
	);

	late final Translations$common$gender$zh gender = Translations$common$gender$zh.internal(_root);
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

	/// zh: '主题'
	String get theme => '主题';

	/// zh: '深色模式'
	String get darkMode => '深色模式';

	/// zh: '中文'
	String get zh => '中文';

	/// zh: '英文'
	String get en => '英文';
}

// Path: common.gender
class Translations$common$gender$zh {
	Translations$common$gender$zh.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// zh: '他'
	String get male => '他';

	/// zh: '她'
	String get female => '她';

	/// zh: '他们'
	String get other => '他们';
}
