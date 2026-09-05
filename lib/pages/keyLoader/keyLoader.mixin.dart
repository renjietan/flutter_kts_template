import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/loading/simple.async.loading.dart';
import 'package:flutter_kts_template/utils/provider/keyloader.provider.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:unified_popups/unified_popups.dart';

import '../../api/KeyLoaders.api.dart';
import '../../components/TextField/simple.form.textfield.dart';
import '../../components/dialog/simple.form.dialog.dart';
import '../../components/loading/simple.loading.dart';
import '../../core/entities/keyLoaders/keyLoadersEntity.dart';
import '../../i18n/handle/translations.g.dart';
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
    Pop.loading();
    KeyLoadersApi.getAll().then((res) {
      if (mounted) {
        context.read<KeyLoaderProvider>().setKeyLoaders = res.data.list;
      }
      SimpleAsyncPopup.hideLoading(Duration(milliseconds: 200));
      setState(() {
        data = res.data.list;
        totalItems = res.data.total;
        selectKeyLoader = data.isNotEmpty ? data[0] : null;
        refreshToken++;
      });
    });
  }

  void create(Map<String, dynamic> v) {
    KeyLoadersApi.create(v).then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
  }

  void delete(KeyLoadersEntity data) {
    KeyLoadersApi.delete("${data.id}").then((res) {
      SimplePopup.success(t.common.OperationSuccess);
      getList();
    });
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

    SimpleFormDialog(
      title: t.button.radioManager.createRadio,
      confirmText: t.button.radioManager.createRadio,
      confirmBtnWidth: 160,
      fields: [
        FormFieldConfig(
          name: 'name',
          label: t.Form.injectEncrypt.name.label,
          hintText: t.Form.injectEncrypt.name.placeholder,
          textEditingController: nameTextEditController,
          validators: [
            FormBuilderValidators.required(
              errorText: t.Form.injectEncrypt.name.validate,
            ),
          ],
        ),
      ],
      onConfirm: (v) {
        if (type == DialogTypeEnum.create) {
          create(v);
        } else {
          update(data!, v);
        }
      },
    );
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
