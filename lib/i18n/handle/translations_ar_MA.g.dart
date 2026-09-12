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
class TranslationsArMa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsArMa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.arMa,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ar-MA>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsArMa _root = this; // ignore: unused_field

	@override 
	TranslationsArMa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsArMa(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$app$ar_MA app = Translations$app$ar_MA.internal(_root);
	@override late final Translations$common$ar_MA common = Translations$common$ar_MA.internal(_root);
	@override late final Translations$permission$ar_MA permission = Translations$permission$ar_MA.internal(_root);
	@override late final Translations$uploads$ar_MA uploads = Translations$uploads$ar_MA.internal(_root);
	@override late final Translations$tree$ar_MA tree = Translations$tree$ar_MA.internal(_root);
	@override late final Translations$json$ar_MA json = Translations$json$ar_MA.internal(_root);
	@override late final Translations$pageable$ar_MA pageable = Translations$pageable$ar_MA.internal(_root);
	@override late final Translations$pager$ar_MA pager = Translations$pager$ar_MA.internal(_root);
	@override late final Translations$tips$ar_MA tips = Translations$tips$ar_MA.internal(_root);
	@override late final Translations$tableColumn$ar_MA tableColumn = Translations$tableColumn$ar_MA.internal(_root);
	@override late final Translations$button$ar_MA button = Translations$button$ar_MA.internal(_root);
	@override late final Translations$checkbox$ar_MA checkbox = Translations$checkbox$ar_MA.internal(_root);
	@override late final Translations$TextField$ar_MA TextField = Translations$TextField$ar_MA.internal(_root);
	@override late final Translations$Form$ar_MA Form = Translations$Form$ar_MA.internal(_root);
	@override late final Translations$entity$ar_MA entity = Translations$entity$ar_MA.internal(_root);
	@override late final Translations$usb$ar_MA usb = Translations$usb$ar_MA.internal(_root);
	@override late final Translations$udp$ar_MA udp = Translations$udp$ar_MA.internal(_root);
	@override late final Translations$errorMiddle$ar_MA errorMiddle = Translations$errorMiddle$ar_MA.internal(_root);
	@override late final Translations$platform$ar_MA platform = Translations$platform$ar_MA.internal(_root);
	@override late final Translations$layout$ar_MA layout = Translations$layout$ar_MA.internal(_root);
	@override late final Translations$settings$ar_MA settings = Translations$settings$ar_MA.internal(_root);
	@override late final Translations$cpds$ar_MA cpds = Translations$cpds$ar_MA.internal(_root);
}

// Path: app
class Translations$app$ar_MA extends Translations$app$zh {
	Translations$app$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get title => 'تطبيقي';
	@override late final Translations$app$appbar$ar_MA appbar = Translations$app$appbar$ar_MA.internal(_root);
}

// Path: common
class Translations$common$ar_MA extends Translations$common$zh {
	Translations$common$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get confirm => 'تأكيد';
	@override String get cancel => 'إلغاء';
	@override String get close => 'إغلاق';
	@override String get noData => 'لا توجد بيانات';
	@override String get OperationSuccess => 'تمت العملية بنجاح';
	@override String get OperationError => 'فشلت العملية';
	@override String get requestError => 'فشل الطلب';
	@override String get requestCancel => 'تم إلغاء الطلب';
	@override String get requestTimeout => 'انتهت مهلة الشبكة، يرجى المحاولة لاحقًا';
	@override String get connectionTimeout => 'انتهت مهلة الاتصال بالشبكة';
	@override String get sendTimeout => 'انتهت مهلة الإرسال';
	@override String get serverError => 'خطأ في الخادم';
	@override String get UnknowError => 'خطأ غير معروف';
	@override String get preview => 'معاينة';
	@override String get addSuccess => 'تمت الإضافة بنجاح';
	@override String get pleaseSelect => 'يرجى الاختيار';
	@override String get saveSuccess => 'تم الحفظ بنجاح';
}

// Path: permission
class Translations$permission$ar_MA extends Translations$permission$zh {
	Translations$permission$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get no => 'لا يوجد إذن وصول، هل تريد الانتقال إلى الإعدادات الآن؟';
	@override String get cancel => 'تم إلغاء العملية';
}

// Path: uploads
class Translations$uploads$ar_MA extends Translations$uploads$zh {
	Translations$uploads$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get success => 'تم الرفع بنجاح';
	@override String successWithPath({required Object path}) => 'تم الرفع بنجاح؛ المسار: ${path}!';
	@override String get cancel => 'تم إلغاء العملية';
	@override String get failed => 'فشل الرفع';
	@override String get emptyPath => 'لا يمكن أن يكون مسار الملف فارغًا';
	@override String get emptyData => 'لا يمكن أن تكون بيانات الملف فارغة';
	@override String get existPath => 'مسار الملف غير موجود';
	@override String get selectedFolderDialogTitle => 'يرجى اختيار مجلد';
	@override String get selectedAllow => 'يدعم حاليًا ملفات ZIP والمجلدات فقط';
}

