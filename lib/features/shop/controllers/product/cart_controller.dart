import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/controllers/product/variation_controller.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';
import 'package:tienda_ropa/utils/constants/enums.dart';
import 'package:tienda_ropa/utils/local_storage/storage_utility.dart';
import 'package:tienda_ropa/utils/popups/loaders.dart';

import '../../models/cart_item_model.dart';

class CartController extends GetxController {
  static CartController get instance => Get.find();

  // Variables
  RxInt noOfCartItems = 0.obs;
  RxDouble totalCartPrice = 0.0.obs;
  RxInt productQuantityInCart = 0.obs;
  RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final variationController = VariationController.instance;

  CartController() {
    loadCartItems();
  }

  // Agregar articulo al carrito
  void addToCart(ProductModel product) {
    // Verificar cantidad
    if(productQuantityInCart.value < 1) {
      TLoaders.customToast(message: 'Selecciona Cantidad');
      return;
    }

    if(product.productType == ProductType.variable.toString() && variationController.selectedVariation.value.id.isEmpty){
      TLoaders.customToast(message: 'Selecciona una variacion');
      return;
    }

    // Verificación de Stock
    if (product.productType == ProductType.variable.toString()) {
      final availableStock = variationController.selectedVariation.value.stock;

      // Verificar si hay stock disponible
      if (availableStock < 1) {
        TLoaders.warningSnackBar(title: 'Oh Vaya!', message: 'No hay stock disponible');
        return;
      }

      // Verificar si la cantidad solicitada excede el stock disponible
      if (productQuantityInCart.value > availableStock) {
        TLoaders.warningSnackBar(
          title: 'Stock insuficiente',
          message: 'Solo hay $availableStock unidades disponibles'
        );
        return;
      }
    } else {
      final availableStock = product.stock;

      // Verificar si hay stock disponible
      if (availableStock < 1) {
        TLoaders.warningSnackBar(title: 'Oh Vaya!', message: 'Producto seleccionado agotado');
        return;
      }

      // Verificar si la cantidad solicitada excede el stock disponible
      if (productQuantityInCart.value > availableStock) {
        TLoaders.warningSnackBar(
          title: 'Stock insuficiente',
          message: 'Solo hay $availableStock unidades disponibles'
        );
        return;
      }
    }

    // Convertir el ProductModel a CartItemModel con la cantidad seleccionada
    final selectedCartItem = convertToCartItem(product, productQuantityInCart.value);
    
    // Verificar si el producto ya esta en el carrito
    int index = cartItems.indexWhere((cartItem) => cartItem.productId == selectedCartItem.productId && cartItem.variationId == selectedCartItem.variationId);

    if(index >= 0){
      // Esta cantidad ya esta agregada o actualizada/eliminada del carrito
      cartItems[index].quantity = selectedCartItem.quantity;
    } else {
      cartItems.add(selectedCartItem);
    }

    updateCart();
    TLoaders.customToast(message: 'Tu producto fue agregado al carrito');
  }

  void addOneToCart(CartItemModel item) {
    int index = cartItems.indexWhere((cartItem) => cartItem.productId == item.productId && cartItem.variationId == item.variationId);

    if (index >= 0) {
      cartItems[index].quantity += 1;
    } else {
      cartItems.add(item);
    }

    updateCart();
  }

  void removeOneFromCart(CartItemModel item) {
    int index = cartItems.indexWhere((cartItem) => cartItem.productId == item.productId && cartItem.variationId == item.variationId);

    if (index >= 0) {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity -= 1;
      } else {
        // Mostrar un dialogo despues de eliminar el producto completamente
        cartItems[index].quantity == 1 ? removeFromCartDialog(index) : cartItems.removeAt(index);
      }
      updateCart();
    }
  }

  void removeFromCartDialog(int index) {
    Get.defaultDialog(
      title: 'Eliminar Producto',
      middleText: 'Estas seguro de eliminar este producto?',
      onConfirm: () {
        // Eliminar el item del carrito
        cartItems.removeAt(index);
        updateCart();
        TLoaders.customToast(message: 'Tu producto fue eliminado del carrito');
        Get.back();
      },
      onCancel: () => () => Get.back(),
    );
  }

  /// -- Inicializar ya se agrego contador de items en el carrito
  void updateAlreadyAddedProductCount(ProductModel product) {
    // Si el producto no tiene variaciones entonces calcula la cantidad de productos en el carrito y despliega el total
    // Si no hace por defecto las entradas a 0 y muestra las entradas en el carrito cuando la variacion esta seleccionada
    if (product.productType == ProductType.single.toString()) {
      productQuantityInCart.value = getProductQuantityInCart(product.id);
    } else {
      // Obtener variaciones seleccionada si existe
      final variationId = variationController.selectedVariation.value.id;
      if (variationId.isNotEmpty) {
        productQuantityInCart.value = getVariationQuantityInCart(product.id, variationId);
      } else {
        productQuantityInCart.value = 0;
      }
    }
  }

  /// Esta funcion convierte ProductModel a CartItemModel
  CartItemModel convertToCartItem(ProductModel product, int quantity) {
    if(product.productType == ProductType.single.toString()) {
      // Reiniciar la seleccion de variacion en caso de que solo exista un tipo de producto.
      variationController.resetSelectedAttributes();
    }

    final variation = variationController.selectedVariation.value;
    final isVariation = variation.id.isNotEmpty;
    final price = isVariation
        ? variation.salePrice > 0.0
        ? variation.salePrice
        : variation.price
        : product.salePrice > 0.0
        ? product.salePrice
        : product.price;

    return CartItemModel(
      productId: product.id,
      title: product.title,
      price: price,
      quantity: quantity,
      variationId: variation.id,
      image: isVariation ? variation.image : product.thumbnail,
      brandName: product.brand != null ? product.brand!.name : '',
      selectedVariation: isVariation ? variation.attributeValues : null,
    );
  }

  /// Actualizar valores del Carrito
  void updateCart() {
    updateCartTotals();
    saveCartItems();
    cartItems.refresh();
  }

  void updateCartTotals() {
    double calculatedTotalPrice = 0.0;
    int calculatedNoOfCartItems = 0;

    for (var item in cartItems) {
      calculatedTotalPrice += (item.price) * item.quantity.toDouble();
      calculatedNoOfCartItems += item.quantity;
    }

    totalCartPrice.value = calculatedTotalPrice;
    noOfCartItems.value = calculatedNoOfCartItems;
  }

  void saveCartItems() {
    final cartItemStrings = cartItems.map((item) => item.toJson()).toList();
    TLocalStorage.instance().writeData('cartItems', cartItemStrings);
  }

  void loadCartItems() {
    final cartItemStrings = TLocalStorage.instance().readData<List<dynamic>>('cartItems');
    if (cartItemStrings != null) {
      cartItems.assignAll(cartItemStrings.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)));
      updateCartTotals();
    }
  }

  int getProductQuantityInCart(String productId) {
    final foundItem = cartItems.where((item) => item.productId == productId).fold(0, (previousValue, element) => previousValue + element.quantity);
    return foundItem;
  }

  int getVariationQuantityInCart(String productId, String variationId) {
    final foundItem = cartItems.firstWhere(
        (item) => item.productId == productId && item.variationId == variationId,
      orElse: () => CartItemModel.empty(),
    );

    return foundItem.quantity;
  }

  void clearCart() {
    productQuantityInCart.value = 0;
    cartItems.clear();
    updateCart();
  }
}