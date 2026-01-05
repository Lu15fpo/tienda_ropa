import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tienda_ropa/features/shop/controllers/review_controller.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/features/shop/screens/product_reviews/product_reviews.dart';

import '../../../../../utils/constants/sizes.dart';

class TRatingAndShare extends StatelessWidget {
  const TRatingAndShare({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReviewController());

    // Cargar estadísticas de reseñas al construir el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProductRatingStats(product.id);
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Calificación - Clickeable para ir a reseñas
        InkWell(
          onTap: () {
            Get.to(() => ProductReviewsScreen(product: product));
          },
          borderRadius: BorderRadius.circular(TSizes.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: TSizes.xs,
              horizontal: TSizes.sm,
            ),
            child: Obx(() {
              return Row(
                children: [
                  const Icon(Iconsax.star5, color: Colors.amber, size: 24),
                  const SizedBox(width: TSizes.spaceBtwItems / 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: controller.averageRating.value > 0
                              ? controller.averageRating.value.toStringAsFixed(1)
                              : '0.0',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        TextSpan(
                          text: ' (${controller.reviewsCount.value})',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),

        /// Botón de compartir
        IconButton(
          onPressed: () {
            // Compartir información del producto
            final String shareText = '''
¡Mira este producto increíble! 🛍️

${product.title}
${product.brand != null ? 'Marca: ${product.brand!.name}' : ''}
Precio: \$${product.salePrice > 0 ? product.salePrice : product.price}

${product.description ?? 'Sin descripción disponible'}

🔗 [En desarrollo - URL del producto estará disponible próximamente]
ID del Producto: ${product.id}
''';
            SharePlus.instance.share(
                ShareParams(text: shareText, subject: product.title));
          },
          icon: const Icon(Icons.share, size: TSizes.iconMd),
        ),
      ],
    );
  }
}
