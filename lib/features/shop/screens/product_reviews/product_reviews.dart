import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/products/ratings/rating_indicator.dart';
import 'package:tienda_ropa/features/shop/controllers/review_controller.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/features/shop/screens/product_reviews/add_review_screen.dart';
import 'package:tienda_ropa/features/shop/screens/product_reviews/widgets/rating_progress_indicator.dart';
import 'package:tienda_ropa/features/shop/screens/product_reviews/widgets/user_review_card.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';

class ProductReviewsScreen extends StatelessWidget {
  const ProductReviewsScreen({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReviewController());

    // Cargar reseñas del producto cuando se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProductReviews(product.id);
    });

    return Scaffold(
      /// AppBar
      appBar: const TAppBar(
        title: Text('Recomendaciones y Calificación'),
        showBackArrow: true,
      ),

      /// Botón flotante para agregar reseña
      floatingActionButton: Obx(
        () => controller.isLoading.value
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: () {
                  Get.to(() => AddReviewScreen(product: product));
                },
                backgroundColor: TColors.primary,
                icon: const Icon(Iconsax.edit, color: Colors.white),
                label: Text(
                  controller.userReview.value != null
                      ? 'Editar Reseña'
                      : 'Agregar Reseña',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
      ),

      /// Body
      body: Obx(() {
        // Estado de carga
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Texto informativo
              const Text(
                "Calificaciones y recomendaciones son verificadas y son de personas que usan este producto.",
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Resumen de calificaciones
              _buildRatingSummary(context, controller),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Lista de reseñas
              _buildReviewsList(controller),
            ],
          ),
        );
      }),
    );
  }

  /// Widget de resumen de calificaciones
  Widget _buildRatingSummary(BuildContext context, ReviewController controller) {
    return Column(
      children: [
        /// Distribución de ratings
        const TOverallProductRating(),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Rating promedio con estrellas
        TRatingBarIndicator(rating: controller.averageRating.value),
        const SizedBox(height: TSizes.xs),

        /// Contador de reseñas
        Text(
          controller.reviewsCount.value == 0
              ? 'Sin reseñas aún'
              : controller.reviewsCount.value == 1
                  ? '1 reseña'
                  : '${controller.reviewsCount.value} reseñas',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Widget de lista de reseñas
  Widget _buildReviewsList(ReviewController controller) {
    if (controller.productReviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections * 2),
          child: Column(
            children: [
              Icon(
                Iconsax.message_text,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                'No hay reseñas todavía',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: TSizes.xs),
              Text(
                'Sé el primero en dejar una reseña',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: controller.productReviews
          .map((review) => Padding(
                padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                child: UserReviewCard(review: review),
              ))
          .toList(),
    );
  }
}



