import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tienda_ropa/features/shop/models/category_model.dart';

import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../../services/cloud_storage/firebase_storage_service.dart';

class CategoryRepository extends GetxController {
  static CategoryRepository get instance => Get.find();

  /// Variables
  final _db = FirebaseFirestore.instance;

  /// Obtener todas las categorias
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      print('🔍 [CategoryRepository] Obteniendo categorías desde Firebase...');
      final snapshot = await _db.collection('Categories').get();
      print('📊 [CategoryRepository] Documentos encontrados: ${snapshot.docs.length}');
      final list = snapshot.docs.map((document) => CategoryModel.fromSnapshot(document)).toList();
      print('✅ [CategoryRepository] Categorías parseadas: ${list.length}');
      for (var cat in list) {
        print('  📂 ${cat.name} - IsFeatured: ${cat.isFeatured}, ParentId: "${cat.parentId}"');
      }
      return list;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intentalo de nuevo';
    }
  }

  /// Obtener Sub Categorias

  Future<List<CategoryModel>> getSubCategories(String categoryId) async {
    try {

      final snapshot = await _db.collection('Categories').where('parentId', isEqualTo: categoryId).get();
      final result = snapshot.docs.map((e) => CategoryModel.fromSnapshot(e)).toList();
      return result;

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intentalo de nuevo';
    }
  }

  /// Subir las categorias a Cloud Firebase
  Future<void> uploadDummyData(List<CategoryModel> categories) async {
    try {
      // Subir todas las categorias con sus respectivas imagenes
      final storage = Get.put(TFirebaseStorageService());

      // Listar todas las categorias
      for (var category in categories) {
        // Obtener ImageData atraves del link del local assets
        final file = await storage.getImageDataFromAssets(category.image);

        // Subir las imagenes y obtener el URL de la imagen
        final url = await storage.uploadImageData('Categorias', file, category.name);

        // Asignar el URL a Category.image atributo
        category.image = url;

        // Almacenar Categoria en Firestore
        await _db.collection('Categorias').doc(category.id).set(category.toJson());
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intentalo de nuevo';
    }
  }
}