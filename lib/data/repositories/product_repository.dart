import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/data/services/cloud_storage/firebase_storage_service.dart';
import 'package:tienda_ropa/utils/exceptions/firebase_exceptions.dart';
import 'package:tienda_ropa/utils/exceptions/platform_exceptions.dart';

import '../../features/shop/models/product_model.dart';
import '../../utils/constants/enums.dart';

/// Repositorio para manejar dator y operaciones relacionado con los productos
class ProductRepository extends GetxController {
  static ProductRepository get instance => Get.find();

  /// Instancia de Firestore para la interaccion del database
  final _db = FirebaseFirestore.instance;


  /// Obtener los productos destacados
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final snapshot = await _db.collection('Products').where('IsFeatured', isEqualTo: true).limit(4).get();
      return snapshot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException (e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intente de nuevo.';
    }
  }

  Future<List<ProductModel>> getAllFeaturedProducts() async {
    try {
      final snapshot = await _db.collection('Products').where('IsFeatured', isEqualTo: true).get();
      return snapshot.docs.map((e) => ProductModel.fromSnapshot(e)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException (e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intente de nuevo.';
    }
  }

  /// Obtener productos basado en la marca
  Future<List<ProductModel>> fetchProductsByQuery(Query query) async {
    try {
      final querySnapshot = await query.get();
      final List<ProductModel> productList = querySnapshot.docs.map((doc) => ProductModel.fromQuerySnapshot(doc)).toList();
      return productList;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException (e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intente de nuevo.';
    }
  }

  /// Obtener productos basado en la marca
  Future<List<ProductModel>> getFavouriteProducts(List<String> productIds) async {
    try {
      final snapshot = await _db.collection('Products').where(FieldPath.documentId, whereIn: productIds).get();
      return snapshot.docs.map((querySnapshot) => ProductModel.fromSnapshot(querySnapshot)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException (e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intente de nuevo.';
    }
  }

  Future<List<ProductModel>> getProductsForBrand({required String brandId, int limit = -1}) async {
    try {
      print('🔍 [ProductRepository] getProductsForBrand INICIADO');
      print('📂 [ProductRepository] BrandId buscado: $brandId');
      print('📊 [ProductRepository] Limit: $limit');

      final querySnapshot = limit == -1
          ? await _db.collection('Products').where('Brand.Id', isEqualTo: brandId).get()
          : await _db.collection('Products').where('Brand.Id', isEqualTo: brandId).limit(limit).get();

      print('📦 [ProductRepository] Productos encontrados: ${querySnapshot.docs.length}');

      final products = querySnapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();

      print('✅ [ProductRepository] Productos retornados: ${products.length}');
      for (var product in products) {
        print('  📦 ${product.title} (Brand: ${product.brand?.name})');
      }

      return products;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException (e.code).message;
    } catch (e) {
      throw 'Algo salio mal. Por favor intente de nuevo.';
    }
  }

  Future<List<ProductModel>> getProductsForCategory({required String categoryId, int limit = 4}) async {
    try {
      print('🔍 [ProductRepository] getProductsForCategory INICIADO');
      print('📂 [ProductRepository] CategoryId buscado: $categoryId');
      print('📊 [ProductRepository] Limit: $limit');

      // Obtner todos los documentos donde productId coincida con el categoryId y limitarlos o sin limitarlos basado en el limite
      QuerySnapshot productCategoryQuery = limit == -1
          ? await _db.collection('ProductCategory').where('categoryId', isEqualTo: categoryId).get()
          : await _db.collection('ProductCategory').where('categoryId', isEqualTo: categoryId).limit(limit).get();

      print('📄 [ProductRepository] ProductCategory docs encontrados: ${productCategoryQuery.docs.length}');

      // Extraer productIds de los documentos
      List<String> productIds = productCategoryQuery.docs.map((doc) => doc['productId'] as String).toList();

      print('🆔 [ProductRepository] ProductIds extraídos: $productIds');

      if (productIds.isEmpty) {
        print('⚠️ [ProductRepository] No se encontraron productIds para esta categoría');
        return [];
      }

      // Query para obtener todos los documentos donde brandId esta en la lista de brandIds, FieldPath.documentId para obtner los documentos en Collection
      final productsQuery = await _db.collection('Products').where(FieldPath.documentId, whereIn: productIds).get();

      print('📦 [ProductRepository] Productos encontrados en Products collection: ${productsQuery.docs.length}');

      // Extraer el nombre de la marca u otros datos relevantes del documento
      List<ProductModel> products = productsQuery.docs.map((doc) {
        try {
          final product = ProductModel.fromSnapshot(doc);
          print('  ✅ Producto mapeado: ${product.title} (CategoryId: ${product.categoryId})');
          return product;
        } catch (e) {
          print('  ❌ Error mapeando producto ${doc.id}: $e');
          rethrow;
        }
      }).toList();

      print('🏁 [ProductRepository] Total productos retornados: ${products.length}');
      return products;
    } on FirebaseException catch (e) {
      print('❌ [ProductRepository] FirebaseException: ${e.message}');
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      print('❌ [ProductRepository] PlatformException: ${e.message}');
      throw TPlatformException (e.code).message;
    } catch (e) {
      print('❌ [ProductRepository] Error general: $e');
      throw 'Algo salio mal. Por favor intente de nuevo.';
    }
  }

  /// Actualizar stock del producto después de una compra
  Future<void> updateProductStock(String productId, int quantity) async {
    try {
      // Obtener el producto actual
      final productDoc = await _db.collection('Products').doc(productId).get();

      if (!productDoc.exists) {
        throw 'Producto no encontrado';
      }

      final currentStock = productDoc.data()?['Stock'] ?? 0;
      final currentSold = productDoc.data()?['SoldQuantity'] ?? 0;
      final newStock = currentStock - quantity;
      final newSold = currentSold + quantity;

      // Asegurar que el stock no sea negativo
      if (newStock < 0) {
        throw 'Stock insuficiente para completar la operación';
      }

      // Actualizar el stock y SoldQuantity en Firebase
      await _db.collection('Products').doc(productId).update({
        'Stock': newStock,
        'SoldQuantity': newSold,
      });

      print('✅ Stock actualizado para producto $productId: $currentStock -> $newStock');
      print('✅ SoldQuantity actualizado: $currentSold -> $newSold');

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error al actualizar stock: ${e.toString()}';
    }
  }

  /// Actualizar stock de una variación de producto
  Future<void> updateProductVariationStock(String productId, String variationId, int quantity) async {
    try {
      // Obtener el producto
      final productDoc = await _db.collection('Products').doc(productId).get();

      if (!productDoc.exists) {
        throw 'Producto no encontrado';
      }

      final productData = productDoc.data()!;
      final variations = productData['ProductVariations'] as List<dynamic>;

      // Encontrar y actualizar la variación específica
      bool variationFound = false;
      for (var i = 0; i < variations.length; i++) {
        if (variations[i]['Id'] == variationId) {
          final currentStock = variations[i]['Stock'] ?? 0;
          final newStock = currentStock - quantity;

          if (newStock < 0) {
            throw 'Stock insuficiente para la variación';
          }

          variations[i]['Stock'] = newStock;
          variationFound = true;

          print('✅ Stock de variación actualizado: $currentStock -> $newStock');
          break;
        }
      }

      if (!variationFound) {
        throw 'Variación no encontrada';
      }

      // Actualizar el producto con las variaciones modificadas
      await _db.collection('Products').doc(productId).update({
        'ProductVariations': variations,
      });

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error al actualizar stock de variación: ${e.toString()}';
    }
  }

  /// Subir dummy data a la Cloud Firebase
  Future<void> uploadDummyData(List<ProductModel> products) async {
    try {
      // Subir todos los productos con sus images
      final storage = Get.put(TFirebaseStorageService());

      // Recorrer los productos
      for (var product in products) {
        // Obtener link de imagen desde local assets
        final thumbnail = await storage.getImageDataFromAssets(product.thumbnail);

        // Subir la imagen y obtener la URL
        final url = await storage.uploadImageData('Products/Images', thumbnail, product.thumbnail.toString());

        // Asignar la URL a product.thumbnail atributo
        product.thumbnail = url;

        // Lista de imagenes del producto
        if (product.images != null && product.images!.isNotEmpty) {
          List<String> imagesUrl = [];
          for (var image in product.images!) {
            // Obtener link de imagen desde local assets
            final assetImage = await storage.getImageDataFromAssets(image);

            // Subir imagen y obtener URL
            final url = await storage.uploadImageData('Products/Images', assetImage, image);

            // Asignar URL a product.thumbnail atributo
            imagesUrl.add(url);
          }
          product.images!.clear();
          product.images!.addAll(imagesUrl);
        }

        // Subir Variaciones de Imagenes
        if (product.productType == ProductType.variable.toString()) {
          for (var variation in product.productVariations!) {
            // Obtener datos de la imagen con el link desde local assets
            final assetImage = await storage.getImageDataFromAssets(variation.image);

            // Subir imagen y obtener su URL
            final url = await storage.uploadImageData('Products/Images', assetImage, variation.image);

            // Asignar URL al atributo de variation.image
            variation.image = url;
          }
        }

        // Almacenar productos en Firestore
        await _db.collection("Products").doc(product.id).set(product.toJson());
      }
    } on FirebaseException catch (e) {
      throw e.message!;
    } on SocketException catch (e) {
      throw e.message;
    } on PlatformException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }
}