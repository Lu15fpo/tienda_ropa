# 📱 INSTRUCCIONES PARA INSTALAR EN iPhone 12 mini

## ✅ PREPARACIÓN REALIZADA (Ya está lista)

- ✅ Bundle ID configurado: `com.example.tiendaRopa` (registrado en Firebase)
- ✅ Nombre de la app: "Men's Locker Clothing Ec."
- ✅ Ícono de la app configurado
- ✅ Permisos de iOS agregados (cámara, fotos, ubicación)
- ✅ Configuración de Firebase para iOS (GoogleService-Info.plist incluido)
- ✅ Google Sign-In completamente funcional
- ✅ Proyecto listo para compilar

---

## 🎯 PASOS A SEGUIR EN LA MAC (Día de instalación)

### PASO 1: Preparar el iPhone 12 mini (5 minutos)

1. **Conecta el iPhone a la Mac** con el cable USB
2. **En el iPhone**, ve a:
   - `Ajustes` → `Privacidad y Seguridad` → `Modo Desarrollador`
   - Activa **"Modo Desarrollador"**
   - El iPhone se reiniciará (es normal)
3. **Confía en la computadora**:
   - Después del reinicio, aparecerá un mensaje en el iPhone
   - Pulsa **"Confiar"** y escribe tu código de iPhone

---

### PASO 2: Abrir el proyecto en Xcode (2 minutos)

1. Abre **Terminal** en la Mac
2. Navega a la carpeta del proyecto:
   ```bash
   cd /ruta/al/proyecto/tienda_ropa
   ```
3. Abre el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ **IMPORTANTE**: Abre el archivo `.xcworkspace`, NO el `.xcodeproj`

---

### PASO 3: Configurar cuenta de Apple (3 minutos)

1. En Xcode, ve al menú superior:
   - `Xcode` → `Settings...` (o `Preferences`)
   - Clic en la pestaña **"Accounts"**

2. **Agregar tu Apple ID personal**:
   - Clic en el botón **"+"** (abajo a la izquierda)
   - Selecciona **"Apple ID"**
   - Ingresa tu **correo de Apple ID personal** (NO el de la empresa)
   - Ingresa tu **contraseña**
   - Clic en **"Sign In"**

3. **Verificar el equipo**:
   - Verás tu nombre con "(Personal Team)" al lado
   - Esto es correcto para desarrollo personal

---

### PASO 4: Configurar Firma de Código (2 minutos)

1. En Xcode, en el panel izquierdo:
   - Clic en **"Runner"** (el archivo azul de arriba)
   
2. En la pestaña **"Signing & Capabilities"**:
   - ✅ Marca **"Automatically manage signing"**
   - En **"Team"**: Selecciona tu nombre **(Personal Team)**
   - **Bundle Identifier** debe mostrar: `com.example.tiendaRopa`
   
3. Si aparece error de Bundle ID:
   - Xcode te sugerirá cambiarlo automáticamente
   - Acepta el cambio (agregará tu ID de equipo)

---

### PASO 5: Seleccionar dispositivo y compilar (3 minutos)

1. En la barra superior de Xcode:
   - Al lado del botón **"Play" (▶️)**
   - Clic en el menú desplegable que dice "Runner > ..."
   - Selecciona tu **iPhone 12 mini** (debe aparecer conectado)

2. **Compilar e instalar**:
   - Presiona el botón **▶️ (Play)** o `Cmd + R`
   - Espera a que compile (puede tardar 2-5 minutos la primera vez)

3. **Si aparece error de "Developer Mode"**:
   - En el iPhone, ve a: `Ajustes` → `Privacidad y Seguridad` → `Modo Desarrollador`
   - Activa el modo desarrollador
   - Reinicia el iPhone
   - Vuelve a presionar **▶️** en Xcode

---

### PASO 6: Confiar en el desarrollador en el iPhone (1 minuto)

⚠️ **IMPORTANTE**: La primera vez que instales la app, verás este error en el iPhone:

**"No se puede verificar el desarrollador"**

**Solución**:
1. En el iPhone, ve a:
   - `Ajustes` → `General` → `Gestión de VPN y dispositivos`
   
2. En la sección **"APP DE DESARROLLADOR"**:
   - Verás tu Apple ID (correo)
   - Pulsa sobre él
   
3. Pulsa el botón azul:
   - **"Confiar en [tu correo]"**
   - Confirma pulsando **"Confiar"** de nuevo

4. **¡Listo!** Ahora puedes abrir la app desde el iPhone

---

### PASO 7: Desconectar y probar (1 minuto)

1. **Desconecta el iPhone de la Mac**
2. Abre la app **"Men's Locker Clothing Ec."** desde el iPhone
3. La app debe funcionar completamente sin estar conectada

---

## ⏰ DURACIÓN DE LA INSTALACIÓN

- ✅ Con cuenta **gratuita (Personal Team)**: **7 días**
- ✅ Perfecto para tu defensa del viernes
- 📅 La app dejará de funcionar en 7 días (después de tu defensa)

---

## ⚠️ POSIBLES PROBLEMAS Y SOLUCIONES

### Problema 1: "No se puede verificar la identidad del desarrollador"
**Solución**: Ve a `Ajustes` → `General` → `Gestión de VPN y dispositivos` → Confía en tu Apple ID

### Problema 2: "Failed to register bundle identifier"
**Solución**: 
- En Xcode, cambia el Bundle ID agregando un sufijo único
- Por ejemplo: `com.example.tiendaRopa.tuNombre`

### Problema 3: "Código de firma no válido"
**Solución**: 
- Ve a `Signing & Capabilities` en Xcode
- Desmarca y vuelve a marcar "Automatically manage signing"

### Problema 4: "No devices found"
**Solución**:
- Desconecta y reconecta el iPhone
- Asegúrate de que el iPhone confíe en la Mac
- En Xcode: `Window` → `Devices and Simulators` → verifica que aparezca

### Problema 5: Error de Firebase en iOS
**Solución**:
- Verifica que el archivo `GoogleService-Info.plist` esté en `ios/Runner/`
- Si no está, cópialo desde Firebase Console

---

## 📝 NOTAS IMPORTANTES

1. **No uses la cuenta de la empresa** - Usa tu Apple ID personal
2. **La app funcionará por 7 días** - Suficiente para tu defensa
3. **No necesitas certificados de pago** - La cuenta gratuita es suficiente
4. **Desconéctate después de instalar** - La app funcionará sin cable
5. **Si necesitas reinstalar** - Solo repite el Paso 5

---

## 📞 CONTACTOS DE EMERGENCIA (Por si algo falla)

- **Documentación oficial de Flutter iOS**: https://docs.flutter.dev/deployment/ios
- **Soporte de Xcode**: Menú `Help` → `Xcode Help`

---

## ✅ CHECKLIST RÁPIDO

Antes de ir a la empresa, asegúrate de tener:

- [ ] iPhone 12 mini cargado (mínimo 50%)
- [ ] Cable USB para conectar iPhone a Mac
- [ ] Tu Apple ID personal (correo y contraseña)
- [ ] Código de desbloqueo del iPhone
- [ ] Este documento impreso o en otro dispositivo

---

## 🎓 ¡MUCHA SUERTE EN TU DEFENSA DE TESIS! 🎓

El proyecto está completamente configurado y listo para instalar en tu iPhone.
Solo sigue estos pasos y en menos de 15 minutos tendrás la app funcionando.

**¡Éxitos!** 🚀

