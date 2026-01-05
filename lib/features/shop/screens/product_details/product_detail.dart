import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:readmore/readmore.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/features/shop/controllers/product/cart_controller.dart';
import 'package:tienda_ropa/features/shop/controllers/review_controller.dart';
import 'package:tienda_ropa/features/shop/screens/cart/cart.dart';
import 'package:tienda_ropa/features/shop/screens/product_details/widgets/bottom_add_to_cart_widget.dart';
import 'package:tienda_ropa/features/shop/screens/product_details/widgets/product_attributes.dart';
import 'package:tienda_ropa/features/shop/screens/product_details/widgets/product_detail_image_slider.dart';
import 'package:tienda_ropa/features/shop/screens/product_details/widgets/product_meta_data.dart';
import 'package:tienda_ropa/features/shop/screens/product_details/widgets/rating_share_widget.dart';
import 'package:tienda_ropa/utils/constants/enums.dart';

import '../../../../utils/constants/sizes.dart';
import '../../models/product_model.dart';
import '../product_reviews/product_reviews.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    final reviewController = Get.put(ReviewController());

    // Cargar estadísticas de reseñas para el producto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reviewController.loadProductRatingStats(product.id);
    });

    return Scaffold(
      bottomNavigationBar: TBottomAddToCart(product: product),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 1 - Slider de imagenes del producto
            TProductImageSlider(product: product),

            /// 2 - Informacion del producto
            Padding(
              padding: const EdgeInsets.only(right: TSizes.defaultSpace, left: TSizes.defaultSpace, top: TSizes.defaultSpace),
              child: Column(
                children: [
                  /// - Calificacion y Compartir
                  TRatingAndShare(product: product),

                  /// - Precio, Titulo, Cantidad y Talla
                  TProductMetaData(product: product),

                  /// -- Atributos
                  if (product.productType == ProductType.variable.toString()) TProductAttributes(product: product),
                  if (product.productType == ProductType.variable.toString()) const SizedBox(height: TSizes.spaceBtwSections),
                  
                  /// -- Espacio antes del boton de compra
                  const SizedBox(height: TSizes.spaceBtwItems),

                  /// -- Boton de compra
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Agregar producto al carrito
                        cartController.addToCart(product);
                        // Navegar al carrito para revisar antes de pagar
                        Get.to(() => const CartScreen());
                      },
                      child: const Text('Comprar')
                    )
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// - Descripcion
                  const TSectionHeading(title: 'Descripcion', showActionButton: false),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  ReadMoreText(
                    product.description ?? '',
                    trimLines: 2,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: 'Ver mas',
                    trimExpandedText: 'Ver menos',
                    moreStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    lessStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),

                  /// - Recomendaciones
                  const Divider(),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() {
                        final count = reviewController.reviewsCount.value;
                        return TSectionHeading(
                          title: 'Recomendaciones ($count)',
                          showActionButton: false,
                        );
                      }),
                      IconButton(
                        icon: const Icon(Iconsax.arrow_right_3, size: 18),
                        onPressed: () => Get.to(() => ProductReviewsScreen(product: product)),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
