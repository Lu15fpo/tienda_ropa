#!/usr/bin/env node

/**
 * Script SIMPLIFICADO - Probar Cloud Function sin serviceAccountKey
 * Usa Firebase CLI directamente
 */

const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

async function probarFuncion() {
  console.log('\n🚀 PRUEBA SIMPLIFICADA DE CLOUD FUNCTIONS');
  console.log('═══════════════════════════════════════════════════════════\n');

  try {
    // Paso 1: Crear datos del pedido de prueba
    console.log('📦 Paso 1: Creando pedido de prueba en Firestore...\n');

    const pedidoJSON = JSON.stringify({
      userId: '9999999999999',
      deliveryName: 'CONSUMIDOR FINAL TEST',
      deliveryEmail: 'test@example.com',
      deliveryPhone: '0999999999',
      deliveryAddress: 'Av. Principal 123',
      deliveryCity: 'Quito',
      deliveryState: 'Pichincha',
      deliveryCountry: 'Ecuador',
      deliveryPostalCode: '170102',
      totalAmount: 112,
      subtotal: 100,
      tax: 12,
      shippingCost: 0,
      discount: 0,
      items: [{
        productId: 'TEST-001',
        title: 'Producto de Prueba SRI',
        brand: 'Nike',
        quantity: 1,
        price: 100,
        image: 'https://via.placeholder.com/150',
        variationId: ''
      }],
      status: 'OrderStatus.procesando',
      paymentMethod: 'Efectivo',
      facturaGenerada: false,
      facturaId: ''
    });

    console.log('📝 Datos del pedido:');
    console.log(JSON.parse(pedidoJSON));
    console.log('\n');

    // Instrucciones para crear manualmente en Firebase Console
    console.log('═══════════════════════════════════════════════════════════');
    console.log('⚠️  ACCIÓN REQUERIDA:');
    console.log('═══════════════════════════════════════════════════════════\n');
    console.log('1. Abre Firebase Console → Firestore:');
    console.log('   https://console.firebase.google.com/project/ecommerceapp-5f46c/firestore\n');
    console.log('2. Crea la colección "Configuracion" (si no existe)');
    console.log('   y dentro crea el documento "secuenciales" con:');
    console.log('   - factura: 0 (tipo: number)');
    console.log('   - establecimiento: "001" (tipo: string)');
    console.log('   - puntoEmision: "001" (tipo: string)\n');
    console.log('3. Crea un pedido en la colección "Orders":');
    console.log('   - Haz clic en "Agregar documento"');
    console.log('   - Usa ID automático');
    console.log('   - Copia los campos del JSON de arriba');
    console.log('   - Agrega el campo "orderDate" de tipo timestamp\n');
    console.log('4. COPIA EL ID DEL PEDIDO generado\n');
    console.log('5. Vuelve aquí y pega el ID cuando se te solicite\n');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Esperar input del usuario
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const orderId = await new Promise(resolve => {
      readline.question('📝 Pega el ID del pedido que creaste: ', answer => {
        readline.close();
        resolve(answer.trim());
      });
    });

    if (!orderId) {
      console.log('\n❌ No se proporcionó un ID. Abortando...');
      process.exit(1);
    }

    console.log(`\n✅ ID del pedido: ${orderId}`);
    console.log('\n🔥 Llamando a la Cloud Function generarFactura...\n');

    // Llamar a la función usando Firebase CLI
    const cmd = `firebase functions:call generarFactura --data "{\\"orderId\\":\\"${orderId}\\"}"`;

    console.log('Ejecutando:', cmd);
    console.log('\n⏳ Esto puede tardar 30-60 segundos...\n');

    const { stdout, stderr } = await execAsync(cmd);

    if (stderr && !stderr.includes('deprecation')) {
      console.error('⚠️  Advertencias:', stderr);
    }

    console.log('═══════════════════════════════════════════════════════════');
    console.log('📊 RESPUESTA DE LA FUNCIÓN:');
    console.log('═══════════════════════════════════════════════════════════');
    console.log(stdout);
    console.log('═══════════════════════════════════════════════════════════\n');

    console.log('✅ Ahora verifica en Firestore:');
    console.log('   - Colección "Facturas" debe tener un nuevo documento');
    console.log('   - El pedido debe tener facturaGenerada: true\n');
    console.log('🔗 Ver en Firestore:');
    console.log('   https://console.firebase.google.com/project/ecommerceapp-5f46c/firestore\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.log('\n💡 SOLUCIÓN ALTERNATIVA:');
    console.log('═══════════════════════════════════════════════════════════');
    console.log('Si el comando anterior falló, usa esta opción:\n');
    console.log('1. Ve a Firebase Console → Functions');
    console.log('2. Haz clic en "generarFactura"');
    console.log('3. Ve a la pestaña "Logs"');
    console.log('4. Haz clic en "Trigger function" (si aparece)');
    console.log('\nO simplemente espera a integrar con Flutter (Fase 3)\n');
    process.exit(1);
  }
}

probarFuncion();