// Path: tree
class Translations$tree$ar_MA extends Translations$tree$zh {
	Translations$tree$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get empty => '<فارغ>';
	@override String get futureWarrior => 'محارب المستقبل';
}

// Path: json
class Translations$json$ar_MA extends Translations$json$zh {
	Translations$json$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get serialization => 'تنسيق المعلومات المستلمة غير مألوف';
}

// Path: pageable
class Translations$pageable$ar_MA extends Translations$pageable$zh {
	Translations$pageable$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get pageSizeMin => 'يجب أن يكون pageSize أكبر من أو يساوي 1';
	@override String get pageSizeMax => 'لا يمكن أن يتجاوز pageSize 100';
	@override String get pageMin => 'يجب أن يكون page أكبر من أو يساوي 1';
	@override String paramsValidateError({required Object errors}) => 'فشل التحقق من المعلمات: ${errors}';
	@override String keywordValidateError({required Object count}) => 'لا يمكن أن يتجاوز نص الكلمة المفتاحية ${count} حرفًا';
}

// Path: pager
class Translations$pager$ar_MA extends Translations$pager$zh {
	Translations$pager$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override late final Translations$pager$injectParams$ar_MA injectParams = Translations$pager$injectParams$ar_MA.internal(_root);
	@override late final Translations$pager$radioManager$ar_MA radioManager = Translations$pager$radioManager$ar_MA.internal(_root);
	@override late final Translations$pager$injectEncrypt$ar_MA injectEncrypt = Translations$pager$injectEncrypt$ar_MA.internal(_root);
}

// Path: tips
class Translations$tips$ar_MA extends Translations$tips$zh {
	Translations$tips$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get title => 'تلميح';
	@override String get cancel => 'إلغاء';
	@override String get ok => 'موافق';
	@override late final Translations$tips$paramsInject$ar_MA paramsInject = Translations$tips$paramsInject$ar_MA.internal(_root);
	@override late final Translations$tips$keyLoaders$ar_MA keyLoaders = Translations$tips$keyLoaders$ar_MA.internal(_root);
}

// Path: tableColumn
class Translations$tableColumn$ar_MA extends Translations$tableColumn$zh {
	Translations$tableColumn$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override late final Translations$tableColumn$base$ar_MA base = Translations$tableColumn$base$ar_MA.internal(_root);
	@override late final Translations$tableColumn$radioManager$ar_MA radioManager = Translations$tableColumn$radioManager$ar_MA.internal(_root);
	@override late final Translations$tableColumn$injectEncrypt$ar_MA injectEncrypt = Translations$tableColumn$injectEncrypt$ar_MA.internal(_root);
}

// Path: button
class Translations$button$ar_MA extends Translations$button$zh {
	Translations$button$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override late final Translations$button$radioManager$ar_MA radioManager = Translations$button$radioManager$ar_MA.internal(_root);
	@override late final Translations$button$paramsInject$ar_MA paramsInject = Translations$button$paramsInject$ar_MA.internal(_root);
	@override late final Translations$button$injectEncrypt$ar_MA injectEncrypt = Translations$button$injectEncrypt$ar_MA.internal(_root);
}

// Path: checkbox
class Translations$checkbox$ar_MA extends Translations$checkbox$zh {
	Translations$checkbox$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get DeselectAll => 'إلغاء تحديد الكل';
	@override String SelectAll({required Object count}) => 'تحديد الكل (${count})';
	@override String get selected => 'محدد';
}

// Path: TextField
class Translations$TextField$ar_MA extends Translations$TextField$zh {
	Translations$TextField$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get search => 'بحث......';
	@override String get select => 'اختيار......';
}

// Path: Form
class Translations$Form$ar_MA extends Translations$Form$zh {
	Translations$Form$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override late final Translations$Form$radioManager$ar_MA radioManager = Translations$Form$radioManager$ar_MA.internal(_root);
	@override late final Translations$Form$injectEncrypt$ar_MA injectEncrypt = Translations$Form$injectEncrypt$ar_MA.internal(_root);
	@override late final Translations$Form$paramsInject$ar_MA paramsInject = Translations$Form$paramsInject$ar_MA.internal(_root);
}

// Path: entity
class Translations$entity$ar_MA extends Translations$entity$zh {
	Translations$entity$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get sameName => 'لا يمكن تكرار الاسم';
	@override String get aliasDuplicate => 'الاسم المستعار للجهاز موجود بالفعل';
	@override String get consumerDuplicate => 'المستخدم موجود بالفعل';
	@override String get snDuplicate => 'رقم SN موجود بالفعل';
}

