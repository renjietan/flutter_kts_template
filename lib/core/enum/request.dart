enum EnumContentType {
  json('application/json'),
  wwwFormUrlencoded("application/x-www-form-urlencoded"),
  formData("application/form-data"),
  multipart("multipart/form-data");

  final String value;
  const EnumContentType(this.value);
}
