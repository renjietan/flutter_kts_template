///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$home$en home = _Translations$home$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$zh {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'My App';
}

// Path: common
class _Translations$common$en extends Translations$common$zh {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get hello => 'Hello';
	@override String welcome({required Object appName}) => 'Welcome to ${appName}';
	@override String itemCount({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'No items',
		one: '1 item',
		other: '${count} items',
	);
	@override late final _Translations$common$gender$en gender = _Translations$common$gender$en._(_root);
}

// Path: home
class _Translations$home$en extends Translations$home$zh {
	_Translations$home$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home';
	@override String greeting({required Object name}) => 'Welcome back, ${name}!';
	@override String lastLogin({required Object date}) => 'Last login: ${date}';
}

// Path: settings
class _Translations$settings$en extends Translations$settings$zh {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get language => 'Language';
	@override String get theme => 'Theme';
	@override String get darkMode => 'Dark Mode';
	@override String get zh => 'Chinese';
	@override String get en => 'English';
}

// Path: common.gender
class _Translations$common$gender$en extends Translations$common$gender$zh {
	_Translations$common$gender$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get male => 'He';
	@override String get female => 'She';
	@override String get other => 'They';
}
