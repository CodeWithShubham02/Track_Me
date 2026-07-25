class FieldModel {
  final String id;
  final String fieldLabel;
  final String fieldName;
  final String fieldType;
  final String isRequired;
  final String sortOrder;

  FieldModel({
    required this.id,
    required this.fieldLabel,
    required this.fieldName,
    required this.fieldType,
    required this.isRequired,
    required this.sortOrder,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json["id"].toString(),
      fieldLabel: json["field_label"] ?? "",
      fieldName: json["field_name"] ?? "",
      fieldType: json["field_type"] ?? "",
      isRequired: json["is_required"].toString(),
      sortOrder: json["sort_order"].toString(),
    );
  }
}