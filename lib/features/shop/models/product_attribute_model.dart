
class ProductAttributeModel {
  String? name;
  final List<String>? values;

  ProductAttributeModel({this.name, this.values});

  /// Formato Json
  Map<String, Object?> toJson() {
    return {'Name': name, 'Values': values};
  }

  /// Mapeado Json orientado al documento de Firebase a Model
  factory ProductAttributeModel.fromJson(Map<String, dynamic> document) {
    final data = document;

    if (data.isEmpty) return ProductAttributeModel();

    return ProductAttributeModel(
      name: data.containsKey('Name') ? data['Name'] : '',
      values: List<String>.from(data['Values']),
    );
  }
}