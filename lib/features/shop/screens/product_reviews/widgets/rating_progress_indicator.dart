import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/controllers/review_controller.dart';
import 'package:tienda_ropa/features/shop/screens/product_reviews/widgets/progress_indicator_and_rating.dart';

class TOverallProductRating extends StatelessWidget {
  const TOverallProductRating({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ReviewController.instance;

    return Obx(() {
      // Si no hay reseñas, mostrar valores por defecto
      if (controller.reviewsCount.value == 0) {
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Text('0.0', style: Theme.of(context).textTheme.displayLarge),
            ),
            const Expanded(
              flex: 7,
              child: Column(
                children: [
                  TRatingProgressIndicator(text: '5', value: 0.0),
                  TRatingProgressIndicator(text: '4', value: 0.0),
                  TRatingProgressIndicator(text: '3', value: 0.0),
                  TRatingProgressIndicator(text: '2', value: 0.0),
                  TRatingProgressIndicator(text: '1', value: 0.0),
                ],
              ),
            ),
          ],
        );
      }

      // Mostrar rating promedio y distribución real
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              controller.averageRating.value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          Expanded(
            flex: 7,
            child: Column(
              children: [
                TRatingProgressIndicator(
                  text: '5',
                  value: controller.getRatingPercentage(5) / 100,
                ),
                TRatingProgressIndicator(
                  text: '4',
                  value: controller.getRatingPercentage(4) / 100,
                ),
                TRatingProgressIndicator(
                  text: '3',
                  value: controller.getRatingPercentage(3) / 100,
                ),
                TRatingProgressIndicator(
                  text: '2',
                  value: controller.getRatingPercentage(2) / 100,
                ),
                TRatingProgressIndicator(
                  text: '1',
                  value: controller.getRatingPercentage(1) / 100,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}