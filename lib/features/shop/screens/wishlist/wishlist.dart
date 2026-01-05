import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/icons/t_circular_icon.dart';
import 'package:tienda_ropa/common/widgets/layouts/grid_layout.dart';
import 'package:tienda_ropa/common/widgets/loaders/animation_loader.dart';
import 'package:tienda_ropa/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:tienda_ropa/common/widgets/shimmers/vertical_product_shimmer.dart';
import 'package:tienda_ropa/features/shop/controllers/home_controller.dart';
import 'package:tienda_ropa/features/shop/controllers/product/favourites_controller.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';

import '../../../../navigation_menu.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FavouritesController.instance;
    return Scaffold(
      appBar: TAppBar(
        title: Text('Favoritos', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          TCircularIcon(icon: Iconsax.add, onPressed: () => Get.to(HomeController())),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Obx(
              () => FutureBuilder(
                future: controller.favoriteProducts(),
                builder: (context, snapshot) {
                  /// Widget No se encontro nada
                  final emptyWidget = TAnimationLoaderWidget(
                    text: 'Ooops! No hay productos favoritos...',
                    animation: TImages.pencilAnimation,
                    showAction: true,
                    actionText: 'Vamos agregar algo',
                    onActionPressed: () => Get.off(() => const NavigationMenu()),
                  );

                  const loader = TVerticalProductShimmer(itemCount: 6);
                  final widget = TCloudHelperFunctions.checkMultiRecordState(snapshot: snapshot, loader: loader, nothingFound: emptyWidget);
                  if (widget != null) return widget;

                  final products = snapshot.data!;
                  return TGridLayout(itemCount: products.length, itemBuilder: (_, index) => TProductCardVertical(product: products[index]));
                }
              ),
            ),
          ),
        ),
    );
  }
}