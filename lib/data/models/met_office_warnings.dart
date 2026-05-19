import 'package:json_annotation/json_annotation.dart';

part 'met_office_warnings.g.dart';

/// Met Office Severe Weather Warnings — `/warnings/active` endpoint.
///
/// Shape is documented at https://datahub.metoffice.gov.uk.
@JsonSerializable(explicitToJson: true)
class MetOfficeWarningsResponse {
  const MetOfficeWarningsResponse({required this.warnings});

  final List<MetOfficeWarning> warnings;

  factory MetOfficeWarningsResponse.fromJson(Map<String, dynamic> json) =>
      _$MetOfficeWarningsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficeWarningsResponseToJson(this);
}

@JsonSerializable()
class MetOfficeWarning {
  const MetOfficeWarning({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.warningType,
    required this.validFrom,
    required this.validTo,
    this.regions,
  });

  final String id;
  final String title;
  final String description;
  final String severity; // "yellow" | "amber" | "red"
  final String warningType; // rain | wind | snow | ice | fog | thunderstorm
  final String validFrom;
  final String validTo;
  final List<String>? regions;

  factory MetOfficeWarning.fromJson(Map<String, dynamic> json) =>
      _$MetOfficeWarningFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficeWarningToJson(this);
}
