import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/data/repositories/payment_method/payment_method_repository.dart';
import 'package:tienda_ropa/features/shop/screens/payment_methods/add_payment_method.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';

import '../../../../utils/constants/sizes.dart';
import '../../models/payment_method_model.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance => Get.find();

  final Rx<PaymentMethodModel> selectedPaymentMethod = PaymentMethodModel.empty().obs;
  final paymentMethodRepository = Get.put(PaymentMethodRepository());
  RxBool refreshData = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDefaultPaymentMethod();
  }

  /// Cargar método de pago predeterminado al iniciar
  Future<void> loadDefaultPaymentMethod() async {
    try {
      final defaultMethod = await paymentMethodRepository.fetchDefaultPaymentMethod();
      if (defaultMethod != null) {
        selectedPaymentMethod.value = defaultMethod;
      } else {
        // Si no hay método predeterminado, intentar cargar el primero disponible
        final methods = await paymentMethodRepository.fetchUserPaymentMethods();
        if (methods.isNotEmpty) {
          selectedPaymentMethod.value = methods.first;
        }
      }
    } catch (e) {
      // Si no hay métodos guardados, dejar vacío
    }
  }

  /// Obtener todos los métodos de pago del usuario
  Future<List<PaymentMethodModel>> getAllUserPaymentMethods() async {
    try {
      final paymentMethods = await paymentMethodRepository.fetchUserPaymentMethods();
      return paymentMethods;
    } catch (e) {
      return [];
    }
  }

  /// Seleccionar un método de pago
  Future<void> selectPaymentMethodItem(PaymentMethodModel method) async {
    selectedPaymentMethod.value = method;
    Get.back();
  }

  /// Modal para seleccionar método de pago
  Future<dynamic> selectPaymentMethod(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(TSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TSectionHeading(
                  title: 'Seleccionar Método de Pago',
                  showActionButton: false,
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Obx(
                  () => FutureBuilder(
                    key: Key(refreshData.value.toString()),
                    future: getAllUserPaymentMethods(),
                    builder: (_, snapshot) {
                      /// Manejo de estados
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
                          return ListTile(
                            contentPadding: const EdgeInsets.all(0),
                            onTap: () => selectPaymentMethodItem(method),
                            leading: Container(
                              width: 60,
                              height: 40,
                              padding: const EdgeInsets.all(TSizes.xs),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(TSizes.sm),
                              ),
                              child: Image(
                                image: AssetImage(method.cardTypeImage),
                                fit: BoxFit.contain,
                              ),
                            ),
                            title: Text(method.maskedCardNumber),
                            subtitle: Text(method.cardHolderName ?? ''),
                            trailing: method.isDefault
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      await Get.to(() => const AddPaymentMethodScreen());
                      // Actualizar la lista después de agregar
                      refreshData.toggle();
                      // Recargar el método predeterminado
                      await loadDefaultPaymentMethod();
                    },
                    child: const Text('Agregar nuevo método'),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

