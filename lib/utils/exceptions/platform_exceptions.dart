/// Exception class for handling various platform-related errors.
class TPlatformException implements Exception {
  final String code;

  TPlatformException(this.code);

  String get message {
    switch (code) {
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Inicio de sesión fallido. Por favor verifique su informacion.';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor intente de nuevo más tarde.';
      case 'invalid-argument':
        return 'Argument invalido para el método de autenticación.';
      case 'invalid-password':
        return 'Contraseña incorrecta. Por favor intente de nuevo.';
      case 'invalid-phone-number':
        return 'El número de teléfono es inválido.';
      case 'operation-not-allowed':
        return 'El proveedor de inicio de sesión está desactivado para tu proyecto de Firebase.';
      case 'session-cookie-expired':
        return 'La sesión de Firebase ha expirado. Por favor vuelve a intentarlo.';
      case 'uid-already-exists':
        return 'El ID de usuario ya está en uso por otro usuario.';
      case 'sign_in_failed':
        return 'Inicio de sesión fallido. Por favor intente de nuevo.';
      case 'network-request-failed':
        return 'Solicitud de conexión fallida. Por favor verifique su conexión a internet.';
      case 'internal-error':
        return 'Error interno. Por favor intente de nuevo más tarde.';
      case 'invalid-verification-code':
        return 'Codigo de verificacion incorrecto. Por favor ingrese un codigo valido.';
      case 'invalid-verification-id':
        return 'Verificacion de ID invalida. Por favor solicite un nuevo codigo de verificacion.';
      case 'quota-exceeded':
        return 'Cuota excedida. Intente de nuevo más tarde.';
    // Add more cases as needed...
      default:
        return 'Un error inesperado ha ocurrido en la plataforma. Por favor intenta de nuevo.';
    }
  }
}
