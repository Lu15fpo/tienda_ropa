// Script para subir el logo a Firebase Storage
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Inicializar Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'ecommerceapp-5f46c.firebasestorage.app'
});

const bucket = admin.storage().bucket();

async function subirLogo() {
  try {
    console.log('📤 Subiendo logo a Firebase Storage...');

    // Ruta del logo en tu proyecto
    const logoPath = path.join(__dirname, '..', 'assets', 'logos', 'LogoRedondoLightLogin.png');

    // Verificar que el archivo existe
    if (!fs.existsSync(logoPath)) {
      throw new Error(`No se encontró el logo en: ${logoPath}`);
    }

    // Subir a Firebase Storage
    const destination = 'logos/LogoRedondoLightLogin.png';
    await bucket.upload(logoPath, {
      destination: destination,
      metadata: {
        contentType: 'image/png',
        metadata: {
          firebaseStorageDownloadTokens: 'logo-factura-token'
        }
      }
    });

    // Hacer el archivo público
    const file = bucket.file(destination);
    await file.makePublic();

    // Obtener URL pública
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${destination}`;

    console.log('✅ Logo subido exitosamente!');
    console.log(`📍 URL pública: ${publicUrl}`);
    console.log(`📁 Ubicación: ${destination}`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Error al subir logo:', error);
    process.exit(1);
  }
}

subirLogo();

