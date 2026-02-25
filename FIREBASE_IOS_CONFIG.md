# 🔥 CONFIGURACIÓN FIREBASE PARA iOS

## ⚠️ IMPORTANTE: ARCHIVO FALTANTE

El archivo `GoogleService-Info.plist` **NO está** en el proyecto iOS.
Este archivo es necesario para que Firebase funcione en iOS.

---

## 📥 CÓMO OBTENER EL ARCHIVO (Desde Firebase Console)

### OPCIÓN A: Descargar desde Firebase Console (Recomendado)

1. **Accede a Firebase Console**:
   - Ve a: https://console.firebase.google.com
   - Inicia sesión con la cuenta de Firebase del proyecto

2. **Selecciona tu proyecto**:
   - Busca: **"eCommerceApp"** o tu proyecto

3. **Ve a Configuración del proyecto**:
   - Clic en el ⚙️ (engranaje) al lado de "Descripción general del proyecto"
   - Selecciona **"Configuración del proyecto"**

4. **Registra la app iOS** (si no está registrada):
   - Ve a la pestaña **"General"**
   - En la sección "Tus apps", busca el ícono de iOS
   - Si no está, clic en **"Agregar app"** → Selecciona **iOS**

5. **Configuración del Bundle ID**:
   - Bundle ID de iOS: `ec.menslockerclothing.app`
   - Nombre de la app (opcional): Men's Locker Clothing Ec.
   - App Store ID (opcional): Déjalo vacío
   - Clic en **"Registrar app"**

6. **Descargar GoogleService-Info.plist**:
   - Firebase te mostrará el archivo para descargar
   - Clic en **"Descargar GoogleService-Info.plist"**
   - Guarda el archivo

7. **Si ya está registrada la app iOS**:
   - En la sección "Tus apps"
   - Busca la app con ícono de iOS
   - Clic en el ícono de iOS
   - Scroll hasta abajo
   - Clic en **"Descargar GoogleService-Info.plist"**

---

## 📁 DÓNDE COLOCAR EL ARCHIVO

### EN LA MAC:

1. **Copia el archivo** `GoogleService-Info.plist` descargado

2. **Abre el proyecto en Xcode**:
   ```bash
   cd /ruta/al/proyecto/tienda_ropa
   open ios/Runner.xcworkspace
   ```

3. **Arrastra el archivo a Xcode**:
   - En el panel izquierdo de Xcode
   - Busca la carpeta **"Runner"** (con ícono amarillo)
   - **Arrastra** el archivo `GoogleService-Info.plist` a esta carpeta
   
4. **Configuración al arrastrar**:
   - ✅ Marca **"Copy items if needed"**
   - ✅ Marca **"Create groups"**
   - En "Add to targets", marca **"Runner"**
   - Clic en **"Finish"**

5. **Verificar**:
   - El archivo debe aparecer en la carpeta "Runner" en Xcode
   - Debe estar al mismo nivel que `Info.plist`

---

## 🖥️ ALTERNATIVA: Colocar manualmente (Si no tienes Xcode abierto)

1. Copia el archivo `GoogleService-Info.plist`

2. Pégalo en esta ruta:
   ```
   tienda_ropa/ios/Runner/GoogleService-Info.plist
   ```

3. Luego abre Xcode y verifica que aparezca en el proyecto

---

## ⚠️ SI NO PUEDES ACCEDER A FIREBASE CONSOLE

### OPCIÓN B: Pedir el archivo al administrador del proyecto

Si no tienes acceso a Firebase Console:

1. Pide al administrador del proyecto que te envíe el archivo
2. El archivo debe ser para el Bundle ID: `ec.menslockerclothing.app`
3. Coloca el archivo siguiendo las instrucciones de arriba

---

## ✅ VERIFICAR QUE FIREBASE FUNCIONA EN iOS

Después de colocar el archivo y compilar:

1. Abre la app en el iPhone
2. Intenta iniciar sesión
3. Si funciona, Firebase está configurado correctamente

Si aparecen errores:
- Verifica que el Bundle ID en Firebase Console sea: `ec.menslockerclothing.app`
- Verifica que el archivo esté en la carpeta correcta
- Limpia el proyecto: En Xcode: `Product` → `Clean Build Folder` (`Cmd + Shift + K`)
- Recompila: `Product` → `Run` (`Cmd + R`)

---

## 📝 NOTAS IMPORTANTES

1. **El archivo es único por proyecto** - No copies de otro proyecto
2. **No subas este archivo a GitHub** - Contiene claves sensibles
3. **Un archivo por plataforma** - iOS usa `.plist`, Android usa `.json`
4. **Si cambias el Bundle ID** - Debes actualizar en Firebase Console también

---

## 🔗 ENLACES ÚTILES

- Firebase Console: https://console.firebase.google.com
- Documentación oficial: https://firebase.google.com/docs/ios/setup
- Tutorial de configuración: https://firebase.google.com/docs/flutter/setup

---

## 📞 CONTACTO

Si tienes problemas para obtener el archivo, contacta al administrador del proyecto Firebase.

