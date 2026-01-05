import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/models/review_model.dart';
import 'package:tienda_ropa/utils/exceptions/firebase_exceptions.dart';
import 'package:tienda_ropa/utils/exceptions/platform_exceptions.dart';

/// Repositorio para manejar datos y operaciones relacionadas con las reseñas
class ReviewRepository extends GetxController {
  static ReviewRepository get instance => Get.find();

  /// Instancia de Firestore para la interacción con la base de datos
  final _db = FirebaseFirestore.instance;

  /// Agregar una nueva reseña a un producto
  Future<void> addReview(ReviewModel review) async {
    try {
      // Referencia a la subcolección de reseñas del producto
      final reviewRef = _db
          .collection('Products')
          .doc(review.productId)
          .collection('Reviews')
          .doc(review.id);

      // Guardar la reseña en Firebase
      await reviewRef.set(review.toJson());

      // Actualizar el rating promedio y contador del producto
      await _updateProductRatingStats(review.productId);

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al agregar la reseña. Por favor intente de nuevo.';
    }
  }

  /// Obtener todas las reseñas de un producto específico
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .orderBy('CreatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al obtener las reseñas. Por favor intente de nuevo.';
    }
  }

  /// Obtener todas las reseñas de un usuario específico
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      // Nota: Esta query requiere un índice compuesto en Firebase
      final snapshot = await _db
          .collectionGroup('Reviews')
          .where('UserId', isEqualTo: userId)
          .orderBy('CreatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al obtener las reseñas del usuario. Por favor intente de nuevo.';
    }
  }

  /// Verificar si un usuario ya ha dejado una reseña en un producto
  Future<bool> hasUserReviewed(String productId, String userId) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .where('UserId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al verificar la reseña. Por favor intente de nuevo.';
    }
  }

  /// Obtener la reseña de un usuario para un producto específico
  Future<ReviewModel?> getUserReviewForProduct(String productId, String userId) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .where('UserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ReviewModel.fromSnapshot(snapshot.docs.first);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al obtener la reseña. Por favor intente de nuevo.';
    }
  }

  /// Actualizar una reseña existente
  Future<void> updateReview(ReviewModel review) async {
    try {
      final reviewRef = _db
          .collection('Products')
          .doc(review.productId)
          .collection('Reviews')
          .doc(review.id);

      // Actualizar la fecha de modificación
      final updatedReview = review.copyWith(updatedAt: DateTime.now());

      await reviewRef.update(updatedReview.toJson());

      // Actualizar el rating promedio y contador del producto
      await _updateProductRatingStats(review.productId);

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al actualizar la reseña. Por favor intente de nuevo.';
    }
  }

  /// Eliminar una reseña
  Future<void> deleteReview(String productId, String reviewId) async {
    try {
      await _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .doc(reviewId)
          .delete();

      // Actualizar el rating promedio y contador del producto
      await _updateProductRatingStats(productId);

    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al eliminar la reseña. Por favor intente de nuevo.';
    }
  }

  /// Calcular el rating promedio de un producto
  Future<double> calculateAverageRating(String productId) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      for (var doc in snapshot.docs) {
        final review = ReviewModel.fromSnapshot(doc);
        totalRating += review.rating;
      }

      return totalRating / snapshot.docs.length;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al calcular el rating. Por favor intente de nuevo.';
    }
  }

  /// Obtener el contador de reseñas de un producto
  Future<int> getReviewsCount(String productId) async {
    try {
      final snapshot = await _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .get();

      return snapshot.docs.length;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al contar las reseñas. Por favor intente de nuevo.';
    }
  }

  /// Método privado para actualizar las estadísticas de rating en el producto
  Future<void> _updateProductRatingStats(String productId) async {
    try {
      final averageRating = await calculateAverageRating(productId);
      final reviewsCount = await getReviewsCount(productId);

      // Actualizar el documento del producto con las nuevas estadísticas
      await _db.collection('Products').doc(productId).update({
        'AverageRating': averageRating,
        'ReviewsCount': reviewsCount,
      });
    } catch (e) {
      // Log del error pero no lanzar excepción para no interrumpir el flujo
      print('Error al actualizar estadísticas del producto: $e');
    }
  }

  /// Obtener reseñas con paginación
  Future<List<ReviewModel>> getProductReviewsPaginated(
    String productId, {
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _db
          .collection('Products')
          .doc(productId)
          .collection('Reviews')
          .orderBy('CreatedAt', descending: true)
          .limit(limit);

      // Si hay un último documento, comenzar después de él
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Algo salió mal al obtener las reseñas. Por favor intente de nuevo.';
    }
  }
}

