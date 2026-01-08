import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/texts/section_heading.dart';
import 'package:tienda_ropa/data/repositories/payment_method/payment_method_repository.dart';
import 'package:tienda_ropa/features/shop/models/payment_method_model.dart';
import 'package:tienda_ropa/utils/constants/image_strings.dart';
import 'package:tienda_ropa/utils/helpers/cloud_helper_functions.dart';
import 'package:tienda_ropa/utils/helpers/network_manager.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../utils/constants/sizes.dart';

/// Controlador para gestionar métodos de pago del usuario
class PaymentMethodController extends GetxController {
  static PaymentMethodController get instance => Get.find();

  /// Variables
  final cardHolderName = TextEditingController();
  final cardNumber = TextEditingController();
  final expiryDate = TextEditingController();
  final cvv = TextEditingController();
  GlobalKey<FormState> paymentMethodFormKey = GlobalKey<FormState>();

  /// Observables
  RxBool refreshData = true.obs;
  final Rx<PaymentMethodModel> selectedPaymentMethod = PaymentMethodModel.empty().obs;
  final RxString detectedCardType = ''.obs;
  final RxBool isDefault = false.obs;

  // Variables reactivas para actualizar CardPreview en tiempo real
  final RxString cardNumberPreview = ''.obs;
  final RxString cardHolderNamePreview = ''.obs;
  final RxString expiryDatePreview = ''.obs;

  /// Repositorio
  final paymentMethodRepository = Get.put(PaymentMethodRepository());

  @override
  void onInit() {
    super.onInit();
    // Cargar el método de pago predeterminado al iniciar
    loadDefaultPaymentMethod();

    // Agregar listeners para actualizar el preview en tiempo real
    cardNumber.addListener(() => cardNumberPreview.value = cardNumber.text);
    cardHolderName.addListener(() => cardHolderNamePreview.value = cardHolderName.text);
    expiryDate.addListener(() => expiryDatePreview.value = expiryDate.text);
  }

  /// Cargar método de pago predeterminado
  Future<void> loadDefaultPaymentMethod() async {
    try {
      final defaultMethod = await paymentMethodRepository.fetchDefaultPaymentMethod();
      if (defaultMethod != null) {
        selectedPaymentMethod.value = defaultMethod;
      }
    } catch (e) {
      // Si no hay método predeterminado, no hacer nada
    }
  }

  /// Obtener todos los métodos de pago del usuario
  Future<List<PaymentMethodModel>> getAllUserPaymentMethods() async {
    try {
      final paymentMethods = await paymentMethodRepository.fetchUserPaymentMethods();

      // Si hay métodos, actualizar el seleccionado si no está establecido
      if (paymentMethods.isNotEmpty && selectedPaymentMethod.value.id.isEmpty) {
        selectedPaymentMethod.value = paymentMethods.firstWhere(
          (element) => element.isDefault,
          orElse: () => paymentMethods.first,
        );
      }

      return paymentMethods;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
      return [];
    }
  }

  /// Detectar tipo de tarjeta mientras el usuario escribe
  void onCardNumberChanged(String value) {
    final type = PaymentMethodModel.detectCardType(value);
    detectedCardType.value = type;
  }

  /// Formatear el número de tarjeta mientras escribe
  String formatCardNumberInput(String value) {
    return PaymentMethodModel.formatCardNumber(value);
  }

  /// Seleccionar un método de pago
  Future<void> selectPaymentMethod(PaymentMethodModel newSelectedMethod) async {
    try {
      Get.defaultDialog(
        title: '',
        onWillPop: () async => false,
        barrierDismissible: false,
        backgroundColor: Colors.transparent,
        content: const CircularProgressIndicator(),
      );

      // Actualizar el método seleccionado
      selectedPaymentMethod.value = newSelectedMethod;

      // Cerrar diálogo
      Get.back();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error en la selección', message: e.toString());
    }
  }

  /// Agregar un nuevo método de pago
  Future<void> addNewPaymentMethod() async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog(
        'Agregando método de pago...',
        TImages.docerAnimation,
      );

      // Revisar la conexión a internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validación del formulario
      if (!paymentMethodFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Detectar tipo de tarjeta
      final cardType = PaymentMethodModel.detectCardType(cardNumber.text.trim());
      if (cardType == 'Unknown') {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'Tarjeta no válida',
          message: 'El número de tarjeta ingresado no es válido.',
        );
        return;
      }

      // Obtener últimos 4 dígitos
      final last4 = PaymentMethodModel.getLast4Digits(cardNumber.text.trim());

      // Crear el método de pago
      final paymentMethod = PaymentMethodModel(
        id: '',
        cardHolderName: cardHolderName.text.trim().toUpperCase(),
        cardNumberLast4: last4,
        cardType: cardType,
        expiryDate: expiryDate.text.trim(),
        isDefault: isDefault.value,
        createdAt: DateTime.now(),
      );

      // Guardar en Firebase
      final id = await paymentMethodRepository.addPaymentMethod(paymentMethod);

      // Actualizar el método con su ID
      paymentMethod.id = id;

      // Si es predeterminado o es el primero, seleccionarlo
      if (isDefault.value || selectedPaymentMethod.value.id.isEmpty) {
        selectedPaymentMethod.value = paymentMethod;
      }

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Mensaje de confirmación
      TLoaders.successSnackBar(
        title: '¡Éxito!',
        message: 'Tu método de pago fue agregado correctamente.',
      );

      // Actualizar datos
      refreshData.toggle();

      // Reiniciar campos
      resetFormFields();