// Path: usb
class Translations$usb$ar_MA extends Translations$usb$zh {
	Translations$usb$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String deviceInserted({required Object address}) => 'تم إدخال جهاز USB: ${address}';
	@override String deviceRemoved({required Object address}) => 'تم فصل جهاز USB: ${address}';
	@override String deviceNotFound({required Object address}) => 'لم يتم العثور على جهاز USB: ${address}';
	@override String get createPortFailed => 'فشل إنشاء منفذ USB';
	@override String get openPortFailed => 'فشل فتح منفذ USB';
	@override String get deviceConnected => 'تم الاتصال بجهاز USB';
	@override String get noAvailableConnection => 'لا يوجد اتصال USB متاح';
	@override String get winUsbNotFound => 'لم يتم العثور على جهاز WinUSB';
	@override String endpointNotFound({required Object epOut, required Object epIn}) => 'لم يتم العثور على نقطة النهاية: ${epOut} ${epIn}';
	@override String get winUsbConnected => 'تم الاتصال بجهاز WinUSB';
	@override String get winUsbDisconnected => 'تم فصل جهاز WinUSB';
	@override String get winUsbNotConnected => 'WinUSB غير متصل';
	@override String get noWinUsbConnection => 'لا يوجد اتصال WinUSB متاح';
	@override String get noOutPipe => 'لا توجد قناة OUT متاحة';
}

// Path: udp
class Translations$udp$ar_MA extends Translations$udp$zh {
	Translations$udp$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get loginFail => 'فشلت المصادقة';
	@override String get loginTimeout => 'انتهت مهلة المصادقة';
	@override String get closed => 'تم إغلاق الخدمة المحلية';
	@override String get pingFail => 'فشل استجابة نبضات القلب';
	@override String get pingTimeout => 'انتهت مهلة طلب نبضات القلب';
	@override String get fileFail => 'فشل نقل الملف';
}

// Path: errorMiddle
class Translations$errorMiddle$ar_MA extends Translations$errorMiddle$zh {
	Translations$errorMiddle$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get error500 => 'حدث خطأ غير متوقع، يرجى المحاولة لاحقًا';
	@override String errorArg({required Object error}) => 'معامل غير صالح، ${error}';
}

// Path: platform
class Translations$platform$ar_MA extends Translations$platform$zh {
	Translations$platform$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get webNotReadFile => 'الصفحة الحالية غير مُهيأة للتعامل مع الملفات';
}

// Path: layout
class Translations$layout$ar_MA extends Translations$layout$zh {
	Translations$layout$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get settings => 'الإعدادات';
	@override String get clearTempFiles => 'مسح الملفات المؤقتة';
	@override String get clearCache => 'مسح ذاكرة التخزين المؤقت';
	@override String get confirmExit => 'تأكيد الخروج';
	@override String get leavePagePrompt => 'هل أنت متأكد من مغادرة هذه الصفحة؟';
}

// Path: settings
class Translations$settings$ar_MA extends Translations$settings$zh {
	Translations$settings$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get zh => 'الصينية';
	@override String get en => 'الإنجليزية';
	@override String get arEg => 'العربية (شرق)';
	@override String get arMa => 'العربية (غرب)';
}

