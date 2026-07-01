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
	@override late final _Translations$pager$en pager = _Translations$pager$en._(_root);
	@override late final _Translations$tableColumn$en tableColumn = _Translations$tableColumn$en._(_root);
	@override late final _Translations$button$en button = _Translations$button$en._(_root);
	@override late final _Translations$checkbox$en checkbox = _Translations$checkbox$en._(_root);
	@override late final _Translations$TextField$en TextField = _Translations$TextField$en._(_root);
	@override late final _Translations$Form$en Form = _Translations$Form$en._(_root);
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
	@override String get connectionTimeout => 'Network connection timeout';
	@override String get sendTimeout => 'Send timeout';
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
	@override String get selectedFolderDialogTitle => 'Please select a folder';
	@override String get selectedAllow => 'Only ZIP and folders are supported';
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

// Path: pager
class _Translations$pager$en extends Translations$pager$zh {
	_Translations$pager$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$pager$radioManager$en radioManager = _Translations$pager$radioManager$en._(_root);
}

// Path: tableColumn
class _Translations$tableColumn$en extends Translations$tableColumn$zh {
	_Translations$tableColumn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$tableColumn$base$en base = _Translations$tableColumn$base$en._(_root);
	@override late final _Translations$tableColumn$radioManager$en radioManager = _Translations$tableColumn$radioManager$en._(_root);
}

// Path: button
class _Translations$button$en extends Translations$button$zh {
	_Translations$button$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$button$radioManager$en radioManager = _Translations$button$radioManager$en._(_root);
}

// Path: checkbox
class _Translations$checkbox$en extends Translations$checkbox$zh {
	_Translations$checkbox$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get DeselectAll => 'Deselect All';
	@override String SelectAll({required Object count}) => 'Select All (${count})';
	@override String get selected => 'selected';
}

// Path: TextField
class _Translations$TextField$en extends Translations$TextField$zh {
	_Translations$TextField$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get search => 'Search......';
}

// Path: Form
class _Translations$Form$en extends Translations$Form$zh {
	_Translations$Form$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$Form$radioManager$en radioManager = _Translations$Form$radioManager$en._(_root);
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

// Path: pager.radioManager
class _Translations$pager$radioManager$en extends Translations$pager$radioManager$zh {
	_Translations$pager$radioManager$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Radio manager';
}

// Path: tableColumn.base
class _Translations$tableColumn$base$en extends Translations$tableColumn$base$zh {
	_Translations$tableColumn$base$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get actions => 'Actions';
}

// Path: tableColumn.radioManager
class _Translations$tableColumn$radioManager$en extends Translations$tableColumn$radioManager$zh {
	_Translations$tableColumn$radioManager$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get alias => 'Radio alias';
	@override String get alias_desc => 'Custom radio alias';
	@override String get consumer => 'Consumer';
	@override String get consumer_desc => 'Radio consumer';
	@override String get location => 'Location';
	@override String get location_desc => 'Radio location';
	@override String get sn => 'SN';
	@override String get sn_desc => 'Radio SN';
	@override String get columnInfo => 'Show column info';
}

// Path: button.radioManager
class _Translations$button$radioManager$en extends Translations$button$radioManager$zh {
	_Translations$button$radioManager$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get createRadio => 'Create Radio';
	@override String get resetRadio => 'Reset';
	@override String get edit => 'Edit';
	@override String get delete => 'Delete';
	@override String get clear => 'Clear';
	@override String get search => 'Search';
}

// Path: Form.radioManager
class _Translations$Form$radioManager$en extends Translations$Form$radioManager$zh {
	_Translations$Form$radioManager$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$Form$radioManager$alias$en alias = _Translations$Form$radioManager$alias$en._(_root);
	@override late final _Translations$Form$radioManager$sn$en sn = _Translations$Form$radioManager$sn$en._(_root);
	@override late final _Translations$Form$radioManager$location$en location = _Translations$Form$radioManager$location$en._(_root);
	@override late final _Translations$Form$radioManager$consumer$en consumer = _Translations$Form$radioManager$consumer$en._(_root);
}

// Path: Form.radioManager.alias
class _Translations$Form$radioManager$alias$en extends Translations$Form$radioManager$alias$zh {
	_Translations$Form$radioManager$alias$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio alias';
	@override String get validate => 'Radio alias cannot be empty';
}

// Path: Form.radioManager.sn
class _Translations$Form$radioManager$sn$en extends Translations$Form$radioManager$sn$zh {
	_Translations$Form$radioManager$sn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio sn';
	@override String get validate => 'Radio sn cannot be empty';
}

// Path: Form.radioManager.location
class _Translations$Form$radioManager$location$en extends Translations$Form$radioManager$location$zh {
	_Translations$Form$radioManager$location$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio location';
	@override String get validate => 'Radio location cannot be empty';
}

// Path: Form.radioManager.consumer
class _Translations$Form$radioManager$consumer$en extends Translations$Form$radioManager$consumer$zh {
	_Translations$Form$radioManager$consumer$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio consumer';
	@override String get validate => 'Radio consumer cannot be empty';
}
