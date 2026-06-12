class LoginModel {
  int? code;
  String? msg;
  Map<String, dynamic>? data;

  LoginModel({this.code, this.msg, this.data});

  LoginModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    msg = json['msg'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['msg'] = msg;
    data['data'] = data;
    return data;
  }
}