// Path: cpds
class Translations$cpds$ar_MA extends Translations$cpds$zh {
	Translations$cpds$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get fileTitle => 'تحليل الملف';
	@override String get browse => 'استعراض';
	@override String get goNow => 'الانتقال الآن';
	@override String get parse => 'تحليل';
	@override String get filePlaceholder => 'يرجى اختيار حزمة معلمات الاتصال';
	@override String get packageFileMissing => 'ملف حزمة معلمات الاتصال مفقود';
	@override String get fileBytesEmpty => 'بايتات الملف فارغة';
	@override String get browseConfirm => 'سيؤدي إعادة تحميل الملف إلى مسح حزمة معلمات الاتصال المرتبطة بجهاز تحميل المفاتيح، هل تريد المتابعة؟';
	@override String get browseSourceTitle => 'اختيار مصدر الملف';
	@override String get browseSourceLocal => 'قائمة الملفات المحلية';
	@override String get browseSourceKeyLoader => 'قائمة ملفات جهاز تحميل المفاتيح';
	@override String get keyLoaderPermissionDenied => 'لم يتم منح إذن USB';
	@override String get keyLoaderConnectSuccess => 'تم الاتصال بجهاز تحميل المفاتيح بنجاح';
	@override String get keyLoaderConnectFailed => 'فشل الاتصال بجهاز تحميل المفاتيح';
	@override String get keyLoaderStepConnect => 'الاتصال بجهاز تحميل المفاتيح';
	@override String get keyLoaderStepList => 'الحصول على قائمة الملفات';
	@override String get keyLoaderStepSelect => 'اختيار الملف';
	@override String get keyLoaderStepSelected => 'تم اختيار الملف';
	@override String get keyLoaderListEmpty => 'لا توجد ملفات';
	@override String get keyLoaderListError => 'فشل الحصول على قائمة الملفات';
	@override String get keyLoaderListTimeout => 'انتهت مهلة الحصول على قائمة الملفات';
	@override String get keyLoaderStepPassword => 'التحقق من كلمة المرور';
	@override String get keyLoaderStepDownload => 'تنزيل';
	@override String get keyLoaderStepReady => 'جاهز';
	@override String get keyLoaderStepComplete => 'اكتمل';
	@override String get keyLoaderNext => 'التالي';
	@override String get keyLoaderPrev => 'السابق';
	@override String get keyLoaderDecryptTimeout => 'انتهت المهلة';
	@override String get keyLoaderDecryptFail => 'فشل التحقق';
	@override String keyLoaderDecryptFailRemaining({required Object n}) => 'كلمة المرور خاطئة، تبقى ${n} محاولات';
	@override String get keyLoaderDecryptCleared => 'تم تدمير المفتاح بسبب أخطاء متعددة في كلمة المرور';
	@override String get keyLoaderDecryptErr => 'الملف تالف';
	@override String get keyLoaderStepDecrypt => 'فك التشفير';
	@override String get keyLoaderStepParse => 'التحليل';
	@override String get keyLoaderFileCorrupted => 'الملف غير مكتمل وتالف';
	@override String get keyLoaderDownloadTimeout => 'انتهت مهلة استقبال الملف، يرجى إعادة توصيل جهاز تحميل المفاتيح';
	@override String get keyLoaderDeviceRemoved => 'تم فصل جهاز USB';
	@override String get keyLoaderDecryptFailed => 'فشل فك التشفير';
	@override String get keyLoaderSuccess => 'اكتمل التنزيل';
	@override String get keyLoaderReadyTimeout => 'انتهت مهلة الاستجابة';
	@override String get keyLoaderVerifyFailed => 'فشل: فشل التحقق';
	@override String get keyLoaderParseSuccess => 'نجح التحليل';
	@override String get keyLoaderParseFailed => 'فشل التحليل';
	@override String get nodesTitle => 'عقد الشبكة';
	@override String get nodesEmpty => 'يتم عرض العقد بعد تحليل حزمة الاتصال';
	@override String get currentTitle => 'العقدة الحالية';
	@override String online({required Object online, required Object expected}) => 'متصل ${online}/${expected}';
	@override String get noSelection => 'يرجى اختيار عقدة شبكة';
	@override String get networkInterfaceLabel => 'بطاقة شبكة الأعمال';
	@override String get networkInterfacePlaceholder => 'يرجى اختيار بطاقة شبكة سلكية';
	@override String networkInterfaceOption({required Object name, required Object ip}) => '${name} · ${ip}';
	@override String get automatic => 'تحديد تلقائي';
	@override String get refresh => 'تحديث';
	@override String get distribute => 'توزيع';
	@override String get unsupported => 'سيتم تنفيذ آلة حالة التوزيع الكاملة في المرحلة التالية';
	@override late final Translations$cpds$stages$ar_MA stages = Translations$cpds$stages$ar_MA.internal(_root);
	@override late final Translations$cpds$statuses$ar_MA statuses = Translations$cpds$statuses$ar_MA.internal(_root);
	@override late final Translations$cpds$device$ar_MA device = Translations$cpds$device$ar_MA.internal(_root);
	@override late final Translations$cpds$deviceTypes$ar_MA deviceTypes = Translations$cpds$deviceTypes$ar_MA.internal(_root);
	@override late final Translations$cpds$saveDialog$ar_MA saveDialog = Translations$cpds$saveDialog$ar_MA.internal(_root);
	@override late final Translations$cpds$setPassword$ar_MA setPassword = Translations$cpds$setPassword$ar_MA.internal(_root);
	@override late final Translations$cpds$export$ar_MA export = Translations$cpds$export$ar_MA.internal(_root);
	@override late final Translations$cpds$exportProgress$ar_MA exportProgress = Translations$cpds$exportProgress$ar_MA.internal(_root);
	@override late final Translations$cpds$usbProgress$ar_MA usbProgress = Translations$cpds$usbProgress$ar_MA.internal(_root);
}

// Path: app.appbar
class Translations$app$appbar$ar_MA extends Translations$app$appbar$zh {
	Translations$app$appbar$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get paramsInject => 'حقن المعلمات';
	@override String get radioManager => 'إدارة أجهزة الراديو';
	@override String get keyManager => 'إدارة تحميل المفاتيح';
}

