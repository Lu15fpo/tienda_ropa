import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/features/shop/screens/home/home.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/helpers/helper_functions.dart';

import 'features/personalization/screens/settings/settings.dart';
import 'features/shop/screens/store/store.dart';
import 'features/shop/screens/wishlist/wishlist.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) => controller.selectedIndex.value = index,
          backgroundColor: darkMode ? TColors.black : Colors.white,
          indicatorColor: darkMode ? TColors.white.withValues(alpha: 0.1) : TColors.black.withValues(alpha: 0.1),

          destinations: const [
              NavigationDestination(icon: Icon(Iconsax.home), label: 'Inicio'),
              NavigationDestination(icon: Icon(Iconsax.shop), label: 'Tienda'),
              NavigationDestination(icon: Icon(Iconsax.heart), label: 'Favoritos'),
              NavigationDestination(icon: Icon(Iconsax.user), label: 'Perfil'),
            ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}



class NavigationController extends GetxController{
  final Rx<int> selectedIndex = 0.obs;

  final screens = [const HomeScreen(), const StoreScreen(), const FavouriteScreen(), const SettingsScreen()];
}