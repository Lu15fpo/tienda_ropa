import 'package:get/get.dart';
import 'package:tienda_ropa/data/repositories/review/review_repository.dart';
import 'package:tienda_ropa/features/personalization/controllers/user_controller.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/features/shop/models/review_model.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

/// Controlador para manejar la lógica de reseñas y calificaciones
class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  /// Variables
  final reviewRepository = ReviewRepository.instance;
  final userController = UserController.instance;

  /// Observables
  RxBool isLoading = false.obs;
  RxList<ReviewModel> productReviews = <ReviewModel>[].obs;
  RxDouble averageRating = 0.0.obs;
  RxInt reviewsCount = 0.obs;
  Rx<ReviewModel?> userReview = Rx<ReviewModel?>(null);
  RxDouble selectedRating = 0.0.obs;

  /// Resetear valores
  void resetForm() {
    selectedRating.value = 0.0;
    userReview.value = null;
  }

  /// Cargar reseñas de un producto
  Future<void> loadProductReviews(String productId) async {
    try {
      isLoading.value = true;

      // Obtener todas las reseñas del producto
      final reviews = await reviewRepository.getProductReviews(productId);
      productReviews.assignAll(reviews);

      // Calcular estadísticas
      await loadProductRatingStats(productId);

      // Verificar si el usuario actual ya dejó una reseña
      await checkUserReview(productId);
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error', message: 'No se pudieron cargar las reseñas');
    } finally {
      isLoading.value = false;
    }
  }

  /// Cargar estadísticas de rating de un producto
  Future<void> loadProductRatingStats(String productId) async {
    try {
      final rating = await reviewRepository.calculateAverageRating(productId);
      final count = await reviewRepository.getReviewsCount(productId);

      averageRating.value = rating;
      reviewsCount.value = count;
    } catch (e) {
      // Log silencioso del error
      print('Error al cargar estadísticas: $e');
    }
  }

  /// Verificar si el usuario actual ya dejó una reseña
  Future<void> checkUserReview(String productId) async {
    try {
      final userId = userController.user.value.id;
      final review =
          await reviewRepository.getUserReviewForProduct(productId, userId);

      userReview.value = review;
      if (review != null) {
        selectedRating.value = review.rating;
      }
    } catch (e) {
      print('Error al verificar reseña del usuario: $e');
    }
  }

  /// Agregar o actualizar reseña
  Future<void> saveReview(
      ProductModel product, String comment, double rating) async {
    try {
      // Validaciones
      if (rating < 1.0 || rating > 5.0) {
        TLoaders.warningSnackBar(
            title: 'Rating inválido',
            message: 'Por favor selecciona una calificación entre 1 y 5 estrellas');
        return;
      }

      if (comment.trim().isEmpty) {
        TLoaders.warningSnackBar(
            title: 'Comentario requerido',
            message: 'Por favor escribe un comentario sobre el producto');
        return;
      }

      if (comment.trim().length < 10) {
        TLoaders.warningSnackBar(
            title: 'Comentario muy corto',
            message: 'El comentario debe tener al menos 10 caracteres');
        return;
      }

      isLoading.value = true;

      final user = userController.user.value;

      // Verificar si el usuario ya tiene una reseña
      final hasReviewed =
          await reviewRepository.hasUserReviewed(product.id, user.id);

      if (hasReviewed && userReview.value != null) {
        // Actualizar reseña existente
        final updatedReview = userReview.value!.copyWith(
          rating: rating,
          comment: comment.trim(),
          updatedAt: DateTime.now(),
        );

        await reviewRepository.updateReview(updatedReview);
        TLoaders.successSnackBar(
            title: '¡Actualizado!',
            message: 'Tu reseña ha sido actualizada exitosamente');
      } else {
        // Crear nueva reseña
        final newReview = ReviewModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: product.id,
          userId: user.id,
          userName: '${user.firstName} ${user.lastName}',
          userProfileImage: user.profilePicture,
          rating: rating,
          comment: comment.trim(),
          createdAt: DateTime.now(),
        );

        await reviewRepository.addReview(newReview);
        TLoaders.successSnackBar(
            title: '¡Éxito!',
            message: 'Tu reseña ha sido publicada exitosamente');
      }

      // Recargar reseñas del producto
      await loadProductReviews(product.id);

      // Resetear formulario
      resetForm();

      // Volver a la pantalla anterior
      Get.back();
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error', message: 'No se pudo guardar la reseña');
    } finally {
      isLoading.value = false;
    }
  }

  /// Eliminar reseña
  Future<void> deleteReview(String productId, String reviewId) async {
    try {
      isLoading.value = true;

      await reviewRepository.deleteReview(productId, reviewId);

      TLoaders.successSnackBar(
          title: 'Eliminado', message: 'Tu reseña ha sido eliminada');

      // Recargar reseñas
      await loadProductReviews(productId);
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error', message: 'No se pudo eliminar la reseña');
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener reseñas del usuario actual
  Future<void> loadUserReviews() async {
    try {
      isLoading.value = true;

      final userId = userController.user.value.id;
      final reviews = await reviewRepository.getUserReviews(userId);

      productReviews.assignAll(reviews);
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error',
          message: 'No se pudieron cargar tus reseñas');
    } finally {
      isLoading.value = false;
    }
  }

  /// Validar si el usuario puede dejar una reseña
  /// (Por ejemplo, solo si ha comprado el producto)
  Future<bool> canUserReview(String productId) async {
    try {
      // TODO: Implementar lógica para verificar si el usuario compró el producto
      // Por ahora, permitir a cualquier usuario autenticado dejar reseña
      return userController.user.value.id.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtener el color según el rating
  String getRatingColor(double rating) {
    if (rating >= 4.5) return 'green';
    if (rating >= 3.5) return 'lightGreen';
    if (rating >= 2.5) return 'orange';
    if (rating >= 1.5) return 'deepOrange';
    return 'red';
  }

  /// Obtener descripción del rating
  String getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excelente';
    if (rating >= 3.5) return 'Muy Bueno';
    if (rating >= 2.5) return 'Bueno';
    if (rating >= 1.5) return 'Regular';
    return 'Malo';
  }

  /// Calcular distribución de ratings (para gráficos)
  Map<int, int> getRatingDistribution() {
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var review in productReviews) {
      int ratingInt = review.rating.round();
      distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;
    }

    return distribution;
  }

  /// Obtener porcentaje de un rating específico
  double getRatingPercentage(int rating) {
    if (reviewsCount.value == 0) return 0.0;

    int count =
        productReviews.where((r) => r.rating.round() == rating).length;
    return (count / reviewsCount.value) * 100;
  }

  /// Formatear fecha de reseña
  String formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Hace ${difference.inMinutes} minutos';
      }
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      return 'Hace ${(difference.inDays / 7).floor()} semanas';
    } else if (difference.inDays < 365) {
      return 'Hace ${(difference.inDays / 30).floor()} meses';
    } else {
      return 'Hace ${(difference.inDays / 365).floor()} años';
    }
  }
}