// Path: pager.injectParams
class Translations$pager$injectParams$ar_MA extends Translations$pager$injectParams$zh {
	Translations$pager$injectParams$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get futureSoldier => 'محارب المستقبل';
	@override String get networkCard => 'بطاقة شبكة الأعمال';
	@override late final Translations$pager$injectParams$steps$ar_MA steps = Translations$pager$injectParams$steps$ar_MA.internal(_root);
}

// Path: pager.radioManager
class Translations$pager$radioManager$ar_MA extends Translations$pager$radioManager$zh {
	Translations$pager$radioManager$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get title => 'إدارة أجهزة الراديو';
	@override String get netNode => 'عقدة الشبكة';
	@override String get fileParse => 'تحليل الملف';
}

// Path: pager.injectEncrypt
class Translations$pager$injectEncrypt$ar_MA extends Translations$pager$injectEncrypt$zh {
	Translations$pager$injectEncrypt$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get paramPairing => 'إقران المعلمات';
	@override String get keyLoaderManager => 'إدارة جهاز تحميل المفاتيح';
}

// Path: tips.paramsInject
class Translations$tips$paramsInject$ar_MA extends Translations$tips$paramsInject$zh {
	Translations$tips$paramsInject$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get noKeyLoader => 'لا يوجد جهاز مفاتيح متاح حاليًا، يرجى الإضافة ثم المحاولة مرة أخرى';
	@override String get noRadio => 'لا يوجد جهاز راديو متاح حاليًا، يرجى الإضافة ثم المحاولة مرة أخرى';
	@override String get selectRadios => 'يرجى تحديد أجهزة الراديو';
	@override String get gotoConfig => 'اكتمل الربط، هل تريد الانتقال إلى الإعداد الآن؟';
}

// Path: tips.keyLoaders
class Translations$tips$keyLoaders$ar_MA extends Translations$tips$keyLoaders$zh {
	Translations$tips$keyLoaders$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get delete => 'حذف';
	@override String get confirmDelete => 'هل أنت متأكد من الحذف؟';
}

// Path: tableColumn.base
class Translations$tableColumn$base$ar_MA extends Translations$tableColumn$base$zh {
	Translations$tableColumn$base$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get actions => 'الإجراءات';
}

// Path: tableColumn.radioManager
class Translations$tableColumn$radioManager$ar_MA extends Translations$tableColumn$radioManager$zh {
	Translations$tableColumn$radioManager$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get alias => 'الاسم المستعار للجهاز';
	@override String get alias_desc => 'اسم مستعار مخصص لجهاز الراديو';
	@override String get consumer => 'المستخدم';
	@override String get consumer_desc => 'مستخدم جهاز الراديو';
	@override String get location => 'الموقع';
	@override String get location_desc => 'موقع جهاز الراديو';
	@override String get sn => 'SN';
	@override String get sn_desc => 'رقم SN لجهاز الراديو';
	@override String get columnInfo => 'معلومات الأعمدة المعروضة';
}

// Path: tableColumn.injectEncrypt
class Translations$tableColumn$injectEncrypt$ar_MA extends Translations$tableColumn$injectEncrypt$zh {
	Translations$tableColumn$injectEncrypt$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get parameterPacket => 'حزمة معلمات الاتصال';
	@override String get radio => 'جهاز الراديو المقترن';
	@override String get consumer => 'المستخدم';
	@override String get location => 'الموقع';
	@override String get SN => 'SN';
}

// Path: button.radioManager
class Translations$button$radioManager$ar_MA extends Translations$button$radioManager$zh {
	Translations$button$radioManager$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get createRadio => 'إضافة جهاز راديو';
	@override String get resetRadio => 'إعادة تعيين';
	@override String get edit => 'تعديل';
	@override String get editRadio => 'تعديل جهاز الراديو';
	@override String get delete => 'حذف';
	@override String get clear => 'مسح';
	@override String get search => 'بحث';
	@override String get save => 'حفظ';
	@override String get browse => 'استعراض';
	@override String get parse => 'تحليل';
}

// Path: button.paramsInject
class Translations$button$paramsInject$ar_MA extends Translations$button$paramsInject$zh {
	Translations$button$paramsInject$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get inject => 'حقن';
	@override String get bind => 'ربط';
	@override String get refresh => 'تحديث';
	@override String get issue => 'توزيع';
}

// Path: button.injectEncrypt
class Translations$button$injectEncrypt$ar_MA extends Translations$button$injectEncrypt$zh {
	Translations$button$injectEncrypt$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get export => 'تصدير';
	@override String get create => 'جديد';
	@override String get createKeyLoader => 'إضافة جهاز تحميل مفاتيح';
}

