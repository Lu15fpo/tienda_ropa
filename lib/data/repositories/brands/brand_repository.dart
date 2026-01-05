import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/models/brand_model.dart';

import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class BrandRepository extends GetxController {
  static BrandRepository get instance => Get.find();

  /// Variables
  final _db = FirebaseFirestore.instance;


  /// Obtener todas las categorias
  Future<List<BrandModel>> getAllBrands() async {
    try {

      final snapshot = await _db.collection('Brands').get();
      final result = snapshot.docs.map((e) => BrandModel.fromSnapshot(e)).toList();
      return result;

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal al cargar los Banners.';
    }
  }

  /// Obtener Marcas por Categoria

  Future<List<BrandModel>> getBrandsForCategory(String categoryId) async {
    try {
      print('🔍 [BrandRepository] getBrandsForCategory INICIADO');
      print('📂 [BrandRepository] CategoryId buscado: $categoryId');

      // Query para obtener todos los documentos donde categoryId es igual a categoryId
      QuerySnapshot brandCategoryQuery = await _db.collection('BrandCategory').where('categoryId', isEqualTo: categoryId).get();

      print('📄 [BrandRepository] BrandCategory docs encontrados: ${brandCategoryQuery.docs.length}');

      // Extraer brandIds de los documentos
      List<String> brandIds = brandCategoryQuery.docs.map((doc) => doc['brandId'] as String).toList();

      print('🆔 [BrandRepository] BrandIds extraídos: $brandIds');

      if (brandIds.isEmpty) {
        print('⚠️ [BrandRepository] No se encontraron marcas para esta categoría');
        return [];
      }

      // Query para obtner todos los documentos donde el brandId esta en brandIds, FieldPath.documentId a query documentos en Collection
      final brandsQuery = await _db.collection('Brands').where(FieldPath.documentId, whereIn: brandIds).limit(2).get();

      print('📦 [BrandRepository] Marcas encontradas en Brands collection: ${brandsQuery.docs.length}');

      // Extaer lso nombres de las marcas u otros datos relevantes de los documentos
      List<BrandModel> brands = brandsQuery.docs.map((doc) => BrandModel.fromSnapshot(doc)).toList();

      print('✅ [BrandRepository] Marcas retornadas: ${brands.length}');
      for (var brand in brands) {
        print('  🏷️ ${brand.name} (ProductsCount: ${brand.productsCount})');
      }

      return brands;

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salio mal al cargar los Banners.';
    }
  }

  /// Actualizar contador de productos de una marca
  Future<void> updateBrandProductCount(String brandId) async {
    try {
      // Contar productos que tienen esta marca
      final productsQuery = await _db.collection('Products')
          .where('Brand.Id', isEqualTo: brandId)
          .get();

      final productCount = productsQuery.docs.length;

      // Actualizar el contador en la marca
      await _db.collection('Brands').doc(brandId).update({
        'ProductsCount': productCount,
      });

      print('✅ ProductsCount actualizado para marca $brandId: $productCount productos');

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error al actualizar contador de productos de marca: ${e.toString()}';
    }
  }

  /// Recalcular contadores de todas las marcas
  Future<void> recalculateAllBrandProductCounts() async {
    try {
      // Obtener todas las marcas
      final brandsSnapshot = await _db.collection('Brands').get();

      for (var brandDoc in brandsSnapshot.docs) {
        await updateBrandProductCount(brandDoc.id);
      }

      print('✅ Todos los contadores de marcas actualizados');

    } catch (e) {
      throw 'Error al recalcular contadores: ${e.toString()}';
    }
  }
}