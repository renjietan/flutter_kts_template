import 'package:json_annotation/json_annotation.dart';

part 'GenericResult.g.dart';

@JsonSerializable(includeIfNull: false, genericArgumentFactories: true)
class GenericResult<T> {
  final String? name;
  final T? result;

  GenericResult({this.name, this.result});

  factory GenericResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$GenericResultFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(dynamic Function(T value) toJsonT) =>
      _$GenericResultToJson(this, toJsonT);
}
