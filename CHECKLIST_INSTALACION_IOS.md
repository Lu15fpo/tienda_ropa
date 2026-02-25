# ✅ CHECKLIST RÁPIDO - DÍA DE INSTALACIÓN iOS

## 📋 ANTES DE IR A LA EMPRESA

### Documentos y archivos:
- [ ] Imprimir o guardar `INSTRUCCIONES_INSTALACION_IOS.md`
- [ ] Imprimir o guardar `FIREBASE_IOS_CONFIG.md`
- [ ] Proyecto `tienda_ropa` en USB o sincronizado en la nube
- [ ] Descargar `GoogleService-Info.plist` desde Firebase Console

### Hardware:
- [ ] iPhone 12 mini cargado (mínimo 50% batería)
- [ ] Cable USB compatible (Lightning a USB-C o USB-A)
- [ ] Asegurarse de que el cable funciona para datos (no solo carga)

### Credenciales:
- [ ] Apple ID personal (correo y contraseña anotados)
- [ ] Código de desbloqueo del iPhone
- [ ] Acceso a Firebase Console (correo y contraseña)

---

## 🖥️ AL LLEGAR A LA MAC

### FASE 1: Preparación (5 min)
- [ ] Conectar iPhone 12 mini a la Mac
- [ ] Activar "Modo Desarrollador" en iPhone
- [ ] Confiar en la Mac desde el iPhone
- [ ] Copiar proyecto a la Mac (si está en USB)

### FASE 2: Firebase iOS (5 min)
- [ ] Abrir Firebase Console
- [ ] Descargar `GoogleService-Info.plist`
- [ ] Guardar archivo en escritorio temporalmente

### FASE 3: Xcode Setup (5 min)
- [ ] Abrir Terminal
- [ ] `cd /ruta/al/proyecto/tienda_ropa`
- [ ] `open ios/Runner.xcworkspace`
- [ ] Agregar Apple ID en Xcode → Settings → Accounts

### FASE 4: Configuración del Proyecto (3 min)
- [ ] En Xcode: Seleccionar "Runner" en panel izquierdo
- [ ] Tab "Signing & Capabilities"
- [ ] Marcar "Automatically manage signing"
- [ ] Seleccionar Team (Personal Team)
- [ ] Arrastrar `GoogleService-Info.plist` a carpeta Runner

### FASE 5: Compilación (5 min)
- [ ] Seleccionar iPhone 12 mini en menú superior
- [ ] Presionar ▶️ (Play) o Cmd + R
- [ ] Esperar compilación (2-5 minutos)

### FASE 6: Confiar en Desarrollador (2 min)
- [ ] En iPhone: Ajustes → General → Gestión de VPN y dispositivos
- [ ] Pulsar en tu Apple ID
- [ ] Pulsar "Confiar"
- [ ] Confirmar "Confiar"

### FASE 7: Prueba Final (2 min)
- [ ] Desconectar iPhone de la Mac
- [ ] Abrir app "Men's Locker Clothing Ec."
- [ ] Probar funcionalidades básicas:
  - [ ] Iniciar sesión
  - [ ] Ver productos
  - [ ] Agregar al carrito
  - [ ] Ver perfil

---

## ⏱️ TIEMPO TOTAL ESTIMADO: 25-30 minutos

---

## 🚨 PROBLEMAS COMUNES Y SOLUCIONES RÁPIDAS

### ❌ "No se puede verificar el desarrollador"
➡️ Ajustes → General → Gestión de VPN → Confiar en [tu correo]

### ❌ "No devices found" en Xcode
➡️ Desconecta y reconecta el iPhone, confía en la Mac

### ❌ "Bundle identifier already exists"
➡️ En Xcode, cambia Bundle ID a: `ec.menslockerclothing.app.tuNombre`

### ❌ Error de Firebase
➡️ Verifica que `GoogleService-Info.plist` esté en ios/Runner/

### ❌ Modo Desarrollador no aparece
➡️ Solo disponible en iOS 16+, verifica versión del iPhone

---

## 📱 INFORMACIÓN DEL DISPOSITIVO

- **Modelo**: iPhone 12 mini
- **iOS mínimo requerido**: iOS 12.0
- **iOS recomendado**: iOS 16+ (para Modo Desarrollador fácil)

---

## 🎯 OBJETIVO FINAL

✅ App instalada en iPhone 12 mini
✅ App funciona sin estar conectada a Mac
✅ Duración: 7 días (hasta después de defensa del viernes)

---

## 📝 NOTAS IMPORTANTES

1. **No cerrar Xcode** hasta verificar que la app funciona en el iPhone
2. **Hacer prueba completa** antes de desconectar
3. **Si algo falla**, consultar `INSTRUCCIONES_INSTALACION_IOS.md`
4. **Tomar screenshots** de la app funcionando (para la defensa)

---

## 🎓 PARA LA DEFENSA

### Capturas recomendadas:
- [ ] Pantalla de inicio (Home)
- [ ] Pantalla de productos
- [ ] Pantalla de carrito
- [ ] Pantalla de perfil
- [ ] Pantalla de mis compras
- [ ] Factura PDF en el dispositivo

### Demostración sugerida:
1. Mostrar app en Android
2. Mostrar la MISMA app en iPhone
3. Demostrar cross-platform
4. Mostrar factura PDF funcionando

---

## ✅ VERIFICACIÓN FINAL ANTES DE SALIR

Antes de salir de la empresa, verifica:

- [ ] App abre correctamente en iPhone
- [ ] Puedo iniciar sesión
- [ ] Firebase funciona (datos se cargan)
- [ ] Puedo navegar entre pantallas
- [ ] Puedo ver productos
- [ ] El ícono se ve correctamente
- [ ] El nombre es "Men's Locker Clothing Ec."
- [ ] iPhone desconectado y app sigue funcionando

---

## 🚀 ¡LISTO PARA LA DEFENSA!

Si completaste todos los checks, tu app está lista para la defensa de tesis.

**Fecha de defensa**: Viernes
**Validez de la app**: 7 días desde instalación
**Estado del proyecto**: ✅ LISTO

---

**¡MUCHA SUERTE! 🎓📱**

