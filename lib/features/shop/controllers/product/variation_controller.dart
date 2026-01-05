import 'package:get/get.dart';
import 'package:tienda_ropa/features/shop/controllers/product/images_controller.dart';
import 'package:tienda_ropa/features/shop/models/product_model.dart';

import '../../models/product_variation_model.dart';
import 'cart_controller.dart';

class VariationController extends GetxController {
  static VariationController get instance => Get.find();

  /// Variables
  RxMap selectedAttributes = {}.obs;
  RxString variationStockStatus = ''.obs;
  Rx<ProductVariationModel> selectedVariation = ProductVariationModel.empty().obs;

  /// -- Seleccionar Atributo y variacion
  void onAttributeSelected(ProductModel product, attributeName, attributeValue) {
    // Cuando el atributo esta seleccionado primero agregara esos atributos al selectedAttributes
    final selectedAttributes = Map<String, dynamic>.from(this.selectedAttributes);
    selectedAttributes[attributeName] = attributeValue;
    this.selectedAttributes[attributeName] = attributeValue;

    final selectedVariation = product.productVariations!.firstWhere(
          (variation) => _isSameAttributeValues(variation.attributeValues, selectedAttributes),
          orElse: () => ProductVariationModel.empty(),
    );

    // Mostrar la imagen de la variacion seleccionada
    if (selectedVariation.image.isNotEmpty) {
      ImagesController.instance.selectedProductImage.value = selectedVariation.image;
    }

    // Mostrar ña cantidad seleccionada de la variacion ya existente en el carrito
    if (selectedVariation.id.isNotEmpty) {
      final cartController = CartController.instance;
      cartController.productQuantityInCart.value = cartController.getVariationQuantityInCart(product.id, selectedVariation.id);
    }

    // Asignar la variacion seleccionada
    this.selectedVariation.value = selectedVariation;
  }

  /// -- Revisar si el atributo coincide con algun atributo de variacion
  bool _isSameAttributeValues(Map<String, dynamic> variationAttributes, Map<String, dynamic> selectedAttributes) {
    // Si selectedAttributes contiene 3 atributos y la cariacion contiene 2 entonces se retorna
    if(variationAttributes.length != selectedAttributes.length) return false;

    // Si alguno de estos atributos es diferente se retorna, ejemplo. [Verde, L] x [Verde, M]
    for(final key in variationAttributes.keys) {
      // Attributes[key] = Valor puede ser [Verde, S, Algodon] etc.
      if (variationAttributes[key] != selectedAttributes[key]) return false;
    }

    return true;
  }

  /// -- Revisar disponibilidad de variacion / Stock Variacion
  Set<String?> getAttributesAvailabilityInVariation(List<ProductVariationModel> variations, String attributeName) {
    // Pasar la variacion con un check cuando los atributos esten dsiponibles y el stock no sea 0
    final availableVariationAttributeValues = variations
        .where((variation)  =>
    // Revisar atributos de Vacio / Agotado Stock
    variation.attributeValues[attributeName] != null && variation.attributeValues[attributeName]!.isNotEmpty && variation.stock > 0)
    // Obtner todos los atributos no vacios de las variaciones
    .map((variation) => variation.attributeValues[attributeName])
        .toSet();

    return availableVariationAttributeValues;
  }

  String getVariationPrice(){
    return (selectedVariation.value.salePrice > 0 ? selectedVariation.value.salePrice : selectedVariation.value.price).toString();
  }

  /// -- Revisar stock de variacion
  void getProductVariationStockStatus() {
    variationStockStatus.value = selectedVariation.value.stock > 0 ? 'En Stock' : 'Agotado';
  }

  /// -- Reiniciar seleccion de atributos cuando se cambia de producto
  void resetSelectedAttributes() {
    selectedAttributes.clear();
    variationStockStatus.value = '';
    selectedVariation.value = ProductVariationModel.empty();
  }
}