// Path: Form.radioManager
class Translations$Form$radioManager$ar_MA extends Translations$Form$radioManager$zh {
	Translations$Form$radioManager$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override late final Translations$Form$radioManager$alias$ar_MA alias = Translations$Form$radioManager$alias$ar_MA.internal(_root);
	@override late final Translations$Form$radioManager$sn$ar_MA sn = Translations$Form$radioManager$sn$ar_MA.internal(_root);
	@override late final Translations$Form$radioManager$location$ar_MA location = Translations$Form$radioManager$location$ar_MA.internal(_root);
	@override late final Translations$Form$radioManager$consumer$ar_MA consumer = Translations$Form$radioManager$consumer$ar_MA.internal(_root);
}

// Path: Form.injectEncrypt
class Translations$Form$injectEncrypt$ar_MA extends Translations$Form$injectEncrypt$zh {
	Translations$Form$injectEncrypt$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override late final Translations$Form$injectEncrypt$name$ar_MA name = Translations$Form$injectEncrypt$name$ar_MA.internal(_root);
}

// Path: Form.paramsInject
class Translations$Form$paramsInject$ar_MA extends Translations$Form$paramsInject$zh {
	Translations$Form$paramsInject$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get text => 'تحميل المفتاح';
	@override late final Translations$Form$paramsInject$deviceType$ar_MA deviceType = Translations$Form$paramsInject$deviceType$ar_MA.internal(_root);
	@override late final Translations$Form$paramsInject$deviceIp$ar_MA deviceIp = Translations$Form$paramsInject$deviceIp$ar_MA.internal(_root);
	@override late final Translations$Form$paramsInject$selectKeyLoader$ar_MA selectKeyLoader = Translations$Form$paramsInject$selectKeyLoader$ar_MA.internal(_root);
}

// Path: cpds.stages
class Translations$cpds$stages$ar_MA extends Translations$cpds$stages$zh {
	Translations$cpds$stages$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get discovery => 'الاكتشاف';
	@override String get authentication => 'المصادقة';
	@override String get transfer => 'النقل';
	@override String get parse => 'التحليل';
	@override String get complete => 'الإكمال';
}

// Path: cpds.statuses
class Translations$cpds$statuses$ar_MA extends Translations$cpds$statuses$zh {
	Translations$cpds$statuses$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get pending => 'لم يبدأ';
	@override String get discovered => 'تم الاكتشاف';
	@override String get authenticated => 'تمت المصادقة';
	@override String get receiving => 'قيد الاستقبال';
	@override String get waitingParse => 'في انتظار نتيجة التحليل';
	@override String get completed => 'اكتمل';
	@override String get failed => 'فشل';
	@override String get ignored => 'تم التجاهل';
}

// Path: cpds.device
class Translations$cpds$device$ar_MA extends Translations$cpds$device$zh {
	Translations$cpds$device$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get esn => 'ESN';
	@override String get ip => 'عنوان IP الحالي';
	@override String get emptyValue => '--';
}

// Path: cpds.deviceTypes
class Translations$cpds$deviceTypes$ar_MA extends Translations$cpds$deviceTypes$zh {
	Translations$cpds$deviceTypes$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get server => 'Server';
	@override String get hf => 'HF';
	@override String get multiBandRadio => 'MMR200';
	@override String get multiBandHandheld => 'PMR200';
	@override String get ccu => 'CCU-Main';
	@override String get ccuAudio => 'CCU-Audio';
	@override String get ccuGroup => 'CCU';
	@override String get vehInter => 'VehInter';
	@override String get iec => 'IEC';
	@override String get smallHandheld => 'Small Handheld';
	@override String get unknown => 'جهاز غير معروف';
}

// Path: cpds.saveDialog
class Translations$cpds$saveDialog$ar_MA extends Translations$cpds$saveDialog$zh {
	Translations$cpds$saveDialog$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get nameLabel => 'الاسم';
	@override String get nameHint => 'يرجى إدخال الاسم';
	@override String get nameRequired => 'يرجى إدخال الاسم';
	@override String get nameInvalid => 'يحتوي الاسم على أحرف غير قانونية';
	@override String get selectPlaceholder => 'يرجى الاختيار';
}

// Path: cpds.setPassword
class Translations$cpds$setPassword$ar_MA extends Translations$cpds$setPassword$zh {
	Translations$cpds$setPassword$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get title => 'تعيين كلمة المرور';
	@override String get label => 'كلمة المرور';
	@override String get placeholder => 'أدخل كلمة المرور';
	@override String get required => 'يرجى إدخال كلمة المرور';
	@override String get minLength => 'يجب ألا يقل طول كلمة المرور عن 8 أحرف';
	@override String get maxLength => 'يجب ألا يتجاوز طول كلمة المرور 20 حرفًا';
	@override String get invalid => 'يُسمح فقط بإدخال ثمانية أرقام';
	@override String get noChinese => 'لا يمكن أن تحتوي كلمة المرور على الصينية';
}

