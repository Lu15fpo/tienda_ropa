
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

// Add more custom validators as needed for your specific requirements.
}
