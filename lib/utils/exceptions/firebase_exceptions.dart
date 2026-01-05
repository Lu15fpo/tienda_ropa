/// Custom exception class to handle various Firebase-related errors.
class TFirebaseException implements Exception {
  /// The error code associated with the exception.
  final String code;

  /// Constructor that takes an error code.
  TFirebaseException(this.code);

  /// Get the corresponding error message based on the error code.
  String get message {
    switch (code) {
      case 'unknown':
        return 'Un error desconocido en Firebase ha ocurrido. Por favor intenta de nuevo.';
      case 'invalid-custom-token':
        return 'El formato del token personalizado es incorrecto. Por favor verifica el formato del token.';
      case 'custom-token-mismatch':
        return 'El token personalizado no coincide con el usuario actual.';
      case 'user-disabled':
        return 'La cuenta de usuario ha sido deshabilitada.';
      case 'user-not-found':
        return 'No se encontro el usuario con el email o UID proporcionados.';
      case 'invalid-email':
        return 'El email proporcionado es invalido. Por favor ingrese un email valido.';
      case 'email-already-in-use':
        return 'El direccion de email ya esta en uso. Por favor ingresa otra direccion de email.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Por favor intente de nuevo.';
      case 'weak-password':
        return 'La constraseña es muy débil. Por favor ingrese una contraseña mas segura.';
      case 'provider-already-linked':
        return 'La cuenta ya esta vinculada con otro proveedor.';
      case 'operation-not-allowed':
        return 'Esta operacion no esta permitida. Por favor contacte con soporte para mas informacion.';
      case 'invalid-credential':
        return 'Las credenciales proporcionadas son invalidas o han expirado.';
      case 'invalid-verification-code':
        return 'Codigo de verificacion incorrecto. Por favor ingrese un codigo valido.';
      case 'invalid-verification-id':
        return 'ID de verificacion invalida. Por favor solicite un nuevo codigo de verificacion.';
      case 'captcha-check-failed':
        return 'El reCAPTCHA check ha fallado. Por favor intenta de nuevo.';
      case 'app-not-authorized':
        return 'La aplicacion no esta autorizada para usar Firebase Authentication.';
      case 'keychain-error':
        return 'Ocurrio un error con el Keychain. Por favor verifica tu dispositivo.';
      case 'internal-error':
        return 'Un error interno en Firebase ha ocurrido. Por favor intenta de nuevo.';
      case 'invalid-app-credential':
        return 'Las credenciales de la aplicacion son invalidas. Por favor ingrese credenciales validas.';
      case 'user-mismatch':
        return 'Las credenciales proporcionadas no coinciden con el usuario actual.';
      case 'requires-recent-login':
        return 'La operacion es sensible y requiere autenticacion de inicio de sesion mas reciente. Por favor inicie sesion nuevamente.';
      case 'quota-exceeded':
        return 'Cuota excedida. Intente de nuevo mas tarde.';
      case 'account-exists-with-different-credential':
        return 'Una cuenta ya existe con el mismo email pero con credenciales diferentes.';
      case 'missing-iframe-start':
        return 'El email template es faltante el iframe start tag.';
      case 'missing-iframe-end':
        return 'El email template es faltante el iframe end tag.';
      case 'missing-iframe-src':
        return 'El email template es faltante el iframe src attribute.';
      case 'auth-domain-config-required':
        return 'El authDomain configuracion es requerida para la verificacion del enlace de accion.';
      case 'missing-app-credential':
        return 'Las credenciales de la aplicacion son faltantes. Por favor ingrese credenciales validas.';
      case 'session-cookie-expired':
        return 'La sesion de Firebase ha expirado. Por favor vuelve a intentarlo.';
      case 'uid-already-exists':
        return 'El ID de usuario ya existe en otro usuario.';
      case 'web-storage-unsupported':
        return 'El almacenamiento Web no es soportado o esta deshabilitado.';
      case 'app-deleted':
        return 'La aplicacion ha sido eliminada.';
      case 'user-token-mismatch':
        return 'El token de usuario no coincide con el usuario actual.';
      case 'invalid-message-payload':
        return 'La vaerificacion de email no contiene un payload valido.';
      case 'invalid-sender':
        return 'El email remitente es invalido. Por favor ingrese un email valido.';
      case 'invalid-recipient-email':
        return 'El destinatario de email es invalido. Por favor ingrese un email valido.';
      case 'missing-action-code':
        return 'El codigo de accion es faltante. Por favor solicite un nuevo codigo de accion.';
      case 'user-token-expired':
        return 'El usuario token ha expirado y es requerido para continuar. Por favor inicie sesion nuevamente.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Credenciales de acceso invalidas.';
      case 'expired-action-code':
        return 'El codigo de accion ha expirado. Por favor solicite un nuevo codigo de accion.';
      case 'invalid-action-code':
        return 'El codigo de accion es invalido. Por favor verifica el codigo y vuelve a intentarlo.';
      case 'credential-already-in-use':
        return 'Las credenciales ya estan en uso por otro usuario.';
      default:
        return 'Un error inesperado en Firebase ha ocurrido. Por favor intenta de nuevo.';
    }
  }
}
