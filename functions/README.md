# Cloud Functions - Facturación Electrónica SRI Ecuador

## 📋 Descripción

Este módulo contiene las Cloud Functions de Firebase para generar facturas electrónicas según el estándar del SRI (Servicio de Rentas Internas) de Ecuador.

## 🔧 Configuración

### 1. Variables de Entorno (.env)

Copia el archivo `.env.example` a `.env` y completa con tus datos:

```bash
cp .env.example .env
```

Edita `.env` con tus datos reales:

```env
RUC_EMPRESA=1003066535001
RAZON_SOCIAL=TU NOMBRE O RAZON SOCIAL
NOMBRE_COMERCIAL=TIENDA ROPA ECUADOR
DIRECCION_MATRIZ=Tu dirección completa
OBLIGADO_CONTABILIDAD=NO
CONTRIBUYENTE_ESPECIAL=000
```

### 2. Secret Manager (Contraseña del Certificado)

La contraseña del certificado .p12 se almacena de forma segura en Secret Manager:

```bash
firebase functions:secrets:set CERTIFICADO_PASSWORD
```

Cuando te pida el valor, ingresa: `PALACIOS6535*`

Para verificar:

```bash
firebase functions:secrets:access CERTIFICADO_PASSWORD
```

## 📦 Instalación

```bash
npm install
```

## 🚀 Despliegue

```bash
firebase deploy --only functions
```

## 🔐 Seguridad

- ✅ **`.env`** está en `.gitignore` - NUNCA se sube a Git
- ✅ **Contraseña** se guarda en Secret Manager (encriptada)
- ✅ **Certificado .p12** está en Firebase Storage privado

## 📚 Funciones Disponibles

### `generarFactura(orderId)`

Genera una factura electrónica del SRI basada en un pedido.

**Parámetros:**
- `orderId` (string): ID del pedido en Firestore

**Retorna:**
```javascript
{
  success: true,
  claveAcceso: "4901202501...",
  mensaje: "Factura generada y autorizada exitosamente"
}
```

### `consultarAutorizacion(claveAcceso)`

Consulta el estado de autorización de una factura en el SRI.

**Parámetros:**
- `claveAcceso` (string): Clave de acceso de 49 dígitos

## 🧪 Ambiente de Pruebas

Por defecto, las funciones están configuradas para el ambiente de **PRUEBAS** del SRI:

- URL Recepción: `https://celospruebas.sri.gob.ec/...`
- URL Autorización: `https://celospruebas.sri.gob.ec/...`
- Ambiente: `1` (Pruebas)

## 📖 Documentación SRI

- [Guía de Facturación Electrónica](http://www.sri.gob.ec/web/guest/facturacion-electronica)
- [Especificación Técnica v2.23](https://www.sri.gob.ec/o/sri-portlet-biblioteca-alfresco-internet/descargar/c1cb42c4-4b0e-4c3c-a7e6-afca79e69ac0/Ficha%20T%c3%a9cnica%20Comprobantes%20Electr%c3%b3nicos%20Esquema%20Offline%20Versi%c3%b3n%202.23.pdf)

## 📝 Notas

- El código usa **Firebase Functions v2** (la versión moderna)
- Las variables usan el sistema `params` (NO `functions.config()` que está deprecado)
- Los secrets se gestionan con Secret Manager

