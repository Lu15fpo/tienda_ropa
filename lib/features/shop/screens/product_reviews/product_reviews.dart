import 'package:flutter/material.dart';
import 'package:tienda_ropa/features/shop/screens/product_reviews/widgets/rating_progress_indicator.dart';
import 'package:tienda_ropa/features/shop/screens/product_reviews/widgets/user_review_card.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/ratings/rating_indicator.dart';
import '../../../../utils/constants/sizes.dart';

class ProductReviewsScreen extends StatelessWidget {
  const ProductReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// - Appbar
      appBar: const TAppBar(title: Text('Recomendaciones y Calificacion'), showBackArrow: true),

      /// -- Cuerpo
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Calificaciones y recomendaciones son verificadas y son de personas que han usado el mismo tipo de dispositivo que usas."),
            const SizedBox(height: TSizes.spaceBtwItems),

            /// Todos las calificaciones de los productos
            const TOverallProductRating(),
            const TRatingBarIndicator(rating: 3.5),
            Text("12.611", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: TSizes.spaceBtwSections),

            /// Recomendaciones de los usuarios
            const UserReviewCard(),
            const UserReviewCard(),
            const UserReviewCard(),
            const UserReviewCard(),
          ],
        ),
      ),
    );
  }
}


