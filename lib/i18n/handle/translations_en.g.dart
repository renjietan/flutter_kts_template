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
	@override late final _Translations$tree$en tree = _Translations$tree$en._(_root);
	@override late final _Translations$json$en json = _Translations$json$en._(_root);
	@override late final _Translations$pageable$en pageable = _Translations$pageable$en._(_root);
	@override late final _Translations$pager$en pager = _Translations$pager$en._(_root);
	@override late final _Translations$tips$en tips = _Translations$tips$en._(_root);
	@override late final _Translations$tableColumn$en tableColumn = _Translations$tableColumn$en._(_root);
	@override late final _Translations$button$en button = _Translations$button$en._(_root);
	@override late final _Translations$checkbox$en checkbox = _Translations$checkbox$en._(_root);
	@override late final _Translations$TextField$en TextField = _Translations$TextField$en._(_root);
	@override late final _Translations$Form$en Form = _Translations$Form$en._(_root);
	@override late final _Translations$entity$en entity = _Translations$entity$en._(_root);
	@override late final _Translations$udp$en udp = _Translations$udp$en._(_root);
	@override late final _Translations$errorMiddle$en errorMiddle = _Translations$errorMiddle$en._(_root);
	@override late final _Translations$platform$en platform = _Translations$platform$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$cpds$en cpds = _Translations$cpds$en._(_root);
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
	@override String get preview => 'Preview';
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
	@override String successWithPath({required Object path}) => 'Upload successful; path：${path}!';
	@override String get cancel => 'Operation cancelled';
	@override String get failed => 'Upload failed';
	@override String get emptyPath => 'The file path is empty';
	@override String get emptyData => 'The file data is empty';
	@override String get existPath => 'The file path is not exist';
	@override String get selectedFolderDialogTitle => 'Please select a folder';
	@override String get selectedAllow => 'Only ZIP and folders are supported';
}

// Path: tree
class _Translations$tree$en extends Translations$tree$zh {
	_Translations$tree$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get empty => '<null>';
	@override String get futureWarrior => 'Future warrior';
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
	@override late final _Translations$pager$injectParams$en injectParams = _Translations$pager$injectParams$en._(_root);
	@override late final _Translations$pager$radioManager$en radioManager = _Translations$pager$radioManager$en._(_root);
	@override late final _Translations$pager$injectEncrypt$en injectEncrypt = _Translations$pager$injectEncrypt$en._(_root);
}

// Path: tips
class _Translations$tips$en extends Translations$tips$zh {
	_Translations$tips$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tips';
	@override String get cancel => 'Cancel';
	@override String get ok => 'Confirm';
	@override late final _Translations$tips$paramsInject$en paramsInject = _Translations$tips$paramsInject$en._(_root);
	@override late final _Translations$tips$keyLoaders$en keyLoaders = _Translations$tips$keyLoaders$en._(_root);
}

// Path: tableColumn
class _Translations$tableColumn$en extends Translations$tableColumn$zh {
	_Translations$tableColumn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$tableColumn$base$en base = _Translations$tableColumn$base$en._(_root);
	@override late final _Translations$tableColumn$radioManager$en radioManager = _Translations$tableColumn$radioManager$en._(_root);
	@override late final _Translations$tableColumn$injectEncrypt$en injectEncrypt = _Translations$tableColumn$injectEncrypt$en._(_root);
}

// Path: button
class _Translations$button$en extends Translations$button$zh {
	_Translations$button$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$button$radioManager$en radioManager = _Translations$button$radioManager$en._(_root);
	@override late final _Translations$button$paramsInject$en paramsInject = _Translations$button$paramsInject$en._(_root);
	@override late final _Translations$button$injectEncrypt$en injectEncrypt = _Translations$button$injectEncrypt$en._(_root);
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
	@override String get select => 'Select......';
}

// Path: Form
class _Translations$Form$en extends Translations$Form$zh {
	_Translations$Form$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$Form$radioManager$en radioManager = _Translations$Form$radioManager$en._(_root);
	@override late final _Translations$Form$injectEncrypt$en injectEncrypt = _Translations$Form$injectEncrypt$en._(_root);
	@override late final _Translations$Form$paramsInject$en paramsInject = _Translations$Form$paramsInject$en._(_root);
}

// Path: entity
class _Translations$entity$en extends Translations$entity$zh {
	_Translations$entity$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sameName => 'Name must be unique';
}

