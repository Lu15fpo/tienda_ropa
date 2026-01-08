utra en f/**
 * Script de Prueba para Cloud Functions de Facturación SRI
 * Ejecutar: node test_cloud_functions.js
 */

const admin = require('firebase-admin');

// Inicializar Firebase Admin SDK
const serviceAccount = require('./functions/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'ecommerceapp-5f46c'
});

const db = admin.firestore();

/**
 * PASO 1: Crear un pedido de prueba en Firestore
 */
async function crearPedidoPrueba() {
  console.log('📦 Creando pedido de prueba...');

  const pedidoTest = {
    userId: '9999999999999',
    deliveryName: 'CONSUMIDOR FINAL TEST',
    deliveryEmail: 'test@example.com',
    deliveryPhone: '0999999999',
    deliveryAddress: 'Dirección de prueba',
    deliveryCity: 'Quito',
    totalAmount: 112.00, // $100 + 12% IVA
    items: [
      {
        productId: 'PROD-TEST-001',
        title: 'Producto de Prueba SRI',
        quantity: 1,
        price: 100.00,
        image: 'https://via.placeholder.com/150'
      }
    ],
    status: 'OrderStatus.procesando',
    orderDate: admin.firestore.FieldValue.serverTimestamp(),
    paymentMethod: 'Efectivo',
    facturaGenerada: false
  };

  const docRef = await db.collection('Orders').add(pedidoTest);
  console.log('✅ Pedido de prueba creado con ID:', docRef.id);

  return docRef.id;
}

/**
 * PASO 2: Crear documento de secuenciales (si no existe)
 */
async function inicializarSecuenciales() {
  console.log('🔢 Inicializando secuenciales...');

  const secuencialesRef = db.collection('Configuracion').doc('secuenciales');
  const doc = await secuencialesRef.get();

  if (!doc.exists) {
    await secuencialesRef.set({
      factura: 0,
      establecimiento: '001',
      puntoEmision: '001',
      ultimaActualizacion: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Documento de secuenciales creado');
  } else {
    console.log('✅ Documento de secuenciales ya existe');
  }
}

/**
 * PASO 3: Simular llamada a generarFactura
 */
async function simularGenerarFactura(orderId) {
  console.log('\n📄 IMPORTANTE: SIMULACIÓN DE LLAMADA');
  console.log('════════════════════════════════════════════════════════════');
  console.log('Para probar la función generarFactura, tienes 3 opciones:\n');

  console.log('OPCIÓN A: Desde Firebase Console (Recomendado)');
  console.log('1. Ve a: https://console.firebase.google.com/project/ecommerceapp-5f46c/functions');
  console.log('2. Busca la función "generarFactura"');
  console.log('3. Haz clic en los 3 puntos → "Test function"');
  console.log('4. En el campo de prueba, pega este JSON:');
  console.log(JSON.stringify({ orderId: orderId }, null, 2));
  console.log('5. Haz clic en "Test the function"\n');

  console.log('OPCIÓN B: Desde tu App Flutter');
  console.log('1. Integrar el servicio de facturación');
  console.log('2. Llamar la función al confirmar pedido\n');

  console.log('OPCIÓN C: Usando Firebase CLI (Terminal)');
  console.log(`firebase functions:shell`);
  console.log(`generarFactura({orderId: "${orderId}"})\n`);

  console.log('════════════════════════════════════════════════════════════');
}

/**
 * PASO 4: Verificar facturas generadas
 */
async function verificarFacturas() {
  console.log('\n📊 Verificando facturas en Firestore...');

  const facturasSnapshot = await db.collection('Facturas').limit(5).get();

  if (facturasSnapshot.empty) {
    console.log('⚠️  No hay facturas generadas aún');
    return;
  }

  console.log(`✅ Se encontraron ${facturasSnapshot.size} factura(s):\n`);

  facturasSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`  • Clave de Acceso: ${data.claveAcceso}`);
    console.log(`    Pedido: ${data.orderId}`);
    console.log(`    Estado: ${data.estado}`);
    console.log(`    Fecha: ${data.fechaEmision?.toDate?.()}`);
    console.log('');
  });
}

/**
 * FUNCIÓN PRINCIPAL
 */
async function ejecutarPruebas() {
  try {
    console.log('\n🚀 INICIANDO PRUEBAS DE CLOUD FUNCTIONS - SRI');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Paso 1: Inicializar secuenciales
    await inicializarSecuenciales();

    // Paso 2: Crear pedido de prueba
    const orderId = await crearPedidoPrueba();

    // Paso 3: Instrucciones para probar la función
    await simularGenerarFactura(orderId);

    // Paso 4: Verificar facturas existentes
    await verificarFacturas();

    console.log('\n✅ PREPARACIÓN COMPLETADA');
    console.log('═══════════════════════════════════════════════════════════');
    console.log(`\n📝 ID del pedido de prueba: ${orderId}`);
    console.log('\n💡 Ahora puedes probar la función generarFactura usando');
    console.log('   cualquiera de las opciones mostradas arriba.\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error durante las pruebas:', error);
    process.exit(1);
  }
}

// Ejecutar
ejecutarPruebas();