      // Redireccionar
      Navigator.of(Get.context!).pop();
    } catch (e) {
      // Eliminar Carga
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Actualizar un método de pago existente
  Future<void> updatePaymentMethod(PaymentMethodModel paymentMethod) async {
    try {
      // Empezar Carga
      TFullScreenLoader.openLoadingDialog(
        'Actualizando método de pago...',
        TImages.docerAnimation,
      );

      // Revisar la conexión a internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Actualizar en Firebase
      await paymentMethodRepository.updatePaymentMethod(paymentMethod);

      // Si se marcó como predeterminado, actualizar el seleccionado
      if (paymentMethod.isDefault) {
        selectedPaymentMethod.value = paymentMethod;
      }

      // Eliminar Carga
      TFullScreenLoader.stopLoading();

      // Mensaje de confirmación
      TLoaders.successSnackBar(
        title: '¡Actualizado!',
        message: 'El método de pago fue actualizado correctamente.',
      );

      // Actualizar datos
      refreshData.toggle();
    } catch (e) {
      // Eliminar Carga
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Eliminar un método de pago
  Future<void> removePaymentMethod(String paymentMethodId) async {
    try {
      // Confirmar eliminación
      Get.defaultDialog(
        title: '¿Eliminar método de pago?',
        middleText: 'Esta acción no se puede deshacer.',
        textConfirm: 'Eliminar',
        textCancel: 'Cancelar',
        confirmTextColor: Colors.white,
        onConfirm: () async {
          // Cerrar diálogo de confirmación
          Get.back();

          // Empezar Carga
          TFullScreenLoader.openLoadingDialog(
            'Eliminando método de pago...',
            TImages.docerAnimation,
          );

          // Revisar la conexión a internet
          final isConnected = await NetworkManager.instance.isConnected();
          if (!isConnected) {
            TFullScreenLoader.stopLoading();
            return;
          }

          // Eliminar de Firebase
          await paymentMethodRepository.removePaymentMethod(paymentMethodId);

          // Si era el método seleccionado, limpiar selección
          if (selectedPaymentMethod.value.id == paymentMethodId) {
            selectedPaymentMethod.value = PaymentMethodModel.empty();
            // Cargar el nuevo predeterminado
            await loadDefaultPaymentMethod();
          }

          // Eliminar Carga
          TFullScreenLoader.stopLoading();

          // Mensaje de confirmación
          TLoaders.successSnackBar(
            title: 'Eliminado',
            message: 'El método de pago fue eliminado correctamente.',
          );

          // Actualizar datos
          refreshData.toggle();
        },
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Establecer como método predeterminado
  Future<void> setAsDefault(PaymentMethodModel paymentMethod) async {
    try {
      // Empezar Carga
      Get.defaultDialog(
        title: '',
        onWillPop: () async => false,
        barrierDismissible: false,
        backgroundColor: Colors.transparent,
        content: const CircularProgressIndicator(),
      );

      // Actualizar el método
      final updatedMethod = paymentMethod.copyWith(isDefault: true);
      await paymentMethodRepository.updatePaymentMethod(updatedMethod);

      // Actualizar el método seleccionado
      selectedPaymentMethod.value = updatedMethod;

      // Cerrar diálogo
      Get.back();

      // Mensaje de confirmación
      TLoaders.successSnackBar(
        title: 'Predeterminado',
        message: 'El método de pago fue establecido como predeterminado.',
      );

      // Actualizar datos
      refreshData.toggle();
    } catch (e) {
      Get.back();
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    }
  }

  /// Modal para seleccionar método de pago (para checkout)
  Future<dynamic> selectPaymentMethodPopup(BuildContext context) {
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
                      /// Función de ayuda: Manejo del Loader, No Record o mensaje de error
                      final response = TCloudHelperFunctions.checkMultiRecordState(
                        snapshot: snapshot,
                      );
                      if (response != null) return response;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (_, index) {
                          final paymentMethod = snapshot.data![index];
                          return ListTile(
                            contentPadding: const EdgeInsets.all(0),
                            onTap: () async {
                              await selectPaymentMethod(paymentMethod);
                              Get.back();
                            },
                            leading: Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(TSizes.sm),
                              ),
                              child: Center(
                                child: Text(
                                  paymentMethod.cardType ?? '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(paymentMethod.maskedCardNumber),
                            subtitle: Text(paymentMethod.cardHolderName ?? ''),
                            trailing: paymentMethod.isDefault
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
                    onPressed: () {
                      Get.back();
                      // Navegar a pantalla de agregar método
                      // Get.to(() => const AddPaymentMethodScreen());
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

  /// Función para reiniciar los campos del formulario
  void resetFormFields() {
    cardHolderName.clear();
    cardNumber.clear();
    expiryDate.clear();
    cvv.clear();
    detectedCardType.value = '';
    isDefault.value = false;
    paymentMethodFormKey.currentState?.reset();
  }

  /// Validar número de tarjeta usando algoritmo de Luhn
  bool validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanNumber.isEmpty || cleanNumber.length < 13) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10 == 0);
  }

  /// Validar fecha de expiración
  bool validateExpiryDate(String expiryDate) {
    if (expiryDate.isEmpty || !expiryDate.contains('/')) return false;

    final parts = expiryDate.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    // Convertir YY a YYYY
    final fullYear = year < 100 ? 2000 + year : year;
    final now = DateTime.now();
    final expiry = DateTime(fullYear, month);

    // Verificar que no haya expirado
    return expiry.isAfter(DateTime(now.year, now.month));
  }

  @override
  void onClose() {
    cardHolderName.dispose();
    cardNumber.dispose();
    expiryDate.dispose();
    cvv.dispose();
    super.onClose();
  }
}