// Path: udp
class _Translations$udp$en extends Translations$udp$zh {
	_Translations$udp$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get loginFail => 'Authentication failed';
	@override String get loginTimeout => 'Authentication timeout';
	@override String get closed => 'Local service';
	@override String get pingFail => 'Heartbeat acknowledgment failed';
	@override String get pingTimeout => 'Heartbeat request timed out';
	@override String get fileFail => 'File transmission failed';
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

// Path: settings
class _Translations$settings$en extends Translations$settings$zh {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get zh => 'Chinese';
	@override String get en => 'English';
}

// Path: cpds
class _Translations$cpds$en extends Translations$cpds$zh {
	_Translations$cpds$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	@override String get fileTitle => 'File parse';
	@override String get browse => 'Browse';
	@override String get parse => 'Parse';
	@override String get filePlaceholder => 'Select a communication package';
	@override String get nodesTitle => 'Net Node';
	@override String get nodesEmpty => 'Parse a package to display nodes';
	@override String get currentTitle => 'Current Node';
	@override String online({required Object online, required Object expected}) => '${online}/${expected} online';
	@override String get noSelection => 'Select a network node';
	@override String get networkInterfaceLabel => 'Business NIC';
	@override String get networkInterfacePlaceholder => 'Select a wired interface';
	@override String networkInterfaceOption({required Object name, required Object ip}) => '${name} · ${ip}';
	@override String get automatic => 'Auto';
	@override String get refresh => 'Refresh';
	@override String get distribute => 'Distribute';
	@override String get unsupported => 'The complete distribution state machine will be implemented later';

