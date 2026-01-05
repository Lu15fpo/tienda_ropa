

class TPricingCalculator {

  /// -- Calcula el Precio basado en tax y el envio
  static double calculateTotalPrice(double productPrice, String location) {
    double taxRate = getTaxRateForLocation(location);
    double taxAmount = productPrice * taxRate;

    double shippingCost = getShippingCost(location);

    double totalPrice = productPrice + taxAmount + shippingCost;
    return totalPrice;
  }

  /// -- Calcula el envio basado en la ubicacion
  static String calculateShippingCost(double productPrice, String location) {
    double shippingCost = getShippingCost(location);
    return shippingCost.toStringAsFixed(2);
  }
  /// -- Calcula el tax
  static String calculateTax(double productPrice, String location) {
    double taxRate = getTaxRateForLocation(location);
    double taxAmount = productPrice * taxRate;
    return taxAmount.toStringAsFixed(2);
  }

  static double getTaxRateForLocation(String location) {
    // Revisa el rango del tax para la ubicacion otorgada basado en una base de datos o API.
    // Retorna el tax apropiado.
    return 0.15; // Ejemplo de tax del 15%
  }

  static double getShippingCost(String location) {
    // Revisa el costo de envio basado en la ubicacion uando una API de envio.
    // Calucla el costo de envio basado en varios factores como distancia, peso, etc.
    return 5.00; // Ejemplo de costo de envio
  }

// /// -- Suma el total de los productos en el carrito y retorna en monto total
// static double calculateCartTotal(CartModel cart) {
//   return cart.items.map((e) => e.price).fold(0, (previousPrice, currentPrice) => previousPrice + (currentPrice ?? 0));
// }
}