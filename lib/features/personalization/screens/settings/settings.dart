import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:tienda_ropa/common/widgets/list_tiles/settings_menu_tile.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/features/shop/screens/order/order.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';

import '../../../../common/widgets/list_tiles/user_profile_tile.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../shop/screens/cart/cart.dart';
import '../address/address.dart';
import '../profile/profile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen ({super.key});

  @override
  Widget build (BuildContext context){
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// -- Encabezado
            TPrimaryHeaderContainer(
                child: Column(
                  children: [
                    TAppBar(title: Text('Cuenta', style: Theme.of(context).textTheme.headlineMedium!.apply(color:TColors.white))),

                    /// Tarjeta de perfil de Usuario
                    TUserProfileTile(onPressed: () => Get.to(() => const ProfileScreen())),
                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],
                ),
            ),
            /// -- Cuerpo
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Column(
                children: [
                  /// -- Configuracion de Cuenta
                  const TSectionHeading(title: 'Configuracion de Cuenta', showActionButton: false),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  TSettingsMenuTile(
                      icon: Iconsax.safe_home,
                      title: 'Mis Direcciones',
                      subTitle: 'Agregar o Editar Direcciones',
                      onTap: () => Get.to(() => const UserAddressScreen()),
                  ),
                  TSettingsMenuTile(
                      icon: Iconsax.shopping_cart,
                      title: 'Carrito de Compras',
                      subTitle: 'Agregar, eliminar y procesar pedidos',
                      onTap: () => Get.to(() => const CartScreen()),
                  ),
                  TSettingsMenuTile(
                      icon: Iconsax.bag_tick,
                      title: 'Mis Pedidos',
                      subTitle: 'Progreso y pedidios completados',
                      onTap: () => Get.to(() => const OrderScreen())
                  ),
                  const TSettingsMenuTile(
                      icon: Iconsax.bank,
                      title: 'Cuenta Bancaria',
                      subTitle: 'Retirar saldo a cuenta bancaria'),
                  const TSettingsMenuTile(
                      icon: Iconsax.discount_shape,
                      title: 'Mis cupones',
                      subTitle: 'Lista de todos los cupones de descuento'),
                  const TSettingsMenuTile(
                      icon: Iconsax.notification,
                      title: 'Notificaciones',
                      subTitle: 'Establecer mensajes de notificacion'),
                  const TSettingsMenuTile(
                      icon: Iconsax.security_card,
                      title: 'Privacidad de Cuenta',
                      subTitle:
                          'Administracion de datos de cuentas conectadas'),

                  /// -- Configuracion de App
                  SizedBox(height: TSizes.spaceBtwSections),
                  TSectionHeading(title: 'Configuracion', showActionButton: false),
                  SizedBox(height: TSizes.spaceBtwItems),
                  TSettingsMenuTile(icon: Iconsax.document_upload, title: 'Cargar datos', subTitle: 'Subir datos a tu cuenta de Firebase'),
                  TSettingsMenuTile(
                      icon: Iconsax.location,
                      title: 'Ubicacion',
                      subTitle: 'Establcer recomendaciones basado en la ubicacion',
                      trailing: Switch(value: true, onChanged: (value) {})
                  ),
                  TSettingsMenuTile(
                      icon: Iconsax.security_user,
                      title: 'Modo Seguro',
                      subTitle: 'Buscar resultados de manera seguro para todas las edades',
                      trailing: Switch(value: false, onChanged: (value) {})
                  ),
                  TSettingsMenuTile(
                      icon: Iconsax.location,
                      title: 'Calidad de imagen HD',
                      subTitle: 'Establcer calidad de imagen para que sea visible',
                      trailing: Switch(value: false, onChanged: (value) {})
                  ),
                  
                  /// -- Boton de Logout 
                  const SizedBox(height: TSizes.spaceBtwSections),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () async {await AuthenticationRepository.instance.logout();}, child: const Text('Cerrar Sesion')),
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections * 2.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