	@override late final _Translations$cpds$stages$en stages = _Translations$cpds$stages$en._(_root);
	@override late final _Translations$cpds$statuses$en statuses = _Translations$cpds$statuses$en._(_root);
	@override late final _Translations$cpds$device$en device = _Translations$cpds$device$en._(_root);
	@override late final _Translations$cpds$deviceTypes$en deviceTypes = _Translations$cpds$deviceTypes$en._(_root);
}

// Path: cpds.stages
class _Translations$cpds$stages$en extends Translations$cpds$stages$zh {
	_Translations$cpds$stages$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	@override String get discovery => 'Discover';
	@override String get authentication => 'Auth';
	@override String get transfer => 'Transfer';
	@override String get parse => 'Parse';
	@override String get complete => 'Complete';
}

// Path: cpds.statuses
class _Translations$cpds$statuses$en extends Translations$cpds$statuses$zh {
	_Translations$cpds$statuses$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	@override String get pending => 'Not started';
	@override String get discovered => 'Discovered';
	@override String get authenticated => 'Authenticated';
	@override String get receiving => 'Receiving';
	@override String get waitingParse => 'Waiting for parse result';
	@override String get completed => 'Completed';
	@override String get failed => 'Failed';
	@override String get ignored => 'Ignored';
}

// Path: cpds.device
class _Translations$cpds$device$en extends Translations$cpds$device$zh {
	_Translations$cpds$device$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	@override String get esn => 'ESN';
	@override String get ip => 'Current IP';
	@override String get emptyValue => '--';
}

// Path: cpds.deviceTypes
class _Translations$cpds$deviceTypes$en extends Translations$cpds$deviceTypes$zh {
	_Translations$cpds$deviceTypes$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	@override String get server => 'Server';
	@override String get hf => 'HF';
	@override String get multiBandRadio => 'MMR200';
	@override String get multiBandHandheld => 'PMR200';
	@override String get ccu => 'CCU-Main';
	@override String get ccuAudio => 'CCU-Audio';
	@override String get ccuGroup => 'CCU';
	@override String get iec => 'IEC';
	@override String get smallHandheld => 'Small Handheld';
	@override String get unknown => 'Unknown device';
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

// Path: pager.injectParams
class _Translations$pager$injectParams$en extends Translations$pager$injectParams$zh {
	_Translations$pager$injectParams$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get futureSoldier => 'Future soldier';
	@override String get networkCard => 'NIC';
	@override late final _Translations$pager$injectParams$steps$en steps = _Translations$pager$injectParams$steps$en._(_root);
}

// Path: pager.radioManager
class _Translations$pager$radioManager$en extends Translations$pager$radioManager$zh {
	_Translations$pager$radioManager$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Radio manager';
	@override String get netNode => 'Net Node';
	@override String get fileParse => 'File Parse';
}

// Path: pager.injectEncrypt
class _Translations$pager$injectEncrypt$en extends Translations$pager$injectEncrypt$zh {
	_Translations$pager$injectEncrypt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get paramPairing => 'Parameter pairing';
	@override String get keyLoaderManager => 'Key loader';
}

// Path: tips.paramsInject
class _Translations$tips$paramsInject$en extends Translations$tips$paramsInject$zh {
	_Translations$tips$paramsInject$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get noKeyLoader => 'No Key Loader is available. Please go and add one';
	@override String get selectRadios => 'Please select a radio';
	@override String get gotoConfig => 'Binding completed. go to configuration now?';
}

// Path: tips.keyLoaders
class _Translations$tips$keyLoaders$en extends Translations$tips$keyLoaders$zh {
	_Translations$tips$keyLoaders$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get delete => 'delete';
	@override String get confirmDelete => 'Are you sure you want to delete it?';
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

// Path: tableColumn.injectEncrypt
class _Translations$tableColumn$injectEncrypt$en extends Translations$tableColumn$injectEncrypt$zh {
	_Translations$tableColumn$injectEncrypt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get parameterPacket => 'Parameter Packet';
	@override String get radio => 'Matching Radio';
	@override String get consumer => 'Consumer';
	@override String get location => 'Location';
	@override String get SN => 'SN';
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
	@override String get save => 'Save';
	@override String get browse => 'Browse';
	@override String get parse => 'Parse';
}

// Path: button.paramsInject
class _Translations$button$paramsInject$en extends Translations$button$paramsInject$zh {
	_Translations$button$paramsInject$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get inject => 'inject';
	@override String get bind => 'bind';
	@override String get refresh => 'refresh';
	@override String get issue => 'issue';
}

// Path: button.injectEncrypt
class _Translations$button$injectEncrypt$en extends Translations$button$injectEncrypt$zh {
	_Translations$button$injectEncrypt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get export => 'export';
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

// Path: Form.injectEncrypt
class _Translations$Form$injectEncrypt$en extends Translations$Form$injectEncrypt$zh {
	_Translations$Form$injectEncrypt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$Form$injectEncrypt$name$en name = _Translations$Form$injectEncrypt$name$en._(_root);
}

// Path: Form.paramsInject
class _Translations$Form$paramsInject$en extends Translations$Form$paramsInject$zh {
	_Translations$Form$paramsInject$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get text => 'Key loader';
	@override late final _Translations$Form$paramsInject$deviceType$en deviceType = _Translations$Form$paramsInject$deviceType$en._(_root);
	@override late final _Translations$Form$paramsInject$deviceIp$en deviceIp = _Translations$Form$paramsInject$deviceIp$en._(_root);
	@override late final _Translations$Form$paramsInject$selectKeyLoader$en selectKeyLoader = _Translations$Form$paramsInject$selectKeyLoader$en._(_root);
}

// Path: pager.injectParams.steps
class _Translations$pager$injectParams$steps$en extends Translations$pager$injectParams$steps$zh {
	_Translations$pager$injectParams$steps$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get discovery => 'discovery';
	@override String get authentication => 'auth';
	@override String get transfer => 'transfer';
	@override String get parse => 'parse';
	@override String get finish => 'finish';
}

// Path: Form.radioManager.alias
class _Translations$Form$radioManager$alias$en extends Translations$Form$radioManager$alias$zh {
	_Translations$Form$radioManager$alias$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio alias';
	@override String get validate => 'Radio alias cannot be empty!';
}

// Path: Form.radioManager.sn
class _Translations$Form$radioManager$sn$en extends Translations$Form$radioManager$sn$zh {
	_Translations$Form$radioManager$sn$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio sn';
	@override String get validate => 'Radio sn cannot be empty!';
}

// Path: Form.radioManager.location
class _Translations$Form$radioManager$location$en extends Translations$Form$radioManager$location$zh {
	_Translations$Form$radioManager$location$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio location';
	@override String get validate => 'Radio location cannot be empty!';
}

// Path: Form.radioManager.consumer
class _Translations$Form$radioManager$consumer$en extends Translations$Form$radioManager$consumer$zh {
	_Translations$Form$radioManager$consumer$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Please enter radio consumer';
	@override String get validate => 'Radio consumer cannot be empty!';
}

// Path: Form.injectEncrypt.name
class _Translations$Form$injectEncrypt$name$en extends Translations$Form$injectEncrypt$name$zh {
	_Translations$Form$injectEncrypt$name$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Key loader';
	@override String get placeholder => 'Please enter name';
	@override String get validate => 'Please enter name!';
}

// Path: Form.paramsInject.deviceType
class _Translations$Form$paramsInject$deviceType$en extends Translations$Form$paramsInject$deviceType$zh {
	_Translations$Form$paramsInject$deviceType$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get text => 'Device type';
	@override String get validatorText => 'Please enter device type!';
}

// Path: Form.paramsInject.deviceIp
class _Translations$Form$paramsInject$deviceIp$en extends Translations$Form$paramsInject$deviceIp$zh {
	_Translations$Form$paramsInject$deviceIp$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get text => 'Device IP';
	@override String get validatorText => 'Please enter a valid IP address!';
}

// Path: Form.paramsInject.selectKeyLoader
class _Translations$Form$paramsInject$selectKeyLoader$en extends Translations$Form$paramsInject$selectKeyLoader$zh {
	_Translations$Form$paramsInject$selectKeyLoader$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get text => 'Key loader';
	@override String get placeholder => 'Please select';
}
