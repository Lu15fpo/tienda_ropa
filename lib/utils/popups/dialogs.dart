import 'package:flutter/material.dart';

class TDialogs {
  static void defaultDialog({
    required BuildContext context,
    String title = 'Confirmacion de Eliminacion',
    String content = 'Eliminar estos datos eliminara todos los datos relacionados. Esta seguro de eliminarlos?',
    String cancelText = 'Cancelar',
    String confirmText = 'Eliminar',
    Function()? onCancel,
    Function()? onConfirm,
  }) {
    // Show a confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: onConfirm,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}