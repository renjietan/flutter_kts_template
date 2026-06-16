import 'package:flutter/cupertino.dart';

mixin ParamsInjectMixin<T extends StatefulWidget> on State<T> {
  List<Uri> paths = [];

  Future<List<Uri>> getTreeData() async {
    await Future.delayed(Duration(seconds: 3));
    paths = [
      Uri.parse('file:///documents/1'),
      Uri.parse('file:///documents/images/2'),
      Uri.parse('file:///documents/images/3'),
      Uri.parse('file:///downloads/1'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/2'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/3'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/4'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/5'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/6'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/7'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/8'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/9'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/10'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/11'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/12'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/13'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/14'),
      Uri.parse('file:///downloads/music/5'),
      Uri.parse('file:///downloads/15'),
      Uri.parse('file:///downloads/music/5'),
    ];
    return paths;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
}