// Path: cpds.export
class Translations$cpds$export$ar_MA extends Translations$cpds$export$zh {
	Translations$cpds$export$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String zipNotFound({required Object path}) => 'لا يمكن العثور على حزمة ZIP: 【${path}】';
	@override String fileNotFound({required Object path}) => 'لا يمكن العثور على: 【${path}】';
	@override String failed({required Object error}) => '【فشل التصدير】${error}';
	@override String get radioRequired => 'توجد صفوف محددة بدون جهاز راديو مقترن، يرجى الاختيار أولاً';
	@override String get noSelection => 'يرجى تحديد الصفوف المطلوب تصديرها أولاً';
}

// Path: cpds.exportProgress
class Translations$cpds$exportProgress$ar_MA extends Translations$cpds$exportProgress$zh {
	Translations$cpds$exportProgress$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get stepStart => 'البدء';
	@override String get stepPack => 'التعبئة';
	@override String get stepMerge => 'الدمج';
	@override String get stepEncrypt => 'التشفير';
	@override String get detailStart => 'البدء';
	@override String get detailStartPack => 'بدء الضغط في حزمة tar';
	@override String detailPackSuccess({required Object index}) => 'تم ضغط الحزمة رقم ${index} بنجاح';
	@override String detailPackFail({required Object index}) => 'فشل ضغط الحزمة رقم ${index}';
	@override String get detailMerge => 'بدء الدمج لدمج الحزم المتعددة في حزمة ZIP';
	@override String get detailEncrypt => 'تشفير حزمة ZIP';
}

// Path: cpds.usbProgress
class Translations$cpds$usbProgress$ar_MA extends Translations$cpds$usbProgress$zh {
	Translations$cpds$usbProgress$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get stepPermission => 'الإذن';
	@override String get stepConnect => 'الاتصال';
	@override String get stepHandshake => 'المصافحة';
	@override String get stepReady => 'التحضير';
	@override String get stepTransfer => 'النقل';
	@override String get stepComplete => 'الإكمال';
	@override String get stepUsb => 'جهاز تحميل المفاتيح';
	@override String get completed => 'اكتمل';
	@override String get terminated => 'تم الإنهاء';
	@override String get detailPermissionStart => 'التحقق من إذن USB';
	@override String get detailConnectStart => 'الاتصال بجهاز تحميل المفاتيح';
	@override String get detailConnectSuccess => 'نجح الاتصال';
	@override String get detailConnectFail => 'فشل الاتصال';
	@override String get detailHandshakeStart => 'إرسال PAD_LIGHT وانتظار FILE_OK';
	@override String get detailHandshakeSuccess => 'نجحت المصافحة';
	@override String get detailHandshakeTimeout => 'انتهت مهلة المصافحة';
	@override String get detailHandshakeFail => 'فشلت المصافحة';
	@override String get detailReadyStart => 'إرسال PAD_UPLOAD وانتظار READY';
	@override String get detailReadySuccess => 'الجهاز جاهز';
	@override String get detailReadyTimeout => 'انتهت مهلة التحضير';
	@override String get detailReadyFail => 'فشل التحضير';
	@override String get detailTransferStart => 'الإرسال على شكل حزم';
	@override String get detailTransferTimeout => 'انتهت مهلة استقبال الملف، يرجى إعادة توصيل جهاز تحميل المفاتيح';
	@override String get detailComplete => 'استلم جهاز تحميل المفاتيح بنجاح';
	@override String get detailVerifyTimeout => 'انتهت مهلة التحقق';
	@override String get detailVerifyFail => 'فشل التحقق';
	@override String get detailVerifySaveFail => 'فشل الحفظ';
	@override String get detailExportComplete => 'اكتمل: تم تصدير الملف';
	@override String detailPacketSuccess({required Object index}) => 'تم إرسال الحزمة ${index} بنجاح';
	@override String detailPacketFail({required Object index}) => 'فشل إرسال الحزمة ${index}';
	@override String detailPacketTimeout({required Object index}) => 'انتهت مهلة إرسال الحزمة ${index}';
	@override String detailMd5Error({required Object index}) => 'فشل التحقق من MD5 للحزمة ${index}';
	@override String detailSaveError({required Object index}) => 'فشل حفظ الحزمة ${index}';
	@override String get detailError => 'خطأ في نقل USB';
	@override String get detailDeviceRemoved => 'تم فصل جهاز USB';
	@override String get detailKeyLoadSuccess => 'نجح تحميل المفتاح';
}

