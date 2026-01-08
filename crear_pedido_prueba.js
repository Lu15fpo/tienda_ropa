/**
 * Script SIMPLE de prueba - Crea pedido de prueba en Firestore
 * NO requiere serviceAccountKey
 *
 * Ejecutar desde Firebase CLI:
 * firebase firestore:execute create-test-order
 */

// Datos del pedido de prueba
const pedidoPrueba = {
  userId: '9999999999999',
  deliveryName: 'CONSUMIDOR FINAL TEST',
  deliveryEmail: 'test@example.com',
  deliveryPhone: '0999999999',
  deliveryAddress: 'Av. Principal 123 y Secundaria',
  deliveryCity: 'Quito',
  deliveryState: 'Pichincha',
  deliveryCountry: 'Ecuador',
  deliveryPostalCode: '170102',
  totalAmount: 112.00, // $100 + 12% IVA = $112
  subtotal: 100.00,
  tax: 12.00,
  shippingCost: 0,
  discount: 0,
  items: [
    {
      productId: 'TEST-PROD-001',
      title: 'Camiseta Nike SB - PRUEBA SRI',
      brand: 'Nike',
      quantity: 1,
      price: 100.00,
      image: 'https://via.placeholder.com/150',
      variationId: ''
    }
  ],
  status: 'OrderStatus.procesando',
  paymentMethod: 'Efectivo - Prueba',
  facturaGenerada: false,
  facturaId: ''
};

console.log('📦 PEDIDO DE PRUEBA PARA FACTURACIÓN SRI');
console.log('═══════════════════════════════════════════════════════════');
console.log('\n🔹 Para crear este pedido manualmente en Firestore:\n');
console.log('1. Ve a Firebase Console → Firestore');
console.log('   https://console.firebase.google.com/project/ecommerceapp-5f46c/firestore\n');
console.log('2. Ve a la colección "Orders"\n');
console.log('3. Haz clic en "+ Agregar documento"\n');
console.log('4. Genera un ID automático\n');
console.log('5. Agrega estos campos:\n');

// Mostrar cada campo
Object.entries(pedidoPrueba).forEach(([key, value]) => {
  if (key === 'items') {
    console.log(`   ${key}: (array)`);
    console.log('     [0]: (map)');
    Object.entries(value[0]).forEach(([itemKey, itemValue]) => {
      console.log(`       ${itemKey}: "${itemValue}"`);
    });
  } else if (typeof value === 'object') {
    console.log(`   ${key}: ${JSON.stringify(value)}`);
  } else if (typeof value === 'string') {
    console.log(`   ${key}: "${value}"`);
  } else {
    console.log(`   ${key}: ${value}`);
  }
});

console.log('\n6. Agrega el campo "orderDate" de tipo timestamp (usa el servidor)\n');
console.log('7. Guarda el documento\n');
console.log('8. Copia el ID generado\n');
console.log('9. Úsalo para probar la función generarFactura\n');

console.log('═══════════════════════════════════════════════════════════');
console.log('\n📋 JSON COMPLETO (para copiar y pegar si lo prefieres):\n');
console.log(JSON.stringify(pedidoPrueba, null, 2));
console.log('\n═══════════════════════════════════════════════════════════\n');

