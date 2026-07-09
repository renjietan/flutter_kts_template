import 'package:composable_data_table/composable_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/TextField/simple.textfield.dart';
import 'package:flutter_kts_template/components/button/base.button.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';

import '../../i18n/handle/translations.g.dart';
import '../../icons/hy_icons.dart';
import 'fileUploads.mixin.dart';

typedef OnFilePathChange = void Function(String path);

class FileUploads extends StatefulWidget {
  final OnFilePathChange onUpdate;

  const FileUploads({super.key, required this.onUpdate});

  @override
  State<FileUploads> createState() => _FileUploadsState();
}

class _FileUploadsState extends State<FileUploads> with FileUploadsMixin {
  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return TableFilterToolbar(
      mainFilters: [
        DataTablePlusThemeProvider(
          theme: getThemePreset(ThemePreset.dark),
          child: SimpleTextfield(
            height: 35,
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            controller: simpleTextController,
            readonly: true,
            hint: t.TextField.select,
          ),
        ),
        BaseButton(
          label: t.button.radioManager.browse,
          width: 100,
          icon: HyIcons.wenjian,
          isLoading: isUploadLoading,
          onPressed: () {
            pickFiles();
          },
        ),
        Container(
          // FlareButton 没有边框可供配置,所以在 FlareButton  外围套了一层 container,此 container 只作边框使用
          width: 70,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Color(0xFF00A2E9), width: 2),
          ),
          child: Center(
            child: BaseButton(
              label: t.button.radioManager.parse,
              width: 66,
              height: 30,
              isLoading: isUploadLoading,
              colors: const [
                Color(0xFF0A1D35),
                Color(0xFF0A1D35),
                Color(0xFF0A1D35),
                Color(0xFF0A1D35),
              ],
              onPressed: () {
                parseFile();
              },
            ),
          ),
        ),
      ],
      trailingActions: [],
    );
  }
}
