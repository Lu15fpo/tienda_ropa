import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:tienda_ropa/common/widgets/success_screen/success_screen.dart';
import 'package:tienda_ropa/features/shop/controllers/product/cart_controller.dart';
import 'package:tienda_ropa/features/shop/controllers/product/checkout_controller.dart';
import 'package:tienda_ropa/utils/constants/enums.dart';
import 'package:tienda_ropa/utils/constants/image_strings.dart';
import 'package:tienda_ropa/utils/popups/full_screen_loader.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/order/order_repository.dart';
import '../../../../data/repositories/product_repository.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/helpers/pricing_calculator.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../models/order_model.dart';

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  /// Variables
  final cartController = CartController.instance;
  final addressController = AddressController.instance;
  final checkoutController = CheckoutController.instance;
  final orderRepository = Get.put(OrderRepository());

  /// Obtener historial de pedido de usuarios
  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      final userOrders = await orderRepository.fetchUserOrders();
      return userOrders;
    } catch (e) {
      TLoaders.warningSnackBar(title: 'Oh Vaya!', message: e.toString());
      return [];
    }
  }

  /// Agregar metodo para procesar el pedido
  void processOrder(double totalAmount) async {
    try {
      // Validar que haya una dirección seleccionada
      if (addressController.selectedAddress.value.id.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'Dirección requerida',
          message: 'Por favor selecciona una dirección de envío antes de continuar.'
        );
        return;
      }

      // Empezar Carga
      TFullScreenLoader.openLoadingDialog('Procesando Orden', TImages.pencilAnimation);

      // Obtener ID de autentificacion de usuario
      final userId = AuthenticationRepository.instance.authUser.uid;
      if (userId.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: 'Error', message: 'No se pudo obtener el usuario.');
        return;
      }

      print('📍 [OrderController] Dirección seleccionada: ${addressController.selectedAddress.value.name}');
      print('📍 [OrderController] Dirección completa: ${addressController.selectedAddress.value.toString()}');

      // Obtener subtotal del carrito
      final subTotal = cartController.totalCartPrice.value;
      final location = 'US'; // Puedes cambiarlo según la ubicación del usuario

      // Calcular costos individuales
      final shippingCost = double.parse(TPricingCalculator.calculateShippingCost(subTotal, location));
      final taxCost = double.parse(TPricingCalculator.calculateTax(subTotal, location));
      final discount = 0.0; // Aquí puedes agregar lógica de descuentos si existe

      // Agregar Detalles
      final order = OrderModel(
        // Generar un ID unico para el pedido
        id: UniqueKey().toString(),
        userId: userId,
        status: OrderStatus.pending,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
        paymentMethod: checkoutController.selectedPaymentMethod.value.name,
        address: addressController.selectedAddress.value,
        // Calcular fecha de entrega
        deliveryDate: DateTime.now(),
        items: cartController.cartItems.toList(),
        // Agregar desglose de costos
        shippingCost: shippingCost,
        taxCost: taxCost,
        discount: discount,
      );

      // Guardar pedido en Firestore
      await orderRepository.saveOrder(order, userId);

      // Actualizar stock de productos en Firebase
      try {
        print('📦 Actualizando stock de productos...');
        for (var item in cartController.cartItems) {
          if (item.variationId != null && item.variationId!.isNotEmpty) {
            // Producto con variación
            await ProductRepository.instance.updateProductVariationStock(
              item.productId,
              item.variationId!,
              item.quantity
            );
          } else {
            // Producto simple
            await ProductRepository.instance.updateProductStock(
              item.productId,
              item.quantity
            );
          }
        }
        print('✅ Stock actualizado correctamente');
      } catch (e) {
        print('⚠️ Error actualizando stock: $e');
        // No detenemos el proceso, solo registramos el error
      }

      // Actualizar estado del carrito
      cartController.clearCart();

      // Mostrar pantalla de confirmacion
      Get.off(() => SuccessScreen(
        image: TImages.orderCompletedAnimation,
        title: 'Pago Satisfactorio!',
        subTitle: 'Tu pedido sera enviado pronto!',
        onPressed: () => Get.offAll(() => const NavigationMenu()),
      ));
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Vaya!', message: e.toString());
    }
  }
}