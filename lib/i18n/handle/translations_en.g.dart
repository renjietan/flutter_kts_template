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
	@override late final _Translations$permission$en permission = _Translations$permission$en._(_root);
	@override late final _Translations$uploads$en uploads = _Translations$uploads$en._(_root);
	@override late final _Translations$json$en json = _Translations$json$en._(_root);
	@override late final _Translations$pageable$en pageable = _Translations$pageable$en._(_root);
	@override late final _Translations$errorMiddle$en errorMiddle = _Translations$errorMiddle$en._(_root);
	@override late final _Translations$platform$en platform = _Translations$platform$en._(_root);
	@override late final _Translations$home$en home = _Translations$home$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$zh {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'My App';
	@override late final _Translations$app$appbar$en appbar = _Translations$app$appbar$en._(_root);
}

// Path: common
class _Translations$common$en extends Translations$common$zh {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get confirm => 'Confirm';
	@override String get cancel => 'Cancel';
	@override String get noData => 'No data';
	@override String get OperationSuccess => 'Operation Successful';
	@override String get OperationError => 'Operation failed';
	@override String get requestError => 'Request failed';
	@override String get requestCancel => 'Request cancelled';
	@override String get requestTimeout => 'Timeout, retry later';
	@override String get requestConnectionError => 'Connection failed, check network';
	@override String get serverError => 'Server error';
	@override String get UnknowError => 'Unknown error';
}

// Path: permission
class _Translations$permission$en extends Translations$permission$zh {
	_Translations$permission$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get no => 'No permission, Go to settings now？';
	@override String get cancel => 'Operation has been cancelled';
}

// Path: uploads
class _Translations$uploads$en extends Translations$uploads$zh {
	_Translations$uploads$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get success => 'Upload successful';
	@override String successWithPath({required Object path}) => 'Upload successful; 路径：${path}!';
	@override String get cancel => 'Operation cancelled';
	@override String get failed => 'Upload failed';
	@override String get emptyPath => 'The file path is empty';
	@override String get emptyData => 'The file data is empty';
	@override String get existPath => 'The file path is not exist';
}

// Path: json
class _Translations$json$en extends Translations$json$zh {
	_Translations$json$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get serialization => 'The received information seems unfamiliar';
}

// Path: pageable
class _Translations$pageable$en extends Translations$pageable$zh {
	_Translations$pageable$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pageSizeMin => 'The page size must be greater than or equal to 1';
	@override String get pageSizeMax => 'The page size cannot exceed 100.';
	@override String get pageMin => 'The page must be greater than or equal to 1';
	@override String paramsValidateError({required Object errors}) => 'Parameter verification failed: ${errors}';
	@override String keywordValidateError({required Object count}) => 'Key words should not exceed ${count} characters';
}

// Path: errorMiddle
class _Translations$errorMiddle$en extends Translations$errorMiddle$zh {
	_Translations$errorMiddle$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get error500 => 'An unexpected error occurred. Please try again later';
	@override String errorArg({required Object error}) => 'Invalid argument,${error}';
}

// Path: platform
class _Translations$platform$en extends Translations$platform$zh {
	_Translations$platform$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get webNotReadFile => 'web 平台无法根据路径处理文件';
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
	@override String get zh => 'Chinese';
	@override String get en => 'English';
}

// Path: app.appbar
class _Translations$app$appbar$en extends Translations$app$appbar$zh {
	_Translations$app$appbar$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get paramsInject => 'Params inject';
	@override String get radioManager => 'Radio manager';
	@override String get keyManager => 'Key manager';
}
