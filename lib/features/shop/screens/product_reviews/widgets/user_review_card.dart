import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import 'package:tienda_ropa/features/shop/controllers/review_controller.dart';
import 'package:tienda_ropa/features/shop/models/review_model.dart';

import '../../../../../common/widgets/products/ratings/rating_indicator.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

class UserReviewCard extends StatelessWidget {
  const UserReviewCard({super.key, required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final controller = ReviewController.instance;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                /// Foto de perfil del usuario
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.userProfileImage.isNotEmpty
                      ? CachedNetworkImageProvider(review.userProfileImage)
                      : null,
                  child: review.userProfileImage.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: TSizes.spaceBtwItems),

                /// Nombre del usuario
                Flexible(
                  child: Text(
                    review.userName,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Rating y fecha
        Row(
          children: [
            TRatingBarIndicator(rating: review.rating),
            const SizedBox(width: TSizes.spaceBtwItems),
            Text(
              controller.formatReviewDate(review.createdAt),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Comentario de la reseña
        ReadMoreText(
          review.comment,
          trimLines: 2,
          trimMode: TrimMode.Line,
          trimExpandedText: ' mostrar menos',
          trimCollapsedText: ' mostrar más',
          moreStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: TColors.primary,
          ),
          lessStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: TColors.primary,
          ),
        ),

        /// Mostrar si fue actualizada
        if (review.updatedAt != null) ...[
          const SizedBox(height: TSizes.xs),
          Text(
            'Editado',
            style: Theme.of(context).textTheme.bodySmall!.apply(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],

        const SizedBox(height: TSizes.spaceBtwItems),
      ],
    );
  }
}