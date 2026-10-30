// ignore_for_file: cpd_lints/hardcoded_dimension
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/pages/cpds/widgets/cpds_button_styles.dart';
import 'package:flutter_kts_template/utils/provider/keyloader.provider.dart';
import 'package:flutter_kts_template/utils/provider/radios.provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

import '../../api/KeyLoaders.api.dart';
import '../../api/RadiosManagerApi.dart';
import '../../components/TextField/simple.form.textfield.dart';
import '../../components/dialog/simple.form.dialog.dart';
import '../../components/loading/simple.loading.dart';
import '../../core/cpds/service/cpds_manager.dart';
import '../../core/entities/keyLoaders/keyLoadersEntity.dart';
import '../../i18n/handle/translations.g.dart';
import '../../logger/logger.dart';
import '../../utils/enum/dialog_enum.dart';
import 'keyLoader.pager.dart';

mixin KeyLoaderMixin on State<KeyLoaderPager> {
  // =============================================================================
  // 2026/7/7  接口
  // =============================================================================
  KeyLoadersEntity? selectKeyLoader;
  List<KeyLoadersEntity> data = [];
  int totalItems = 0;
  int refreshToken = 0;
  final nameTextEditController = TextEditingController();

  void getList() {
    if (!CpdsManager.instance.hasPackage) return;
    KeyLoadersApi.getAll().then((res) {
      if (mounted) {
        context.read<KeyLoaderProvider>().setKeyLoaders = res.data.list;
      }
      setState(() {
        data = res.data.list;
        totalItems = res.data.total;
        selectKeyLoader = data.isNotEmpty ? data[0] : null;
        refreshToken++;
      });
    });
  }

  void getRadios() {
    RadiosManagerApi.getAll()
        .then((res) {
          if (mounted) {
            context.read<RadiosProvider>().setRadios = res.data.list;
          }
        })
        .catchError((Object error) {
          GlobalLogger.logError('refresh radios failed: $error');
        });
  }

  void create(Map<String, dynamic> v) {
    KeyLoadersApi.create(v).then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
  }

  Future<void> delete(KeyLoadersEntity data) async {
    if (!await _confirmDelete()) return;
    KeyLoadersApi.delete("${data.id}").then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF20262D),
        title: Text(
          t.tips.title,
          style: TextStyle(color: Colors.white, fontSize: 17.sp),
        ),
        content: Text(
          t.tips.keyLoaders.confirmDelete,
          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              t.tips.cancel,
              style: TextStyle(color: Colors.white70, fontSize: 13.sp),
            ),
          ),
          FilledButton(
            style: cpdsFilledButtonStyle(),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              t.common.confirm,
              style: TextStyle(color: Colors.white70, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void update(KeyLoadersEntity? data, Map<String, dynamic> v) {
    KeyLoadersApi.update(data!.id, data: v).then((res) {
      getList();
      SimplePopup.success(t.common.OperationSuccess);
    });
  }

  // =============================================================================
  // 2026/7/7  widget
  // =============================================================================

  Future<void> showCustomDialog(
    DialogTypeEnum type,
    KeyLoadersEntity? data,
  ) async {
    nameTextEditController.text = type == DialogTypeEnum.create
        ? ""
        : (data?.name ?? '');

    final isCreate = type == DialogTypeEnum.create;

    final title = isCreate
        ? t.button.injectEncrypt.createKeyLoader
        : t.button.radioManager.edit;
    final confirmText = isCreate
        ? t.button.injectEncrypt.create
        : t.button.radioManager.save;
    final fields = <FormFieldConfig>[
      FormFieldConfig(
        name: 'name',
        label: t.Form.injectEncrypt.name.label,
        hintText: t.Form.injectEncrypt.name.placeholder,
        textEditingController: nameTextEditController,
        required: true,
        validators: [
          FormBuilderValidators.required(
            errorText: t.Form.injectEncrypt.name.validate,
          ),
        ],
      ),
    ];

    void onConfirm(Map<String, dynamic> v) {
      if (type == DialogTypeEnum.create) {
        create(v);
      } else {
        update(data!, v);
      }
    }

    if (defaultTargetPlatform != TargetPlatform.windows) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SimpleFormPage(
            title: title,
            confirmText: confirmText,
            fields: fields,
            onConfirm: onConfirm,
          ),
        ),
      );
    } else {
      SimpleFormDialog(
        title: title,
        confirmText: confirmText,
        confirmBtnMinWidth: 160,
        fields: fields,
        onConfirm: onConfirm,
      );
    }
  }

  Widget buildEmptyWidget(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              t.common.noData,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
