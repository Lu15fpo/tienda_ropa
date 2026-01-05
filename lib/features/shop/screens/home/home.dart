import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:tienda_ropa/features/shop/screens/home/widgets/home_appbar.dart';
import 'package:tienda_ropa/features/shop/screens/home/widgets/home_categories.dart';
import 'package:tienda_ropa/features/shop/screens/home/widgets/promo_slider.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../../common/widgets/custom_shapes/containers/search_container.dart';
import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../common/widgets/shimmers/vertical_product_shimmer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/product/product_controller.dart';
import '../all_products/all_products.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductController());
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Encabezado
            const TPrimaryHeaderContainer(
              child: Column(
                children: [
                  /// Barra de navegacion
                  THomeAppBar(),
                  SizedBox(height: TSizes.spaceBtwSections),

                  /// Barra de busqueda
                  TSearchContainer(text: 'Buscar en la tienda', showBorder: false),
                  SizedBox(height: TSizes.spaceBtwSections),

                  /// Barra de categorias
                  Padding(
                    padding: EdgeInsets.only(left: TSizes.defaultSpace),
                    child: Column(
                      children: [
                        /// -- Encabezado
                        TSectionHeading(title: 'Categorias Populares', showActionButton: false, textColor: TColors.white),
                        SizedBox(height: TSizes.spaceBtwItems),

                        /// -- Categorias
                        THomeCategories(),
                      ],
                    ),
                  ),
                  SizedBox(height: TSizes.spaceBtwSections)
                ],
              )
            ),

            /// Body Principal
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  /// -- Deslizador de Promociones
                  const TPromoSlider(),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  /// -- Encabezado
                  TSectionHeading(
                      title: 'Productos Populares',
                      onPressed: () => Get.to(() => AllProducts(
                        title: 'Productos Populares', 
                        futureMethod: controller.fetchAllFeaturedProducts(),
                      )),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  /// -- Productos Populares
                  Obx((){
                    if(controller.isLoading.value) return const TVerticalProductShimmer();

                    if(controller.featuredProducts.isEmpty){
                      return Center(child: Text('No se encontraron Datos', style: Theme.of(context).textTheme.bodyMedium));
                    }
                    return TGridLayout(
                        itemCount: controller.featuredProducts.length,
                        itemBuilder: (_, index) => TProductCardVertical(product: controller.featuredProducts[index]),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

