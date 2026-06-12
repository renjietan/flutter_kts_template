String parseDateTime(DateTime dt) {
  // 补零函数：如果数字小于10，前面加0
  String _pl(int n) => n.toString().padLeft(2, '0');

  return '${dt.year}-${_pl(dt.month)}-${_pl(dt.day)} '
      '${_pl(dt.hour)}:${_pl(dt.minute)}:${_pl(dt.second)}';
}