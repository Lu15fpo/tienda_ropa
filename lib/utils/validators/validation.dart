
class TValidator {
  /// Validacion de Texto Vacio
  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El Email es requerido.';
    }

    // Expresiones regulares para validar el email
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Direccion de Email invalido.';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contraseña es requerida.';
    }

    // Revisar la longitud de la contraseña
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    // Revision de mayusculas
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe tener al menos una letra mayuscula.';
    }

    // Revision de numeros
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe tener al menos un numero.';
    }

    // Revision de caracteres especiales
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'La contraseña debe contener al menos un caracter especial.';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'El numero de telefono es requerido.';
    }

    // Expresiones regulares para validar el numero de telefono
    final phoneRegExp = RegExp(r'^\d{10}$');

    if (!phoneRegExp.hasMatch(value)) {
      return 'Numero de telefono invalido (10 digitos requeridos).';
    }

    return null;
  }

  /// Validar número de tarjeta usando algoritmo de Luhn
  static String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de tarjeta es requerido.';
    }

    // Eliminar espacios y guiones
    final cleanNumber = value.replaceAll(RegExp(r'[\s-]'), '');

    // Verificar que solo contenga números
    if (!RegExp(r'^\d+$').hasMatch(cleanNumber)) {
      return 'El número de tarjeta debe contener solo números.';
    }

    // Verificar longitud mínima
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return 'El número de tarjeta debe tener entre 13 y 19 dígitos.';
    }

    // Algoritmo de Luhn para validar el número
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

    if (sum % 10 != 0) {
      return 'Número de tarjeta inválido.';
    }

    return null;
  }

  /// Validar CVV (Código de seguridad)
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'El CVV es requerido.';
    }

    // Verificar que solo contenga números
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'El CVV debe contener solo números.';
    }

    // CVV debe tener 3 o 4 dígitos (AmEx usa 4)
    if (value.length < 3 || value.length > 4) {
      return 'El CVV debe tener 3 o 4 dígitos.';
    }

    return null;
  }

  /// Validar fecha de expiración (MM/YY)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La fecha de expiración es requerida.';
    }

    // Verificar formato MM/YY
    if (!value.contains('/')) {
      return 'Formato inválido. Use MM/YY';
    }

    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Formato inválido. Use MM/YY';
    }

    // Validar mes
    final month = int.tryParse(parts[0]);
    if (month == null || month < 1 || month > 12) {
      return 'Mes inválido. Debe estar entre 01 y 12.';
    }

    // Validar año
    final year = int.tryParse(parts[1]);
    if (year == null) {
      return 'Año inválido.';
    }

    // Convertir YY a YYYY
    final fullYear = year < 100 ? 2000 + year : year;
    final now = DateTime.now();
    final expiryDate = DateTime(fullYear, month);

    // Verificar que no haya expirado
    if (expiryDate.isBefore(DateTime(now.year, now.month))) {
      return 'La tarjeta ha expirado.';
    }

    return null;
  }

  /// Validar nombre del titular de la tarjeta
  static String? validateCardHolderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre del titular es requerido.';
    }

    // Verificar que tenga al menos 2 caracteres
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres.';
    }

    // Verificar que solo contenga letras y espacios
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre debe contener solo letras.';
    }

    return null;
  }

  /// Validar que el campo tenga solo números
  static String? validateNumericOnly(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido.';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return '$fieldName debe contener solo números.';
    }

    return null;
  }

// Add more custom validators as needed for your specific requirements.
}


