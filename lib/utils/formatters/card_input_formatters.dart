import 'package:flutter/services.dart';

/// Formateador para números de tarjeta de crédito
/// Agrega espacios automáticamente cada 4 dígitos
/// Ejemplo: 4242424242424242 → 4242 4242 4242 4242
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todo lo que no sea número
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limitar a 16 dígitos (o 19 para algunas tarjetas)
    final trimmedText = text.length > 19 ? text.substring(0, 19) : text;

    // Agregar espacios cada 4 dígitos
    final buffer = StringBuffer();
    for (int i = 0; i < trimmedText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(trimmedText[i]);
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Formateador para fecha de expiración (MM/YY)
/// Agrega automáticamente la barra diagonal
/// Ejemplo: 1225 → 12/25
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todo lo que no sea número
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limitar a 4 dígitos (MMYY)
    final trimmedText = text.length > 4 ? text.substring(0, 4) : text;

    // Agregar barra diagonal después del mes
    String formattedText = trimmedText;
    if (trimmedText.length >= 2) {
      formattedText = '${trimmedText.substring(0, 2)}/${trimmedText.substring(2)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Formateador para CVV
/// Limita la entrada a 3 o 4 dígitos (según el tipo de tarjeta)
class CVVInputFormatter extends TextInputFormatter {
  final int maxLength;

  CVVInputFormatter({this.maxLength = 4});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todo lo que no sea número
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limitar a maxLength dígitos
    final trimmedText = text.length > maxLength ? text.substring(0, maxLength) : text;

    return TextEditingValue(
      text: trimmedText,
      selection: TextSelection.collapsed(offset: trimmedText.length),
    );
  }
}

/// Formateador para nombre del titular
/// Convierte automáticamente a mayúsculas y elimina números
class CardHolderNameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar números y caracteres especiales, mantener letras y espacios
    final text = newValue.text.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), '');

    // Convertir a mayúsculas
    final upperText = text.toUpperCase();

    return TextEditingValue(
      text: upperText,
      selection: TextSelection.collapsed(offset: upperText.length),
    );
  }
}

/// Formateador genérico que solo permite números
class NumericOnlyInputFormatter extends TextInputFormatter {
  final int? maxLength;

  NumericOnlyInputFormatter({this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar todo lo que no sea número
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Aplicar límite de longitud si está definido
    final trimmedText = maxLength != null && text.length > maxLength!
        ? text.substring(0, maxLength!)
        : text;

    return TextEditingValue(
      text: trimmedText,
      selection: TextSelection.collapsed(offset: trimmedText.length),
    );
  }
}