// Path: pager.injectParams.steps
class Translations$pager$injectParams$steps$ar_MA extends Translations$pager$injectParams$steps$zh {
	Translations$pager$injectParams$steps$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get discovery => 'الاكتشاف';
	@override String get authentication => 'المصادقة';
	@override String get transfer => 'النقل';
	@override String get parse => 'التحليل';
	@override String get finish => 'الإنهاء';
}

// Path: Form.radioManager.alias
class Translations$Form$radioManager$alias$ar_MA extends Translations$Form$radioManager$alias$zh {
	Translations$Form$radioManager$alias$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get placeholder => '12 وحدة من الصينية أو الإنجليزية أو الأرقام أو المسافات أو العربية أو رموز نصف العرض';
	@override String get validate => 'يرجى إدخال الاسم المستعار للجهاز';
	@override String get invalid => 'يحتوي الاسم المستعار على أحرف غير مدعومة';
	@override String get invalidLength => 'يجب أن يكون طول الاسم المستعار من 1 إلى 12 وحدة';
	@override String get help => '1. تحسب كل حرف صيني أو عربي كوحدتين؛ ويحسب كل حرف إنجليزي أو رقم أو مسافة أو رمز نصف عرض كوحدة واحدة. الطول الإجمالي للاسم المستعار من 1 إلى 12 وحدة.\n2. يُسمح فقط بالصينية والعربية والأحرف الإنجليزية والأرقام والمسافات ورموز نصف العرض.\n3. لا يمكن أن يحتوي على \ / : * ? " < > |؛ ولا يمكن أن يبدأ أو ينتهي بمسافة أو نقطة؛ ولا يمكن أن يكون . أو .. فقط.\n';
}

// Path: Form.radioManager.sn
class Translations$Form$radioManager$sn$ar_MA extends Translations$Form$radioManager$sn$zh {
	Translations$Form$radioManager$sn$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get placeholder => '10 أحرف أو أرقام إنجليزية';
	@override String get validate => 'يرجى إدخال رقم SN';
	@override String get invalid => 'يجب أن يكون SN مكونًا من 10 أحرف أو أرقام';
}

// Path: Form.radioManager.location
class Translations$Form$radioManager$location$ar_MA extends Translations$Form$radioManager$location$zh {
	Translations$Form$radioManager$location$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'حتى 50 حرفًا إنجليزيًا أو رقمًا أو مسافة أو رمز "_"';
	@override String get validate => 'لا يمكن أن يكون موقع جهاز الراديو فارغًا';
	@override String get invalid => 'حتى 50 حرفًا إنجليزيًا أو رقمًا أو مسافة أو رمز "_"';
}

// Path: Form.radioManager.consumer
class Translations$Form$radioManager$consumer$ar_MA extends Translations$Form$radioManager$consumer$zh {
	Translations$Form$radioManager$consumer$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'من 5 إلى 30 حرفًا إنجليزيًا أو رقمًا أو مسافة أو رمز "_"';
	@override String get validate => 'لا يمكن أن يكون مستخدم جهاز الراديو فارغًا';
	@override String get invalid => 'من 5 إلى 30 حرفًا إنجليزيًا أو رقمًا أو مسافة أو رمز "_"';
}

// Path: Form.injectEncrypt.name
class Translations$Form$injectEncrypt$name$ar_MA extends Translations$Form$injectEncrypt$name$zh {
	Translations$Form$injectEncrypt$name$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get label => 'الاسم';
	@override String get placeholder => 'يرجى إدخال اسم تحميل المفتاح';
	@override String get validate => 'يرجى إدخال اسم تحميل المفتاح';
}

// Path: Form.paramsInject.deviceType
class Translations$Form$paramsInject$deviceType$ar_MA extends Translations$Form$paramsInject$deviceType$zh {
	Translations$Form$paramsInject$deviceType$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get text => 'نوع الجهاز';
	@override String get validatorText => 'يرجى إدخال نوع الجهاز';
}

// Path: Form.paramsInject.deviceIp
class Translations$Form$paramsInject$deviceIp$ar_MA extends Translations$Form$paramsInject$deviceIp$zh {
	Translations$Form$paramsInject$deviceIp$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get text => 'عنوان IP للجهاز';
	@override String get validatorText => 'يرجى إدخال عنوان IP صالح';
}

// Path: Form.paramsInject.selectKeyLoader
class Translations$Form$paramsInject$selectKeyLoader$ar_MA extends Translations$Form$paramsInject$selectKeyLoader$zh {
	Translations$Form$paramsInject$selectKeyLoader$ar_MA.internal(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get text => 'جهاز تحميل المفاتيح';
	@override String get placeholder => 'يرجى الاختيار';
}
