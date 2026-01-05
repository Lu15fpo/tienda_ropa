import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/features/shop/controllers/review_controller.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  late final TextEditingController commentController;
  int characterCount = 0;

  @override
  void initState() {
    super.initState();
    final controller = Get.put(ReviewController());
    commentController = TextEditingController();

    // Si el usuario ya tiene una reseña, cargar sus datos
    if (controller.userReview.value != null) {
      commentController.text = controller.userReview.value!.comment;
      controller.selectedRating.value = controller.userReview.value!.rating;
      characterCount = commentController.text.length;
    }

    // Listener para actualizar el contador de caracteres
    commentController.addListener(() {
      setState(() {
        characterCount = commentController.text.length;
      });
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ReviewController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: TAppBar(
        title: Text(
          controller.userReview.value != null
              ? 'Editar Reseña'
              : 'Agregar Reseña',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Información del producto
              _ProductInfoCard(product: widget.product, dark: dark),
              const SizedBox(height: TSizes.spaceBtwSections),

              /// Selector de calificación
              Text(
                'Tu Calificación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              Obx(
                () => Center(
                  child: Column(
                    children: [
                      /// Rating Bar
                      RatingBar.builder(
                        initialRating: controller.selectedRating.value,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemPadding:
                            const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(
                          Iconsax.star1,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          controller.selectedRating.value = rating;
                        },
                        glow: true,
                        glowColor: Colors.amber.withValues(alpha: 0.5),
                        itemSize: 45,
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      /// Descripción del rating
                      if (controller.selectedRating.value > 0)
                        Text(
                          controller.getRatingDescription(
                              controller.selectedRating.value),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .apply(
                                color: _getRatingColorValue(
                                    controller.selectedRating.value),
                              ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              /// Campo de comentario
              Text(
                'Tu Comentario',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              TextFormField(
                controller: commentController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Cuéntanos tu experiencia con este producto...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    borderSide: BorderSide(
                      color: dark ? TColors.darkGrey : TColors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    borderSide: const BorderSide(
                      color: TColors.primary,
                      width: 2,
                    ),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: TSizes.xs),

              /// Contador de caracteres manual
              Text(
                '$characterCount/500 caracteres (mínimo 10)',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              /// Botón de enviar
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            await controller.saveReview(
                              widget.product,
                              commentController.text,
                              controller.selectedRating.value,
                            );
                          },
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            controller.userReview.value != null
                                ? 'Actualizar Reseña'
                                : 'Publicar Reseña',
                          ),
                  ),
                ),
              ),

              /// Botón de cancelar
              const SizedBox(height: TSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    controller.resetForm();
                    Get.back();
                  },
                  child: const Text('Cancelar'),
                ),
              ),

              /// Eliminar reseña (si existe)
              if (controller.userReview.value != null) ...[
                const SizedBox(height: TSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      // Mostrar confirmación
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Eliminar Reseña'),
                          content: const Text(
                              '¿Estás seguro de que deseas eliminar tu reseña? Esta acción no se puede deshacer.'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await controller.deleteReview(
                          widget.product.id,
                          controller.userReview.value!.id,
                        );
                        Get.back(); // Volver a la pantalla anterior
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Eliminar Reseña'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Obtener color según el rating
  Color _getRatingColorValue(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.orange;
    if (rating >= 1.5) return Colors.deepOrange;
    return Colors.red;
  }
}

/// Widget para mostrar información del producto
class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({
    required this.product,
    required this.dark,
  });

  final ProductModel product;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.light,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: dark ? TColors.darkGrey : TColors.grey,
        ),
      ),
      child: Row(
        children: [
          /// Imagen del producto
          ClipRRect(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
            child: Image.network(
              product.thumbnail,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade300,
                child: const Icon(Iconsax.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: TSizes.md),

          /// Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TSizes.xs),
                if (product.brand != null)
                  Text(
                    product.brand!.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: TSizes.xs),
                Text(
                  '\$${product.salePrice > 0 ? product.salePrice : product.price}',
                  style: Theme.of(context).textTheme.titleSmall!.apply(
                        color: TColors.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

