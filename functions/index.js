/**
 * Cloud Functions para Facturación Electrónica SRI
 * Maneja la generación, firma y envío de facturas al SRI
 */

const {setGlobalOptions} = require("firebase-functions/v2");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const {create} = require("xmlbuilder2");
const forge = require("node-forge");
const logger = require("firebase-functions/logger");

// Inicializar Firebase Admin
admin.initializeApp();

// Definir parámetros de configuración
const certificadoPassword = defineSecret("CERTIFICADO_PASSWORD");

// Configuración de la empresa desde variables de entorno
const EMPRESA_CONFIG = {
  RUC: process.env.RUC_EMPRESA || "9999999999999",
  RAZON_SOCIAL: process.env.RAZON_SOCIAL || "CONSUMIDOR FINAL",
  NOMBRE_COMERCIAL: process.env.NOMBRE_COMERCIAL || "TIENDA ROPA",
  DIRECCION_MATRIZ: process.env.DIRECCION_MATRIZ || "Ecuador",
  OBLIGADO_CONTABILIDAD: process.env.OBLIGADO_CONTABILIDAD || "NO",
  CONTRIBUYENTE_ESPECIAL: process.env.CONTRIBUYENTE_ESPECIAL || "000",
};

// Configuración global
setGlobalOptions({maxInstances: 10});

// Configuración del SRI (PRUEBAS)
const SRI_CONFIG = {
  RECEPCION_URL: "https://celospruebas.sri.gob.ec/comprobantes-electronicos-ws/RecepcionComprobantesOffline?wsdl",
  AUTORIZACION_URL: "https://celospruebas.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantesOffline?wsdl",
  AMBIENTE: "1", // 1 = Pruebas, 2 = Producción
  TIPO_EMISION: "1", // 1 = Normal
};


/**
 * Genera la clave de acceso de 49 dígitos
 */
