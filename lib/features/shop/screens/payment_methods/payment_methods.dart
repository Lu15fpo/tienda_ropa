import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tienda_ropa/common/widgets/appbar/appbar.dart';
import 'package:tienda_ropa/features/shop/controllers/payment_method_controller.dart';
import 'package:tienda_ropa/features/shop/screens/payment_methods/add_payment_method.dart';
import 'package:tienda_ropa/features/shop/screens/payment_methods/widgets/single_payment_method.dart';
import 'package:tienda_ropa/utils/constants/colors.dart';
import 'package:tienda_ropa/utils/constants/sizes.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';

/// Pantalla para mostrar todos los métodos de pago del usuario
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodController());

    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: Text(
          'Métodos de Pago',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Obx(
            () => FutureBuilder(
              // Usar key para actualizar cuando cambie refreshData
              key: Key(controller.refreshData.value.toString()),
              future: controller.getAllUserPaymentMethods(),
              builder: (context, snapshot) {
                /// Función de ayuda: Manejo del Loader, No Record o mensaje de error
                final response = TCloudHelperFunctions.checkMultiRecordState(
                  snapshot: snapshot,
                );
                if (response != null) return response;

                final paymentMethods = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paymentMethods.length,
                  itemBuilder: (_, index) {
                    final method = paymentMethods[index];
                    return SinglePaymentMethod(
                      paymentMethod: method,
                      onTap: () => controller.setAsDefault(method),
                      onEdit: () {
                        // TODO: Implementar pantalla de edición
                        Get.snackbar(
                          'Editar',
                          'Funcionalidad de edición en desarrollo',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      onDelete: () => controller.removePaymentMethod(method.id),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),

      /// Botón flotante para agregar nuevo método
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddPaymentMethodScreen()),
        backgroundColor: TColors.primary,
        child: const Icon(Iconsax.add, color: TColors.white),
      ),
    );
  }
}

