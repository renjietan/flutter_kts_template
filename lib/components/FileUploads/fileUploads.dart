import 'package:composable_data_table/composable_data_table.dart';
import 'package:flare_button/flare_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kts_template/components/TextField/simple.textfield.dart';
import 'package:flutter_kts_template/theme/table.theme.dart';

import '../../icons/hy_icons.dart';
import 'fileUploads.mixin.dart';

class FileUploads extends StatefulWidget {
  const FileUploads({super.key});

  @override
  State<FileUploads> createState() => _FileUploadsState();
}

class _FileUploadsState extends State<FileUploads> with FileUploadsMixin {
  @override
  Widget build(BuildContext context) {
    // 套用
    return TableFilterToolbar(
      mainFilters: [
        DataTablePlusThemeProvider(
          theme: getThemePreset(ThemePreset.dark),
          child: SimpleTextfield(
            height: 35,
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
            value: filePath,
          ),
        ),
        FlareButton(
          textStyle: TextStyle(fontSize: 12, color: Colors.white),
          label: "Browse",
          width: 116,
          height: 34,
          icon: HyIcons.wenjian,
          borderRadius: 5,
          isLoading: isUploadLoading,
          colors: const [
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
            Color(0xFF00A2E9),
          ],
          onPressed: () {
            pickFiles();
          },
        ),
        Container(
          // FlareButton 没有边框可供配置,所以在 FlareButton  外围套了一层 container,此 container 只作边框使用
          width: 84,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Color(0xFF00A2E9), width: 2),
          ),
          child: FlareButton(
            textStyle: TextStyle(fontSize: 12, color: Colors.white),
            label: "Parse",
            width: 80,
            height: 30,
            borderRadius: 5,
            isLoading: isUploadLoading,
            colors: const [
              Color(0xFF0A1D35),
              Color(0xFF0A1D35),
              Color(0xFF0A1D35),
              Color(0xFF0A1D35),
            ],
            onPressed: () {},
          ),
        ),
      ],
      trailingActions: [],
    );
  }
}