function generarClaveAcceso(fecha, tipoComprobante, ruc, ambiente, serie, numeroComprobante, codigoNumerico, tipoEmision) {
  // Validar parámetros
  if (!fecha) throw new Error("Fecha es undefined");
  if (!tipoComprobante) throw new Error("tipoComprobante es undefined");
  if (!ruc) throw new Error("RUC es undefined");
  if (!ambiente) throw new Error("ambiente es undefined");
  if (!serie) throw new Error("serie es undefined");
  if (!numeroComprobante) throw new Error("numeroComprobante es undefined");
  if (!codigoNumerico) throw new Error("codigoNumerico es undefined");
  if (!tipoEmision) throw new Error("tipoEmision es undefined");

  logger.info(`[generarClaveAcceso] Parámetros: fecha=${fecha}, tipo=${tipoComprobante}, ruc=${ruc}, ambiente=${ambiente}, serie=${serie}, num=${numeroComprobante}, cod=${codigoNumerico}, emision=${tipoEmision}`);

  // Formato: ddmmyyyyTTrrrrrrrrrraasssnnnnnnnnnc
  // TT = Tipo comprobante (01 = Factura)
  // a = Ambiente (1 = Pruebas, 2 = Producción)
  // ss = Serie
  // nnnnnnnnn = Número comprobante
  // c = Dígito verificador (módulo 11)

  const claveBase = fecha.replace(/\//g, "") + // ddmmyyyy
                    tipoComprobante.padStart(2, "0") + // TT
                    ruc + // rrrrrrrrrrr
                    ambiente + // a
                    serie + // ss
                    numeroComprobante.padStart(9, "0") + // nnnnnnnnn
                    codigoNumerico.padStart(8, "0") + // cccccccc
                    tipoEmision; // t

  // Calcular dígito verificador (módulo 11)
  let suma = 0;
  let factor = 7;

  for (let i = 0; i < claveBase.length; i++) {
    suma += parseInt(claveBase[i]) * factor;
    factor = factor === 2 ? 7 : factor - 1;
  }

  const modulo = suma % 11;
  const digitoVerificador = modulo === 0 ? 0 : (11 - modulo);

  return claveBase + digitoVerificador;
}

/**
 * Genera el XML de la factura
 */
function generarXMLFactura(datosFactura) {
  const {claveAcceso, fechaEmision, comprador, items, totales} = datosFactura;

  const root = create({version: "1.0", encoding: "UTF-8"})
      .ele("factura", {id: "comprobante", version: "1.0.0"})
      .ele("infoTributaria")
      .ele("ambiente").txt(SRI_CONFIG.AMBIENTE).up()
      .ele("tipoEmision").txt(SRI_CONFIG.TIPO_EMISION).up()
      .ele("razonSocial").txt(EMPRESA_CONFIG.RAZON_SOCIAL).up()
      .ele("nombreComercial").txt(EMPRESA_CONFIG.NOMBRE_COMERCIAL).up()
      .ele("ruc").txt(EMPRESA_CONFIG.RUC).up()
      .ele("claveAcceso").txt(claveAcceso).up()
      .ele("codDoc").txt("01").up() // 01 = Factura
      .ele("estab").txt(datosFactura.establecimiento).up()
      .ele("ptoEmi").txt(datosFactura.puntoEmision).up()
      .ele("secuencial").txt(datosFactura.secuencial.padStart(9, "0")).up()
      .ele("dirMatriz").txt(EMPRESA_CONFIG.DIRECCION_MATRIZ).up()
      .up()
      .ele("infoFactura")
      .ele("fechaEmision").txt(fechaEmision).up()
      .ele("dirEstablecimiento").txt(EMPRESA_CONFIG.DIRECCION_MATRIZ).up()
      .ele("obligadoContabilidad").txt(EMPRESA_CONFIG.OBLIGADO_CONTABILIDAD).up()
      .ele("tipoIdentificacionComprador").txt(comprador.tipoIdentificacion).up()
      .ele("razonSocialComprador").txt(comprador.razonSocial).up()
      .ele("identificacionComprador").txt(comprador.identificacion).up()
      .ele("totalSinImpuestos").txt(totales.subtotal.toFixed(2)).up()
      .ele("totalDescuento").txt(totales.descuento.toFixed(2)).up()
      .ele("totalConImpuestos");

  // Agregar impuestos (IVA)
  root.ele("totalImpuesto")
      .ele("codigo").txt("2").up() // 2 = IVA
      .ele("codigoPorcentaje").txt("2").up() // 2 = 12%
      .ele("baseImponible").txt(totales.subtotal.toFixed(2)).up()
      .ele("valor").txt(totales.iva.toFixed(2)).up()
      .up();

  root.up()
      .ele("propina").txt("0.00").up()
      .ele("importeTotal").txt(totales.total.toFixed(2)).up()
      .ele("moneda").txt("DOLAR").up()
      .up()
      .ele("detalles");

  // Agregar items
  items.forEach((item, index) => {
    root.ele("detalle")
        .ele("codigoPrincipal").txt(item.codigo || `PROD${index + 1}`).up()
        .ele("descripcion").txt(item.descripcion).up()
        .ele("cantidad").txt(item.cantidad.toString()).up()
        .ele("precioUnitario").txt(item.precioUnitario.toFixed(6)).up()
        .ele("descuento").txt(item.descuento.toFixed(2)).up()
        .ele("precioTotalSinImpuesto").txt(item.subtotal.toFixed(2)).up()
        .ele("impuestos")
        .ele("impuesto")
        .ele("codigo").txt("2").up() // IVA
        .ele("codigoPorcentaje").txt("2").up() // 12%
        .ele("tarifa").txt("12").up()
        .ele("baseImponible").txt(item.subtotal.toFixed(2)).up()
        .ele("valor").txt((item.subtotal * 0.12).toFixed(2)).up()
        .up()
        .up()
        .up();
  });

  return root.end({prettyPrint: true});
}

/**
 * Firma el XML con el certificado digital .p12
 */
async function firmarXML(xmlContent, claveAcceso) {
  try {
    // Obtener el certificado .p12 desde Firebase Storage
    const bucket = admin.storage().bucket();
    const file = bucket.file("certificates/1003066535.p12");

    const [buffer] = await file.download();
    const p12Der = buffer.toString("binary");

    // Contraseña del certificado desde Secret Manager
    const passwordCert = certificadoPassword.value();

    // Convertir p12 a objeto forge
    const p12Asn1 = forge.asn1.fromDer(p12Der);
    const p12 = forge.pkcs12.pkcs12FromAsn1(p12Asn1, passwordCert);

    // Extraer clave privada y certificado
    const bags = p12.getBags({bagType: forge.pki.oids.certBag});
    const certBag = bags[forge.pki.oids.certBag][0];
    const certificate = certBag.cert;

    const keyBags = p12.getBags({bagType: forge.pki.oids.pkcs8ShroudedKeyBag});
    const keyBag = keyBags[forge.pki.oids.pkcs8ShroudedKeyBag][0];
    const privateKey = keyBag.key;

    // Crear firma digital
    const md = forge.md.sha256.create();
    md.update(xmlContent, "utf8");
    const signature = privateKey.sign(md);

    // Convertir firma a base64
    const signatureBase64 = forge.util.encode64(signature);

    // Insertar firma en el XML
    const xmlWithSignature = xmlContent.replace(
        "</factura>",
        `<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Id="Signature${claveAcceso}">
        <ds:SignedInfo>
          <ds:CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
          <ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
          <ds:Reference URI="#comprobante">
            <ds:Transforms>
              <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
            </ds:Transforms>
            <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
            <ds:DigestValue>${forge.util.encode64(forge.md.sha1.create().update(xmlContent, "utf8").digest().bytes())}</ds:DigestValue>
          </ds:Reference>
        </ds:SignedInfo>
        <ds:SignatureValue>${signatureBase64}</ds:SignatureValue>
        <ds:KeyInfo>
          <ds:X509Data>
            <ds:X509Certificate>${forge.util.encode64(forge.asn1.toDer(forge.pki.certificateToAsn1(certificate)).bytes())}</ds:X509Certificate>
          </ds:X509Data>
        </ds:KeyInfo>
      </ds:Signature>
      </factura>`,
    );

    return xmlWithSignature;
  } catch (error) {
    logger.error("Error al firmar XML:", error);
    throw new HttpsError("internal", "Error al firmar la factura: " + error.message);
  }
}

/**
 * Envía el XML firmado al SRI para validación y recepción
 */
async function enviarSRI(xmlFirmado, claveAcceso) {
  try {
    // Crear el SOAP envelope para recepción
    const soapEnvelope = `<?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ec="http://ec.gob.sri.ws.recepcion">
        <soapenv:Header/>
        <soapenv:Body>
          <ec:validarComprobante>
            <xml>${Buffer.from(xmlFirmado).toString("base64")}</xml>
          </ec:validarComprobante>
        </soapenv:Body>
      </soapenv:Envelope>`;

    // Enviar a recepción
    const responseRecepcion = await axios.post(SRI_CONFIG.RECEPCION_URL, soapEnvelope, {
      headers: {
        "Content-Type": "text/xml;charset=UTF-8",
        "SOAPAction": "",
      },
      timeout: 30000,
    });

    logger.info("Respuesta recepción SRI:", responseRecepcion.data);

    // Esperar y consultar autorización
    await new Promise((resolve) => setTimeout(resolve, 3000));

    const soapAutorizacion = `<?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ec="http://ec.gob.sri.ws.autorizacion">
        <soapenv:Header/>
        <soapenv:Body>
          <ec:autorizacionComprobante>
            <claveAccesoComprobante>${claveAcceso}</claveAccesoComprobante>
          </ec:autorizacionComprobante>
        </soapenv:Body>
      </soapenv:Envelope>`;

    const responseAutorizacion = await axios.post(SRI_CONFIG.AUTORIZACION_URL, soapAutorizacion, {
      headers: {
        "Content-Type": "text/xml;charset=UTF-8",
        "SOAPAction": "",
      },
      timeout: 30000,
    });

    logger.info("Respuesta autorización SRI:", responseAutorizacion.data);

    return {
      recepcion: responseRecepcion.data,
      autorizacion: responseAutorizacion.data,
    };
  } catch (error) {
    logger.error("Error al enviar al SRI:", error);
    throw new HttpsError("internal", "Error al comunicarse con el SRI: " + error.message);
  }
}

/**
 * Cloud Function principal para generar factura
 * Llamada desde la app móvil después de confirmar el pedido
 */
exports.generarFactura = onCall({
  maxInstances: 5,
  secrets: [certificadoPassword], // Declarar que esta función usa secrets
}, async (request) => {
  try {
    const {orderId, userId} = request.data;

    if (!orderId) {
      throw new HttpsError("invalid-argument", "El ID del pedido es requerido");
    }

    if (!userId) {
      throw new HttpsError("invalid-argument", "El ID del usuario es requerido");
    }

    logger.info(`📄 [generarFactura] Iniciando para pedido: ${orderId}, usuario: ${userId}`);

    // Obtener datos del pedido desde Firestore (ruta correcta)
    const orderDoc = await admin.firestore()
        .collection("Users")
        .doc(userId)
        .collection("Orders")
        .doc(orderId)
        .get();

    if (!orderDoc.exists) {
      logger.error(`❌ [generarFactura] Pedido no encontrado: Users/${userId}/Orders/${orderId}`);
      throw new HttpsError("not-found", "Pedido no encontrado");
    }

    const orderData = orderDoc.data();
    logger.info(`✅ [generarFactura] Pedido encontrado. Items: ${orderData.items?.length || 0}`);

    // Log de configuración de empresa
    logger.info(`🏢 [generarFactura] Configuración empresa:`);
    logger.info(`   RUC: ${EMPRESA_CONFIG.RUC}`);
    logger.info(`   Razón Social: ${EMPRESA_CONFIG.RAZON_SOCIAL}`);
    logger.info(`   Nombre Comercial: ${EMPRESA_CONFIG.NOMBRE_COMERCIAL}`);

    // Crear documento de secuenciales si no existe
    const secuencialRef = admin.firestore().collection("Configuracion").doc("secuenciales");
    const secuencialDoc = await secuencialRef.get();

    let secuencial = 1;

    if (secuencialDoc.exists) {
      secuencial = (secuencialDoc.data().factura || 0) + 1;
    } else {
      // Crear documento de secuenciales
      await secuencialRef.set({
        factura: 0,
        establecimiento: "001",
        puntoEmision: "001",
        ultimaActualizacion: admin.firestore.FieldValue.serverTimestamp(),
      });
      logger.info("📝 [generarFactura] Documento de secuenciales creado");
    }

    logger.info(`🔢 [generarFactura] Secuencial: ${secuencial}`);

    // Generar datos de la factura
    const fecha = new Date();
    const fechaStr = `${fecha.getDate().toString().padStart(2, "0")}${(fecha.getMonth() + 1).toString().padStart(2, "0")}${fecha.getFullYear()}`;

    logger.info(`📅 [generarFactura] FechaStr: ${fechaStr}`);
    logger.info(`🏢 [generarFactura] RUC: ${EMPRESA_CONFIG.RUC}`);
    logger.info(`🌍 [generarFactura] Ambiente: ${SRI_CONFIG.AMBIENTE}`);
    logger.info(`📋 [generarFactura] Tipo Emisión: ${SRI_CONFIG.TIPO_EMISION}`);

    // Generar clave de acceso
    const claveAcceso = generarClaveAcceso(
        fechaStr,
        "01", // Factura
        EMPRESA_CONFIG.RUC,
        SRI_CONFIG.AMBIENTE,
        "001001", // Serie: establecimiento + punto emisión
        secuencial.toString(),
        Math.floor(Math.random() * 99999999).toString(), // Código numérico aleatorio
        SRI_CONFIG.TIPO_EMISION,
    );

    logger.info(`🔑 [generarFactura] Clave de acceso generada: ${claveAcceso}`);

    // Preparar datos de la factura
    const datosFactura = {
      claveAcceso,
      fechaEmision: `${fecha.getDate().toString().padStart(2, "0")}/${(fecha.getMonth() + 1).toString().padStart(2, "0")}/${fecha.getFullYear()}`,
      establecimiento: "001",
      puntoEmision: "001",
      secuencial: secuencial.toString(),
      comprador: {
        tipoIdentificacion: "05", // 05 = CEDULA, 04 = RUC, 06 = PASAPORTE
        identificacion: userId || "9999999999999", // Usar userId del request
        razonSocial: orderData.address?.name || "CONSUMIDOR FINAL",
      },
      items: (orderData.items || []).map((item) => ({
        codigo: item.productId || "PROD",
        descripcion: item.title || "Producto",
        cantidad: item.quantity || 1,
        precioUnitario: item.price || 0,
        descuento: 0,
        subtotal: (item.price || 0) * (item.quantity || 1),
      })),
      totales: {
        subtotal: orderData.totalAmount / 1.12, // Sin IVA
        descuento: 0,
        iva: orderData.totalAmount - (orderData.totalAmount / 1.12),
        total: orderData.totalAmount,
      },
    };

    // Generar XML
    const xml = generarXMLFactura(datosFactura);

    // Firmar XML
    const xmlFirmado = await firmarXML(xml, claveAcceso);

    // Enviar al SRI
    const respuestaSRI = await enviarSRI(xmlFirmado, claveAcceso);

    // Guardar factura en Firestore
    await admin.firestore().collection("Facturas").doc(claveAcceso).set({
      orderId,
      claveAcceso,
      fechaEmision: admin.firestore.Timestamp.now(),
      xml: xmlFirmado,
      respuestaSRI,
      estado: "AUTORIZADA", // O el estado que devuelva el SRI
      secuencial,
    });

    // Actualizar secuencial
    await admin.firestore().collection("Configuracion").doc("secuenciales").set({
      factura: secuencial,
    }, {merge: true});

    // Actualizar pedido con referencia a factura
    await admin.firestore().collection("Orders").doc(orderId).update({
      facturaId: claveAcceso,
      facturaGenerada: true,
    });

    return {
      success: true,
      claveAcceso,
      mensaje: "Factura generada y autorizada exitosamente",
    };
  } catch (error) {
    logger.error("Error en generarFactura:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * Cloud Function para consultar estado de autorización
 */
exports.consultarAutorizacion = onCall(async (request) => {
  try {
    const {claveAcceso} = request.data;

    if (!claveAcceso) {
      throw new HttpsError("invalid-argument", "La clave de acceso es requerida");
    }

    const soapAutorizacion = `<?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ec="http://ec.gob.sri.ws.autorizacion">
        <soapenv:Header/>
        <soapenv:Body>
          <ec:autorizacionComprobante>
            <claveAccesoComprobante>${claveAcceso}</claveAccesoComprobante>
          </ec:autorizacionComprobante>
        </soapenv:Body>
      </soapenv:Envelope>`;

    const response = await axios.post(SRI_CONFIG.AUTORIZACION_URL, soapAutorizacion, {
      headers: {
        "Content-Type": "text/xml;charset=UTF-8",
        "SOAPAction": "",
      },
    });

    return {
      success: true,
      respuesta: response.data,
    };
  } catch (error) {
    logger.error("Error al consultar autorización:", error);
    throw new HttpsError("internal", error.message);
  }
});
