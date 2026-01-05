import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/appbar/tabbar.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/search_container.dart';
import 'package:tienda_ropa/common/widgets/layouts/grid_layout.dart';
import 'package:tienda_ropa/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/features/shop/controllers/category_controller.dart';
import 'package:tienda_ropa/features/shop/screens/brand/all_brands.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

import '../../../../common/widgets/brands/brand_card.dart';
import '../../../../common/widgets/shimmers/brands_shimmer.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/brand_controller.dart';
import '../brand/brand_products.dart';
import 'widgets/category_tab.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandController = Get.put(BrandController());
    final categories = CategoryController.instance.featuredCategories;

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        appBar: TAppBar(
          title:
          Text('Tienda', style: Theme
              .of(context)
              .textTheme
              .headlineMedium),
          actions: [
            TCartCounterIcon(
                ///onPressed: () => Get.to(() => const CartScreen()),
                iconColor: (THelperFunctions.isDarkMode(context)
                    ? TColors.white
                    : TColors.black)),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                backgroundColor: THelperFunctions.isDarkMode(context)
                    ? TColors.black
                    : TColors.white,
                expandedHeight: 440,
                flexibleSpace: Padding(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [

                      /// -- Barra de busqueda
                      const SizedBox(height: TSizes.spaceBtwItems),
                      const TSearchContainer(
                        text: 'Buscar en la Tienda',
                        showBorder: true,
                        showBackground: false,
                      ),
                      const SizedBox(height: TSizes.spaceBtwSections),

                      ///  -- Marcas Destacadas
                      TSectionHeading(title: 'Marcas Destacadas', onPressed: () => Get.to(() => const AllBrandsScreen())),
                      const SizedBox(height: TSizes.spaceBtwItems / 1.5),

                      /// -- GRID Marcas
                      Obx(
                        () {
                          if (brandController.isLoading.value) return const TBrandsShimmer();

                          if (brandController.featuredBrands.isEmpty) {
                            return Center(
                              child: Text('No se encontro datos!', style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.white)));
                          }
                          return TGridLayout(
                            itemCount: brandController.featuredBrands.length,
                            mainAxisExtent: 80,
                            itemBuilder: (_, index) {
                              final brand = brandController.featuredBrands[index];
                              return TBrandCard(
                                showBorder: true,
                                brand: brand,
                                onTap: () => Get.to(() => BrandProducts(brand: brand)),
                              );
                            },
                          );
                        }
                      ),
                    ],
                  ),
                ),

                /// Tabs
                bottom: TTabBar(tabs: categories.map((category) => Tab(child: Text(category.name))).toList()
                ),
              ),
            ];
          },
          body: TabBarView(children: categories.map((category) => TCategoryTab(category: category)).toList()),
        ),
      ),
    );
  }
}



