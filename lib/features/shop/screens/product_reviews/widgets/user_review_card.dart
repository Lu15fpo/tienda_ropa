import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/rounded_container.dart';

import '../../../../../common/widgets/products/ratings/rating_indicator.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class UserReviewCard extends StatelessWidget {
  const UserReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundImage: AssetImage(TImages.userProfileImage1)),
                const SizedBox(width: TSizes.spaceBtwItems),
                Text('Mabe Mejia', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert)),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Recomendaciones
        Row(
          children: [
            const TRatingBarIndicator(rating: 4),
            const SizedBox(width: TSizes.spaceBtwItems),
            Text('14 Mar, 2025', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        const ReadMoreText(
          'La interfaz de usuario de la aplicacion is muy intuitiva. Es posible navegar y hacer compras de manera amigable. Buen trabajo!',
          trimLines: 1,
          trimMode: TrimMode.Line,
          trimExpandedText: ' mostrar menos',
          trimCollapsedText: ' mostrar mas',
          moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TColors.primary),
          lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TColors.primary),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),

        /// Recomendaciones grupales
        TRoundedContainer(
          backgroundColor: dark ? TColors.darkGrey : TColors.grey,
          child: Padding(
              padding: EdgeInsets.all(TSizes.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mens Locker Clothing', style: Theme.of(context).textTheme.titleMedium),
                      Text('14 Mar, 2025', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const ReadMoreText(
                    'La interfaz de usuario de la aplicacion is muy intuitiva. Es posible navegar y hacer compras de manera amigable. Buen trabajo!',
                    trimLines: 1,
                    trimMode: TrimMode.Line,
                    trimExpandedText: ' mostrar menos',
                    trimCollapsedText: ' mostrar mas',
                    moreStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TColors.primary),
                    lessStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TColors.primary),
                  ),
                ],
              ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
      ],
    );
  }
}