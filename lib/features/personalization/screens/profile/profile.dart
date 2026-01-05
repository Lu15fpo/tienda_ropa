import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/images/t_circular_image.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/features/personalization/screens/profile/widgets/change_name.dart';
import 'package:tienda_ropa/features/personalization/screens/profile/widgets/profile_menu.dart';
import 'package:tienda_ropa/common/widgets/shimmers/shimmer.dart';

import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/user_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: Text('Perfil'),
      ),
      /// -- Cuerpo
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              /// Foto de Perfil
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Obx((){
                      final networkImage = controller.user.value.profilePicture;
                      final image = networkImage.isNotEmpty ? networkImage : TImages.user;
                      return controller.imageUploading.value
                          ? const TShimmerEffect(width: 80, height: 80, radius: 80)
                          : TCircularImage(image: image, width: 80, height: 80, isNetworkImage: networkImage.isNotEmpty);
                    }),
                    TextButton(onPressed: () => controller.uploadUserProfilePicture(), child: const Text('Cambiar foto de perfil')),
                  ],
                ),
              ),

              /// Detalles
              const SizedBox(height: TSizes.spaceBtwItems / 2),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Informacion del Perfil Cabezera
              const TSectionHeading(title: 'Informacion del Perfil', showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),

              TProfileMenu(title: 'Nombre', value: controller.user.value.fullName, onPressed: () => Get.to(() => const ChangeName())),
              TProfileMenu(title: 'Usuario', value: controller.user.value.username, onPressed: () {}),

              const SizedBox(height: TSizes.spaceBtwItems / 2),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              /// Cabezera Informacion Personal
              const TSectionHeading(title: 'Informacion Personal', showActionButton: false),
              const SizedBox(height: TSizes.spaceBtwItems),

              TProfileMenu(title: 'ID de Usuario', value: controller.user.value.id, icon: Iconsax.copy, onPressed: () {}),
              TProfileMenu(title: 'E-mail', value: controller.user.value.email, onPressed: () {}),
              TProfileMenu(title: 'Numero de telefono', value: controller.user.value.phoneNumber, onPressed: () {}),
              TProfileMenu(title: 'Genero', value: 'Hombre', onPressed: () {}),
              TProfileMenu(title: 'Fecha de nacimiento', value: '17 Oct, 1997', onPressed: () {}),
              const Divider(),
              const SizedBox(height: TSizes.spaceBtwItems),

              Center(
                child: TextButton(
                    onPressed: () => controller.deleteAccountWarningPopup(),
                    child: const Text('Cerrar Cuenta', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

