import 'package:cloud_firestore/cloud_firestore.dart';


class BrandModel {
  String name;
  String image;
  int? productsCount;
  bool? isFeatured;
  String id;

  BrandModel({
    required this.name,
    required this.image,
    this.productsCount,
    this.isFeatured,
    required this.id,
  });

  /// Crear una funcion vacia para un codigo limpio
  static BrandModel empty() => BrandModel(id: '', image: '', name: '');

  /// Convertir el modelo a una estrucutura de datos Json asi se podra enviar a Firebase
  Map<String, Object?> toJson () {
    return{
      'Id': id,
      'Name': name,
      'Image': image,
      'ProductsCount': productsCount,
      'IsFeatured': isFeatured,
    };
  }

  /// Mapeado Json orientado al documento de Firebase al UserModel
  factory BrandModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if(data.isEmpty) return BrandModel.empty();
    return BrandModel(
      id: data['Id'] ?? '',
      name: data['Name'] ?? '',
      image: data['Image'] ?? '',
      productsCount: data['ProductsCount'] ?? 0,
      isFeatured: data['IsFeatured'] ?? false,
    );
  }

  /// Mapeado Json orientado al documento de Firebase al UserModel
  factory BrandModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;

      // Mapeado Json al Modelo
      return BrandModel(
        id: document.id,
        name: data['Name'] ?? '',
        image: data['Image'] ?? '',
        productsCount: (data['ProductsCount'] as int?) ?? 0,
        isFeatured: data['IsFeatured'] ?? false,
      );
    } else {
      return BrandModel.empty();
    }
  }
}