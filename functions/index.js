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
const bwipjs = require("bwip-js");
const nodemailer = require("nodemailer");

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

// Configuración de Email
const EMAIL_CONFIG = {
  EMAIL: process.env.EMAIL_SENDER || "palaciosluisfer@gmail.com",
  PASSWORD: process.env.EMAIL_PASSWORD || "fpzv kpuv hqhz ozdd",
  NOMBRE_REMITENTE: "Men's Locker Clothing Ec - Factura Electronica",
};

// Configurar transporter de nodemailer
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: EMAIL_CONFIG.EMAIL,
    pass: EMAIL_CONFIG.PASSWORD,
  },
});

// Configuración global
setGlobalOptions({maxInstances: 10});

// Configuración del SRI (PRUEBAS)
const SRI_CONFIG = {
  RECEPCION_URL: "https://celcer.sri.gob.ec/comprobantes-electronicos-ws/RecepcionComprobantesOffline?wsdl",
  AUTORIZACION_URL: "https://celcer.sri.gob.ec/comprobantes-electronicos-ws/AutorizacionComprobantesOffline?wsdl",
  AMBIENTE: "1", // 1 = Pruebas, 2 = Producción
  TIPO_EMISION: "1", // 1 = Normal
};

/**
 * 🕐 CORRECCIÓN 1: Obtener fecha en zona horaria de Ecuador (UTC-5)
 * Resuelve el problema de "FECHA EMISIÓN EXTEMPORÁNEA"
 */
function obtenerFechaEcuador() {
  const ahora = new Date();

  // Ecuador está en UTC-5 (no cambia por horario de verano)
  // Ajustar la fecha restando 5 horas
  const ecuadorOffset = -5 * 60; // -5 horas en minutos
  const utcOffset = ahora.getTimezoneOffset(); // Offset del servidor en minutos
  const totalOffset = ecuadorOffset - utcOffset;

  const fechaEcuador = new Date(ahora.getTime() + totalOffset * 60 * 1000);

  logger.info(`🕐 [FechaEcuador] UTC: ${ahora.toISOString()}, Ecuador: ${fechaEcuador.toISOString()}`);

  return fechaEcuador;
}

/**
 * 🔧 Parser de XML de respuesta del SRI
 * Extrae información de la respuesta SOAP
 */
function parsearRespuestaSRI(xmlString, tipo) {
  try {
    // Extraer estado de recepción
    if (tipo === "recepcion") {
      const estadoMatch = xmlString.match(/<estado>(.*?)<\/estado>/);
      const estado = estadoMatch ? estadoMatch[1] : null;

      // Extraer mensajes de error si existen
      const mensajes = [];
      const mensajeRegex = /<mensaje>[\s\S]*?<identificador>(.*?)<\/identificador>[\s\S]*?<mensaje>(.*?)<\/mensaje>[\s\S]*?<informacionAdicional>(.*?)<\/informacionAdicional>[\s\S]*?<tipo>(.*?)<\/tipo>[\s\S]*?<\/mensaje>/g;

      let match;
      while ((match = mensajeRegex.exec(xmlString)) !== null) {
        mensajes.push({
          identificador: match[1],
          mensaje: match[2],
          informacionAdicional: match[3],
          tipo: match[4],
        });
      }

      return {
        estado,
        mensajes,
        estadoValido: estado === "RECIBIDA",
      };
    }

    // Extraer información de autorización
    if (tipo === "autorizacion") {
      const claveMatch = xmlString.match(/<claveAccesoConsultada>(.*?)<\/claveAccesoConsultada>/);
      const numeroMatch = xmlString.match(/<numeroComprobantes>(.*?)<\/numeroComprobantes>/);

      const numeroComprobantes = numeroMatch ? parseInt(numeroMatch[1]) : 0;

      // Extraer número de autorización si existe
      const autorizacionMatch = xmlString.match(/<numeroAutorizacion>(.*?)<\/numeroAutorizacion>/);
      const fechaAutorizacionMatch = xmlString.match(/<fechaAutorizacion>(.*?)<\/fechaAutorizacion>/);

      return {
        claveAcceso: claveMatch ? claveMatch[1] : null,
        numeroComprobantes,
        numeroAutorizacion: autorizacionMatch ? autorizacionMatch[1] : null,
        fechaAutorizacion: fechaAutorizacionMatch ? fechaAutorizacionMatch[1] : null,
        autorizado: numeroComprobantes > 0,
      };
    }

    return null;
  } catch (error) {
    logger.error("Error al parsear respuesta SRI:", error);
    return null;
  }
}

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

  // ✅ ESTRUCTURA CORRECTA DE LA CLAVE DE ACCESO (49 DÍGITOS):
  // [Fecha 8][Tipo 2][RUC 13][Ambiente 1][Serie 6][Secuencial 9][CodNum 8][Emision 1][Verificador 1]
  // El RUC va COMPLETO con 13 dígitos (ej: 1003066535001)

  const claveBase = fecha.replace(/\//g, "") + // ddmmyyyy (8)
                    tipoComprobante.padStart(2, "0") + // TT (2)
                    ruc + // rrrrrrrrrrrr (13) ✅ RUC COMPLETO
                    ambiente + // a (1)
                    serie + // ssssss (6)
                    numeroComprobante.padStart(9, "0") + // nnnnnnnnn (9)
                    codigoNumerico.padStart(8, "0") + // cccccccc (8)
                    tipoEmision; // t (1)

  logger.info(`[generarClaveAcceso] Clave base generada: ${claveBase} (${claveBase.length} dígitos)`);
  logger.info(`[generarClaveAcceso] Desglose: Fecha(8)=${fecha.replace(/\//g, "")} + Tipo(2)=${tipoComprobante.padStart(2, "0")} + RUC(13)=${ruc} + Ambiente(1)=${ambiente} + Serie(6)=${serie} + Sec(9)=${numeroComprobante.padStart(9, "0")} + Cod(8)=${codigoNumerico.padStart(8, "0")} + Emi(1)=${tipoEmision}`);

  // VALIDACIÓN: La clave base debe tener 48 dígitos (sin el verificador)
  if (claveBase.length !== 48) {
    throw new Error(`ERROR: La clave base debe tener 48 dígitos, pero tiene ${claveBase.length}. Clave: ${claveBase}`);
  }

  // Calcular dígito verificador (módulo 11)
  let suma = 0;
  let factor = 7;

  for (let i = 0; i < claveBase.length; i++) {
    suma += parseInt(claveBase[i]) * factor;
    factor = factor === 2 ? 7 : factor - 1;
  }

  const modulo = suma % 11;
  const digitoVerificador = modulo === 0 ? 0 : (11 - modulo);

  const claveAccesoFinal = claveBase + digitoVerificador;

  logger.info(`[generarClaveAcceso] ✅ Clave de acceso generada: ${claveAccesoFinal} (${claveAccesoFinal.length} dígitos)`);

  // VALIDACIÓN FINAL: La clave debe tener exactamente 49 dígitos
  if (claveAccesoFinal.length !== 49) {
    throw new Error(`ERROR CRÍTICO: La clave de acceso debe tener 49 dígitos, pero tiene ${claveAccesoFinal.length}. Clave: ${claveAccesoFinal}`);
  }

  return claveAccesoFinal;
}

/**
 * 🔧 Genera el XML de la factura según especificación del SRI
 * Estructura completa con IVA 15%, forma de pago, y datos del comprador
 */
function generarXMLFactura(datosFactura) {
  const {claveAcceso, fechaEmision, comprador, items, totales, formaPago} = datosFactura;

  const root = create({version: "1.0", encoding: "UTF-8"})
      .ele("factura", {id: "comprobante", version: "1.0.0"})
      // === INFO TRIBUTARIA ===
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
      .up() // Cierra infoTributaria
      // === INFO FACTURA ===
      .ele("infoFactura")
      .ele("fechaEmision").txt(fechaEmision).up()
      .ele("dirEstablecimiento").txt(EMPRESA_CONFIG.DIRECCION_MATRIZ).up()
      .ele("obligadoContabilidad").txt(EMPRESA_CONFIG.OBLIGADO_CONTABILIDAD).up()
      .ele("tipoIdentificacionComprador").txt(comprador.tipoIdentificacion).up()
      .ele("razonSocialComprador").txt(comprador.razonSocial).up()
      .ele("identificacionComprador").txt(comprador.identificacion).up()
      .ele("direccionComprador").txt(comprador.direccion).up()
      .ele("totalSinImpuestos").txt(totales.subtotal.toFixed(2)).up()
      .ele("totalDescuento").txt(totales.descuento.toFixed(2)).up()
      // === TOTAL CON IMPUESTOS ===
      .ele("totalConImpuestos")
      .ele("totalImpuesto")
      .ele("codigo").txt("2").up() // 2 = IVA
      .ele("codigoPorcentaje").txt("4").up() // 4 = 15% IVA
      .ele("baseImponible").txt(totales.subtotalIva.toFixed(2)).up()
      .ele("valor").txt(totales.valorIva.toFixed(2)).up()
      .up() // Cierra totalImpuesto
      .up() // Cierra totalConImpuestos
      .ele("importeTotal").txt(totales.total.toFixed(2)).up()
      .ele("moneda").txt("DOLAR").up()
      // === PAGOS (obligatorio según SRI) ===
      .ele("pagos")
      .ele("pago")
      .ele("formaPago").txt(formaPago.codigo).up()
      .ele("total").txt(formaPago.total.toFixed(2)).up()
      .ele("plazo").txt("0").up() // Pago inmediato
      .ele("unidadTiempo").txt("dias").up()
      .up() // Cierra pago
      .up() // Cierra pagos
      .ele("valorRetIva").txt("0.00").up()
      .ele("valorRetRenta").txt("0.00").up()
      .up(); // ✅ CIERRA infoFactura AQUÍ

  // 🔧 CORRECCIÓN CRÍTICA: detalles e infoAdicional van FUERA de infoFactura
  // === DETALLES (productos) - FUERA DE infoFactura ===
  const detallesNode = root.ele("detalles");

  items.forEach((item) => {
    detallesNode.ele("detalle")
        .ele("codigoPrincipal").txt(item.codigo || "PROD").up()
        .ele("descripcion").txt(item.descripcion).up()
        .ele("cantidad").txt(item.cantidad.toString()).up()
        .ele("precioUnitario").txt(item.precioUnitario.toFixed(6)).up()
        .ele("descuento").txt(item.descuento.toFixed(2)).up()
        .ele("precioTotalSinImpuesto").txt(item.subtotal.toFixed(2)).up()
        // === IMPUESTOS DEL ITEM ===
        .ele("impuestos")
        .ele("impuesto")
        .ele("codigo").txt("2").up() // 2 = IVA
        .ele("codigoPorcentaje").txt("4").up() // 4 = 15%
        .ele("tarifa").txt("15").up() // Tarifa 15%
        .ele("baseImponible").txt(item.baseIva.toFixed(2)).up()
        .ele("valor").txt(item.valorIva.toFixed(2)).up()
        .up() // Cierra impuesto
        .up() // Cierra impuestos
        .up(); // Cierra detalle
  });

  detallesNode.up(); // Cierra detalles

  // === INFO ADICIONAL - FUERA DE infoFactura ===
  root.ele("infoAdicional")
      .ele("campoAdicional", {nombre: "Correo"}).txt(comprador.correo).up()
      .ele("campoAdicional", {nombre: "Teléfono"}).txt(comprador.telefono).up()
      .up(); // Cierra infoAdicional


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
 * 🔧 CORRECCIÓN 2 y 3: Envía el XML firmado al SRI con validación de respuesta
 * Parsea la respuesta XML y valida el estado correcto
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

    // 🔧 CORRECCIÓN 3: Parsear respuesta de recepción
    const recepcionParsed = parsearRespuestaSRI(responseRecepcion.data, "recepcion");

    logger.info("🔍 Recepción parseada:", recepcionParsed);

    // 🔧 CORRECCIÓN 2: Validar estado de recepción
    if (!recepcionParsed || recepcionParsed.estado !== "RECIBIDA") {
      const mensajesError = recepcionParsed?.mensajes || [];
      const detalleError = mensajesError.map((m) =>
        `[${m.identificador}] ${m.mensaje}: ${m.informacionAdicional}`
      ).join("; ");

      logger.warn(`⚠️ SRI rechazó el comprobante: ${recepcionParsed?.estado || "DESCONOCIDO"}`);
      logger.warn(`📋 Mensajes del SRI: ${detalleError}`);

      return {
        recepcion: responseRecepcion.data,
        recepcionParsed,
        autorizacion: null,
        autorizacionParsed: null,
        estado: "DEVUELTA",
        mensajesError,
        esValido: false,
      };
    }

    // Si la recepción fue exitosa, consultar autorización
    logger.info("✅ Recepción EXITOSA, consultando autorización...");

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

    // 🔧 CORRECCIÓN 3: Parsear respuesta de autorización
    const autorizacionParsed = parsearRespuestaSRI(responseAutorizacion.data, "autorizacion");

    logger.info("🔍 Autorización parseada:", autorizacionParsed);

    // 🔧 CORRECCIÓN 2: Validar autorización
    const autorizado = autorizacionParsed && autorizacionParsed.numeroComprobantes > 0;

    return {
      recepcion: responseRecepcion.data,
      recepcionParsed,
      autorizacion: responseAutorizacion.data,
      autorizacionParsed,
      estado: autorizado ? "AUTORIZADA" : "RECIBIDA_SIN_AUTORIZAR",
      numeroAutorizacion: autorizacionParsed?.numeroAutorizacion,
      fechaAutorizacion: autorizacionParsed?.fechaAutorizacion,
      esValido: true,
      autorizado,
    };
  } catch (error) {
    logger.error("Error al enviar al SRI:", error);
    throw new HttpsError("internal", "Error al comunicarse con el SRI: " + error.message);
  }
}

/**
 * 🔧 FUNCIÓN HELPER: Guardar log detallado en Firestore
 */
async function guardarLogFacturacion(tipo, mensaje, datos = null, orderId = null) {
  try {
    const timestamp = admin.firestore.Timestamp.now();
    await admin.firestore().collection("FacturasDebug").add({
      tipo, // 'INFO', 'ERROR', 'WARNING', 'SUCCESS'
      mensaje,
      datos: datos || {},
      orderId,
      timestamp,
      timestampFormatted: new Date().toISOString(),
    });

    // También log en consola
    const emoji = {
      'INFO': 'ℹ️',
      'ERROR': '❌',
      'WARNING': '⚠️',
      'SUCCESS': '✅',
    }[tipo] || '📝';

    logger.info(`${emoji} [LOG] ${mensaje}`, datos || {});
  } catch (error) {
    logger.error("Error al guardar log:", error);
  }
}

/**
 * 🔧 FUNCIÓN HELPER: Lógica principal de generación de factura
 * Extraída para poder ser llamada tanto desde onCall como desde HTTP
 */
async function procesarGeneracionFactura(orderId, userId) {
  await guardarLogFacturacion('INFO', 'INICIO: Proceso de generación de factura', {orderId, userId}, orderId);

  if (!orderId) {
    await guardarLogFacturacion('ERROR', 'ERROR: orderId no proporcionado', null, orderId);
    throw new HttpsError("invalid-argument", "El ID del pedido es requerido");
  }

  if (!userId) {
    await guardarLogFacturacion('ERROR', 'ERROR: userId no proporcionado', null, orderId);
    throw new HttpsError("invalid-argument", "El ID del usuario es requerido");
  }

  logger.info(`📄 [generarFactura] Iniciando para pedido: ${orderId}, usuario: ${userId}`);

  // PASO 1: Obtener pedido de Firestore
  await guardarLogFacturacion('INFO', 'PASO 1: Buscando pedido en Firestore', {
    ruta: `Users/${userId}/Orders/${orderId}`,
  }, orderId);

  const orderDoc = await admin.firestore()
      .collection("Users")
      .doc(userId)
      .collection("Orders")
      .doc(orderId)
      .get();

  if (!orderDoc.exists) {
    await guardarLogFacturacion('ERROR', 'ERROR CRÍTICO: Pedido no encontrado en Firestore', {
      ruta: `Users/${userId}/Orders/${orderId}`,
    }, orderId);
    logger.error(`❌ [generarFactura] Pedido no encontrado: Users/${userId}/Orders/${orderId}`);
    throw new HttpsError("not-found", "Pedido no encontrado");
  }

  const orderData = orderDoc.data();
  await guardarLogFacturacion('SUCCESS', 'PASO 1 COMPLETADO: Pedido encontrado', {
    itemsCount: orderData.items?.length || 0,
    totalAmount: orderData.totalAmount,
  }, orderId);
  logger.info(`✅ [generarFactura] Pedido encontrado. Items: ${orderData.items?.length || 0}`);

  // PASO 2: Validar configuración de empresa
  await guardarLogFacturacion('INFO', 'PASO 2: Validando configuración de empresa', {
    RUC: EMPRESA_CONFIG.RUC,
    RAZON_SOCIAL: EMPRESA_CONFIG.RAZON_SOCIAL,
    NOMBRE_COMERCIAL: EMPRESA_CONFIG.NOMBRE_COMERCIAL,
  }, orderId);

  logger.info(`🏢 [generarFactura] Configuración empresa:`);
  logger.info(`   RUC: ${EMPRESA_CONFIG.RUC}`);
  logger.info(`   Razón Social: ${EMPRESA_CONFIG.RAZON_SOCIAL}`);
  logger.info(`   Nombre Comercial: ${EMPRESA_CONFIG.NOMBRE_COMERCIAL}`);

  // PASO 3: Obtener/Crear secuencial
  await guardarLogFacturacion('INFO', 'PASO 3: Obteniendo secuencial de factura', null, orderId);

  const secuencialRef = admin.firestore().collection("Configuracion").doc("secuenciales");
  const secuencialDoc = await secuencialRef.get();

  let secuencial = 1;

  if (secuencialDoc.exists) {
    secuencial = (secuencialDoc.data().factura || 0) + 1;
    await guardarLogFacturacion('INFO', 'Secuencial obtenido de Firestore', {secuencial}, orderId);
  } else {
    // Crear documento de secuenciales
    await secuencialRef.set({
      factura: 0,
      establecimiento: "001",
      puntoEmision: "001",
      ultimaActualizacion: admin.firestore.FieldValue.serverTimestamp(),
    });
    await guardarLogFacturacion('INFO', 'Documento de secuenciales creado (primera factura)', {secuencial}, orderId);
    logger.info("📝 [generarFactura] Documento de secuenciales creado");
  }

  logger.info(`🔢 [generarFactura] Secuencial: ${secuencial}`);

  // PASO 4: Generar clave de acceso
  await guardarLogFacturacion('INFO', 'PASO 4: Generando clave de acceso', {secuencial}, orderId);

  // 🔧 CORRECCIÓN 1: Usar fecha de Ecuador (UTC-5)
  const fechaEcuador = obtenerFechaEcuador();
  const fechaStr = `${fechaEcuador.getDate().toString().padStart(2, "0")}${(fechaEcuador.getMonth() + 1).toString().padStart(2, "0")}${fechaEcuador.getFullYear()}`;

  logger.info(`📅 [generarFactura] Fecha Ecuador (UTC-5): ${fechaEcuador.toISOString()}`);
  logger.info(`📅 [generarFactura] FechaStr para clave: ${fechaStr}`);
  logger.info(`🏢 [generarFactura] RUC: ${EMPRESA_CONFIG.RUC}`);
  logger.info(`🌍 [generarFactura] Ambiente: ${SRI_CONFIG.AMBIENTE}`);
  logger.info(`📋 [generarFactura] Tipo Emisión: ${SRI_CONFIG.TIPO_EMISION}`);

  const codigoNumerico = Math.floor(Math.random() * 99999999).toString();

  await guardarLogFacturacion('INFO', 'Parámetros para clave de acceso', {
    fechaStr,
    tipoComprobante: "01",
    ruc: EMPRESA_CONFIG.RUC,
    ambiente: SRI_CONFIG.AMBIENTE,
    serie: "001001",
    secuencial: secuencial.toString(),
    codigoNumerico,
    tipoEmision: SRI_CONFIG.TIPO_EMISION,
  }, orderId);

  // Generar clave de acceso
  const claveAcceso = generarClaveAcceso(
      fechaStr,
      "01", // Factura
      EMPRESA_CONFIG.RUC,
      SRI_CONFIG.AMBIENTE,
      "001001", // Serie: establecimiento + punto emisión
      secuencial.toString(),
      codigoNumerico,
      SRI_CONFIG.TIPO_EMISION,
  );

  await guardarLogFacturacion('SUCCESS', 'PASO 4 COMPLETADO: Clave de acceso generada', {claveAcceso}, orderId);
  logger.info(`🔑 [generarFactura] Clave de acceso generada: ${claveAcceso}`);

  // PASO 5: Preparar datos de la factura
  await guardarLogFacturacion('INFO', 'PASO 5: Preparando datos de la factura', null, orderId);

  // 🔧 OBTENER DATOS DEL USUARIO PARA FACTURACIÓN
  const userDoc = await admin.firestore().collection("Users").doc(userId).get();
  const userData = userDoc.data();

  // 🔧 Usar fechaEcuador para fechaEmision
  const datosFactura = {
    claveAcceso,
    fechaEmision: `${fechaEcuador.getDate().toString().padStart(2, "0")}/${(fechaEcuador.getMonth() + 1).toString().padStart(2, "0")}/${fechaEcuador.getFullYear()}`,
    establecimiento: "001",
    puntoEmision: "001",
    secuencial: secuencial.toString(),
    comprador: {
      // 🔧 Usar cédula real del usuario
      tipoIdentificacion: userData?.Cedula && userData.Cedula.length === 13 ? "04" : userData?.Cedula && userData.Cedula.length === 10 ? "05" : "07", // 04=RUC, 05=Cédula, 07=Consumidor Final
      identificacion: userData?.Cedula || "9999999999999",
      razonSocial: `${userData?.FirstName || ""} ${userData?.LastName || ""}`.trim() || "CONSUMIDOR FINAL",
      direccion: orderData.address?.Street || orderData.address?.street || "N/A", // 🔧 Probar Street (mayúscula) y street (minúscula)
      telefono: userData?.PhoneNumber || orderData.address?.PhoneNumber || orderData.address?.phoneNumber || "",
      correo: userData?.Email || "",
    },
    // 🔧 Determinar forma de pago según tipo de tarjeta
    formaPago: {
      codigo: orderData.paymentMethod && orderData.paymentMethod.includes("débito") ? "16" : // Tarjeta de débito
               orderData.paymentMethod && orderData.paymentMethod.includes("crédito") ? "19" : // Tarjeta de crédito
               "01", // Sin utilización del sistema financiero (por defecto)
      total: orderData.totalAmount || 0,
    },
    items: (orderData.items || []).map((item) => {
      const precioUnitario = item.price || 0;
      const cantidad = item.quantity || 1;
      const descuento = item.discount || 0;
      const subtotalSinDescuento = precioUnitario * cantidad;
      const subtotalConDescuento = subtotalSinDescuento - descuento;

      // 🔧 Calcular IVA 15% (código "4" del SRI)
      const baseImponible = subtotalConDescuento;
      const valorIva = baseImponible * 0.15;

      // 🔧 Generar SKU automático si no existe
      let codigoProducto;
      if (item.sku) {
        // Si tiene SKU, usarlo
        codigoProducto = item.sku;
      } else if (item.productId) {
        // Si no tiene SKU, generar uno automático a partir del productId
        // Formato: PROD-[primeros 8 caracteres en mayúsculas]
        codigoProducto = `PROD-${item.productId.substring(0, 8).toUpperCase()}`;
      } else {
        // Fallback final
        codigoProducto = "PROD-SIN-CODIGO";
      }

      return {
        codigo: codigoProducto, // 🔧 SKU generado automáticamente si no existe
        descripcion: item.title || "Producto",
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        descuento: descuento,
        subtotal: subtotalConDescuento,
        baseIva: baseImponible,
        porcentajeIva: "4", // 4 = 15% (IVA actual en Ecuador)
        valorIva: valorIva,
        total: baseImponible + valorIva,
      };
    }),
    totales: {
      // 🔧 Calcular correctamente con IVA 15%
      subtotal: orderData.totalAmount / 1.15, // Sin IVA (base imponible)
      subtotalIva: orderData.totalAmount / 1.15, // Subtotal con IVA 15%
      subtotalCero: 0, // Productos con IVA 0%
      descuento: orderData.discount || 0, // Descuento total (cupones)
      valorIva: orderData.totalAmount - (orderData.totalAmount / 1.15), // Valor del IVA 15%
      total: orderData.totalAmount,
    },
  };

  await guardarLogFacturacion('SUCCESS', 'PASO 5 COMPLETADO: Datos de factura preparados', {
    compradorIdentificacion: datosFactura.comprador.identificacion,
    compradorNombre: datosFactura.comprador.razonSocial,
    compradorTipo: datosFactura.comprador.tipoIdentificacion,
    compradorCorreo: datosFactura.comprador.correo,
    itemsCount: datosFactura.items.length,
    total: datosFactura.totales.total,
    fechaEmision: datosFactura.fechaEmision,
  }, orderId);

  // PASO 6: Generar XML
  await guardarLogFacturacion('INFO', 'PASO 6: Generando XML de la factura', null, orderId);

  const xml = generarXMLFactura(datosFactura);

  // 🔧 DEBUG: Loggear el XML generado para verificar estructura
  logger.info(`📄 [DEBUG XML] Primeros 2000 caracteres del XML:\n${xml.substring(0, 2000)}`);
  logger.info(`📄 [DEBUG XML] XML completo length: ${xml.length}`);

  // Buscar específicamente la sección problemática
  const totalConImpuestosIndex = xml.indexOf('<totalConImpuestos>');
  if (totalConImpuestosIndex !== -1) {
    const seccionProblematica = xml.substring(totalConImpuestosIndex, totalConImpuestosIndex + 500);
    logger.info(`🔍 [DEBUG XML] Sección totalConImpuestos:\n${seccionProblematica}`);
  }

  await guardarLogFacturacion('SUCCESS', 'PASO 6 COMPLETADO: XML generado', {
    xmlLength: xml.length,
    xmlPreview: xml.substring(0, 1000), // Guardar preview en Firestore
  }, orderId);
  logger.info(`📄 [generarFactura] XML generado correctamente`);

  // PASO 7: Firmar XML
  await guardarLogFacturacion('INFO', 'PASO 7: Firmando XML con certificado digital', null, orderId);

  let xmlFirmado;
  try {
    xmlFirmado = await firmarXML(xml, claveAcceso);
    await guardarLogFacturacion('SUCCESS', 'PASO 7 COMPLETADO: XML firmado correctamente', {
      xmlFirmadoLength: xmlFirmado.length,
    }, orderId);
    logger.info(`✅ [generarFactura] XML firmado correctamente`);
  } catch (errorFirma) {
    await guardarLogFacturacion('ERROR', 'ERROR EN PASO 7: Error al firmar XML', {
      error: errorFirma.message,
      stack: errorFirma.stack,
    }, orderId);
    throw errorFirma;
  }

  let respuestaSRI = null;
  let estadoFactura = "PENDIENTE";
  let mensajesErrorSRI = [];
  let numeroAutorizacion = null;
  let fechaAutorizacion = null;

  // PASO 8: Intentar enviar al SRI
  await guardarLogFacturacion('INFO', 'PASO 8: Enviando factura al SRI', {
    urlRecepcion: SRI_CONFIG.RECEPCION_URL,
    urlAutorizacion: SRI_CONFIG.AUTORIZACION_URL,
  }, orderId);

  try {
    logger.info(`📤 [generarFactura] Enviando al SRI...`);
    respuestaSRI = await enviarSRI(xmlFirmado, claveAcceso);

    // 🔧 CORRECCIÓN 2: Validar respuesta real del SRI
    if (respuestaSRI.esValido) {
      if (respuestaSRI.autorizado) {
        estadoFactura = "AUTORIZADA";
        numeroAutorizacion = respuestaSRI.numeroAutorizacion;
        fechaAutorizacion = respuestaSRI.fechaAutorizacion;
        logger.info(`✅ [generarFactura] Factura AUTORIZADA por el SRI`);
      } else {
        estadoFactura = "RECIBIDA";
        logger.info(`ℹ️ [generarFactura] Factura RECIBIDA pero no autorizada aún`);
      }
    } else {
      // El SRI devolvió la factura
      estadoFactura = "DEVUELTA";
      mensajesErrorSRI = respuestaSRI.mensajesError || [];
      logger.warn(`⚠️ [generarFactura] Factura DEVUELTA por el SRI`);
    }

    await guardarLogFacturacion('SUCCESS', 'PASO 8 COMPLETADO: SRI respondió correctamente', {
      estado: estadoFactura,
      esValido: respuestaSRI.esValido,
      autorizado: respuestaSRI.autorizado,
      numeroAutorizacion,
      mensajesError: mensajesErrorSRI.length > 0 ? mensajesErrorSRI : undefined,
    }, orderId);
    logger.info(`📊 [generarFactura] Estado final del SRI: ${estadoFactura}`);
  } catch (errorSRI) {
    await guardarLogFacturacion('WARNING', 'PASO 8 CON ERROR: No se pudo conectar con el SRI', {
      error: errorSRI.message,
      stack: errorSRI.stack,
      urlRecepcion: SRI_CONFIG.RECEPCION_URL,
      urlAutorizacion: SRI_CONFIG.AUTORIZACION_URL,
    }, orderId);
    logger.warn(`⚠️ [generarFactura] No se pudo enviar al SRI (no crítico): ${errorSRI.message}`);
    logger.warn(`⚠️ La factura se guardará como PENDIENTE y podrá reenviarse después`);
    estadoFactura = "ERROR_COMUNICACION";
    // No lanzamos error, continuamos guardando la factura
  }

  // PASO 9: Guardar factura en Firestore
  await guardarLogFacturacion('INFO', 'PASO 9: Guardando factura en Firestore', {
    claveAcceso,
    estado: estadoFactura,
  }, orderId);

  logger.info(`💾 [generarFactura] Guardando factura en Firestore...`);

  // 🔧 CORRECCIÓN 2: Guardar información completa del SRI
  const facturaData = {
    orderId,
    userId,
    claveAcceso,
    fechaEmision: admin.firestore.Timestamp.now(),
    xml: xmlFirmado,
    xmlSinFirmar: xml,
    respuestaSRI: respuestaSRI || {error: "No se pudo conectar con el SRI"},
    estado: estadoFactura,
    secuencial,
    establecimiento: "001",
    puntoEmision: "001",
    totalAmount: orderData.totalAmount || 0,
    comprador: datosFactura.comprador,
  };

  // Agregar información adicional si está disponible
  if (numeroAutorizacion) {
    facturaData.numeroAutorizacion = numeroAutorizacion;
  }
  if (fechaAutorizacion) {
    facturaData.fechaAutorizacion = fechaAutorizacion;
  }
  if (mensajesErrorSRI.length > 0) {
    facturaData.mensajesErrorSRI = mensajesErrorSRI;
  }
  if (pdfUrl) {
    facturaData.pdfUrl = pdfUrl;
  }

  await admin.firestore().collection("Facturas").doc(claveAcceso).set(facturaData);

  await guardarLogFacturacion('SUCCESS', 'PASO 9 COMPLETADO: Factura guardada en Firestore', {
    coleccion: 'Facturas',
    documentId: claveAcceso,
    estadoGuardado: estadoFactura,
  }, orderId);
  logger.info(`✅ [generarFactura] Factura guardada en Firestore con estado: ${estadoFactura}`);

  // PASO 9.1: Generar PDF de la factura
  let pdfBuffer = null;
  let pdfUrl = null;
  try {
    await guardarLogFacturacion('INFO', 'PASO 9.1: Generando PDF de factura', null, orderId);

    pdfBuffer = await generarPDFFactura({
      ...datosFactura,
      claveAcceso,
      estado: estadoFactura,
      numeroAutorizacion,
      fechaAutorizacion,
    });

    await guardarLogFacturacion('SUCCESS', 'PASO 9.1 COMPLETADO: PDF generado exitosamente', {
      pdfSize: pdfBuffer.length,
    }, orderId);
    logger.info(`✅ [generarFactura] PDF generado (${pdfBuffer.length} bytes)`);

    // PASO 9.1.1: Guardar PDF en Firebase Storage
    await guardarLogFacturacion('INFO', 'PASO 9.1.1: Guardando PDF en Firebase Storage', null, orderId);

    const bucket = admin.storage().bucket();
    const numeroFactura = `${datosFactura.establecimiento}-${datosFactura.puntoEmision}-${datosFactura.secuencial.toString().padStart(9, "0")}`;
    const pdfFileName = `Facturas/${numeroFactura}_${claveAcceso}.pdf`;
    const pdfFile = bucket.file(pdfFileName);

    await pdfFile.save(pdfBuffer, {
      metadata: {
        contentType: 'application/pdf',
        metadata: {
          orderId: orderId,
          claveAcceso: claveAcceso,
          numeroFactura: numeroFactura,
        },
      },
    });

    // Hacer el archivo público para acceso directo
    await pdfFile.makePublic();

    // Obtener URL pública
    pdfUrl = `https://storage.googleapis.com/${bucket.name}/${pdfFileName}`;

    await guardarLogFacturacion('SUCCESS', 'PASO 9.1.1 COMPLETADO: PDF guardado en Storage', {
      pdfUrl: pdfUrl,
      fileName: pdfFileName,
    }, orderId);
    logger.info(`✅ [generarFactura] PDF guardado en Storage: ${pdfUrl}`);
  } catch (errorPDF) {
    await guardarLogFacturacion('WARNING', 'PASO 9.1 ADVERTENCIA: Error al generar o guardar PDF', {
      error: errorPDF.message,
    }, orderId);
    logger.warn(`⚠️ [generarFactura] Error al generar o guardar PDF:`, errorPDF);
  }

  // PASO 9.2: Enviar email con PDF y XML
  try {
    await guardarLogFacturacion('INFO', 'PASO 9.2: Enviando email con factura', {
      correoDestino: datosFactura.comprador.correo,
    }, orderId);

    const emailEnviado = await enviarEmailFactura({
      correo: datosFactura.comprador.correo,
      nombreCliente: datosFactura.comprador.razonSocial,
      claveAcceso,
      numeroFactura: `${datosFactura.establecimiento}-${datosFactura.puntoEmision}-${datosFactura.secuencial.toString().padStart(9, "0")}`,
      pdfBuffer,
      xmlBuffer: Buffer.from(xmlFirmado, "utf-8"),
      estadoFactura,
    });

    if (emailEnviado) {
      await guardarLogFacturacion('SUCCESS', 'PASO 9.2 COMPLETADO: Email enviado exitosamente', {
        correo: datosFactura.comprador.correo,
      }, orderId);
      logger.info(`✅ [generarFactura] Email enviado a ${datosFactura.comprador.correo}`);
    }
  } catch (errorEmail) {
    await guardarLogFacturacion('WARNING', 'PASO 9.2 ADVERTENCIA: Error al enviar email', {
      error: errorEmail.message,
    }, orderId);
    logger.warn(`⚠️ [generarFactura] Error al enviar email:`, errorEmail);
  }

  // PASO 10: Actualizar secuencial
  await guardarLogFacturacion('INFO', 'PASO 10: Actualizando secuencial', {secuencial}, orderId);

  await admin.firestore().collection("Configuracion").doc("secuenciales").set({
    factura: secuencial,
    ultimaActualizacion: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  await guardarLogFacturacion('SUCCESS', 'PASO 10 COMPLETADO: Secuencial actualizado', {secuencial}, orderId);
  logger.info(`✅ [generarFactura] Secuencial actualizado a ${secuencial}`);

  // PASO 11: Actualizar pedido con referencia a factura
  await guardarLogFacturacion('INFO', 'PASO 11: Actualizando pedido con referencia a factura', {
    ruta: `Users/${userId}/Orders/${orderId}`,
  }, orderId);

  await admin.firestore()
      .collection("Users")
      .doc(userId)
      .collection("Orders")
      .doc(orderId)
      .update({
        facturaId: claveAcceso,
        facturaGenerada: true,
      });

  await guardarLogFacturacion('SUCCESS', 'PASO 11 COMPLETADO: Pedido actualizado', {
    facturaId: claveAcceso,
  }, orderId);
  logger.info(`✅ [generarFactura] Pedido actualizado con facturaId`);

  // FINALIZACIÓN - 🔧 CORRECCIÓN 2: Mensaje según estado real
  let mensajeFinal;
  let success = true;

  switch (estadoFactura) {
    case "AUTORIZADA":
      mensajeFinal = "Factura generada y autorizada exitosamente por el SRI";
      break;
    case "RECIBIDA":
      mensajeFinal = "Factura recibida por el SRI. Autorización en proceso";
      break;
    case "DEVUELTA":
      mensajeFinal = `Factura devuelta por el SRI. Motivo: ${mensajesErrorSRI.map((m) => m.mensaje).join(", ")}`;
      success = false;
      break;
    case "ERROR_COMUNICACION":
      mensajeFinal = "Factura generada pero no se pudo enviar al SRI. Se puede reintentar después";
      break;
    default:
      mensajeFinal = "Factura generada. Estado pendiente de verificación";
  }

  await guardarLogFacturacion('SUCCESS', '🎉 PROCESO COMPLETADO', {
    claveAcceso,
    estado: estadoFactura,
    mensaje: mensajeFinal,
    success,
  }, orderId);

  return {
    success,
    claveAcceso,
    estado: estadoFactura,
    mensaje: mensajeFinal,
    numeroAutorizacion: numeroAutorizacion || undefined,
    mensajesError: mensajesErrorSRI.length > 0 ? mensajesErrorSRI : undefined,
  };
}

/**
 * Cloud Function principal para generar factura (onCall)
 * Llamada desde la app móvil después de confirmar el pedido
 */
exports.generarFactura = onCall({
  maxInstances: 5,
  memory: "512MiB", // 🔧 Aumentado de 256MB a 512MB para generación de PDF + envío de email
  secrets: [certificadoPassword], // Declarar que esta función usa secrets
}, async (request) => {
  try {
    const {orderId, userId} = request.data;
    return await procesarGeneracionFactura(orderId, userId);
  } catch (error) {
    await guardarLogFacturacion('ERROR', '💥 ERROR CRÍTICO EN PROCESO', {
      error: error.message,
      stack: error.stack,
      code: error.code,
    }, request.data?.orderId);
    logger.error("Error en generarFactura:", error);
    throw new HttpsError("internal", error.message);
  }
});

/**
 * 🧪 ENDPOINT HTTP DE PRUEBA (solo para desarrollo)
 * Permite probar la generación de factura directamente desde Postman/navegador
 *
 * URL: https://us-central1-[PROJECT_ID].cloudfunctions.net/generarFacturaTest
 * Método: POST
 * Body: { "orderId": "xxx", "userId": "yyy" }
 */
const {onRequest} = require("firebase-functions/v2/https");

exports.generarFacturaTest = onRequest({
  secrets: [certificadoPassword],
  memory: "512MiB", // 🔧 Aumentado para evitar errores de memoria
  cors: true, // Habilitar CORS para pruebas desde navegador
}, async (req, res) => {
  try {
    // Solo permitir POST
    if (req.method !== "POST") {
      res.status(405).send({error: "Método no permitido. Use POST"});
      return;
    }

    const {orderId, userId} = req.body;

    logger.info(`🧪 [TEST] Llamada a endpoint de prueba: orderId=${orderId}, userId=${userId}`);

    // Llamar a la función principal
    const resultado = await procesarGeneracionFactura(orderId, userId);

    res.status(200).send({
      success: true,
      mensaje: "✅ Endpoint de prueba ejecutado correctamente",
      resultado,
    });
  } catch (error) {
    logger.error("❌ [TEST] Error en endpoint de prueba:", error);
    res.status(500).send({
      success: false,
      error: error.message,
      stack: error.stack,
    });
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

// ═══════════════════════════════════════════════════════════════════════════
// 📧 SISTEMA DE ENVÍO DE FACTURAS POR EMAIL
// ═══════════════════════════════════════════════════════════════════════════


// Configuración del transporter de Gmail
const emailConfig = {
  user: process.env.GMAIL_USER,
  password: process.env.GMAIL_APP_PASSWORD,
  fromName: process.env.EMAIL_FROM_NAME || "Factura Electrónica",
};

/**
 * Crear transporter de nodemailer con Gmail
 */
function crearTransporterEmail() {
  logger.info("📧 [EMAIL] Creando transporter con Gmail...");
  logger.info(`📧 [EMAIL] Usuario: ${emailConfig.user}`);

  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: emailConfig.user,
      pass: emailConfig.password,
    },
  });
}

/**
 * 📧 Enviar email con factura PDF y XML adjuntos
 * @param {Object} datos - Datos del email
 * @param {string} datos.correo - Email del destinatario
 * @param {string} datos.nombreCliente - Nombre del cliente
 * @param {string} datos.claveAcceso - Clave de acceso de la factura
 * @param {string} datos.numeroFactura - Número de factura (001-001-000000001)
 * @param {Buffer} datos.pdfBuffer - Buffer del PDF
 * @param {Buffer} datos.xmlBuffer - Buffer del XML
 * @param {string} datos.estadoFactura - Estado de la factura
 * @return {Promise<boolean>} True si se envió correctamente
 */
async function enviarEmailFactura(datos) {
  try {
    const {correo, nombreCliente, claveAcceso, numeroFactura, pdfBuffer, xmlBuffer, estadoFactura} = datos;

    logger.info(`📧 [EMAIL] Preparando envío de factura a: ${correo}`);

    // Descargar logo desde Firebase Storage
    let logoBuffer;
    try {
      const bucket = admin.storage().bucket();
      const logoFile = bucket.file("logos/LogoRedondoLightLogin.png");
      [logoBuffer] = await logoFile.download();
      logger.info(`📧 [EMAIL] Logo descargado exitosamente`);
    } catch (error) {
      logger.warn(`⚠️ [EMAIL] No se pudo descargar logo:`, error.message);
    }

    // Crear mensaje de estado según el estado de la factura
    let mensajeEstado = "";
    let colorEstado = "#28a745"; // Verde por defecto

    switch (estadoFactura) {
      case "AUTORIZADA":
        mensajeEstado = "✅ <strong>AUTORIZADA</strong> - Su factura ha sido autorizada exitosamente por el SRI.";
        colorEstado = "#28a745";
        break;
      case "RECIBIDA":
        mensajeEstado = "🔄 <strong>RECIBIDA</strong> - Su factura ha sido recibida y está en proceso de autorización.";
        colorEstado = "#ffc107";
        break;
      case "ERROR_COMUNICACION":
        mensajeEstado = "⚠️ <strong>PENDIENTE</strong> - Hubo un problema temporal de comunicación. La factura será procesada pronto.";
        colorEstado = "#ff9800";
        break;
      default:
        mensajeEstado = "📄 <strong>GENERADA</strong> - Su factura ha sido generada exitosamente.";
        colorEstado = "#17a2b8";
    }

    // Configurar email
    const mailOptions = {
      from: `"${EMAIL_CONFIG.NOMBRE_REMITENTE}" <${EMAIL_CONFIG.EMAIL}>`,
      to: correo,
      subject: `Factura Electrónica ${numeroFactura} - ${EMPRESA_CONFIG.NOMBRE_COMERCIAL}`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 30px auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; }
            .logo { width: 120px; height: auto; margin-bottom: 15px; border-radius: 50%; }
            .header h1 { color: white; margin: 0; font-size: 24px; }
            .header p { color: rgba(255,255,255,0.9); margin: 5px 0 0; font-size: 14px; }
            .content { padding: 30px; }
            .estado-box { background: ${colorEstado}15; border-left: 4px solid ${colorEstado}; padding: 15px; margin: 20px 0; border-radius: 5px; }
            .estado-box p { margin: 0; color: #333; }
            .info-factura { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #dee2e6; }
            .info-row:last-child { border-bottom: none; }
            .info-label { font-weight: 600; color: #495057; }
            .info-value { color: #6c757d; }
            .adjuntos { background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 20px 0; }
            .adjuntos h3 { margin: 0 0 10px; color: #0056b3; font-size: 16px; }
            .adjunto-item { display: inline-block; margin: 5px 10px 5px 0; padding: 8px 15px; background: white; border-radius: 5px; border: 1px solid #0056b3; color: #0056b3; font-size: 14px; }
            .footer { background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #6c757d; }
            .clave-acceso { background: #f8f9fa; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 11px; word-break: break-all; color: #495057; margin-top: 10px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              ${logoBuffer ? '<img src="cid:logo" class="logo" alt="Logo">' : ""}
              <h1>Factura Electrónica</h1>
              <p>${EMPRESA_CONFIG.NOMBRE_COMERCIAL}</p>
            </div>

            <div class="content">
              <p>Estimado/a <strong>${nombreCliente}</strong>,</p>
              <p>Adjuntamos su factura electrónica generada por nuestro sistema.</p>

              <div class="estado-box">
                <p>${mensajeEstado}</p>
              </div>

              <div class="info-factura">
                <div class="info-row">
                  <span class="info-label">Número de Factura:</span>
                  <span class="info-value">${numeroFactura}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Empresa:</span>
                  <span class="info-value">${EMPRESA_CONFIG.RAZON_SOCIAL}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">RUC:</span>
                  <span class="info-value">${EMPRESA_CONFIG.RUC}</span>
                </div>
                <div class="info-row">
                  <span class="info-label">Estado:</span>
                  <span class="info-value" style="color: ${colorEstado}; font-weight: 600;">${estadoFactura}</span>
                </div>
              </div>

              <div class="adjuntos">
                <h3>📎 Archivos Adjuntos</h3>
                <span class="adjunto-item">📄 Factura.pdf</span>
                <span class="adjunto-item">📋 Factura.xml</span>
              </div>

              <p style="margin-top: 20px; font-size: 14px; color: #6c757d;">
                <strong>Clave de Acceso:</strong>
              </p>
              <div class="clave-acceso">${claveAcceso}</div>

              <p style="margin-top: 20px; font-size: 13px; color: #6c757d;">
                Gracias por su compra. Si tiene alguna duda, no dude en contactarnos.
              </p>
            </div>

            <div class="footer">
              <p><strong>${EMPRESA_CONFIG.RAZON_SOCIAL}</strong></p>
              <p>${EMPRESA_CONFIG.DIRECCION_MATRIZ}</p>
              <p>RUC: ${EMPRESA_CONFIG.RUC}</p>
              <p style="margin-top: 10px; font-size: 11px; color: #adb5bd;">
                Este es un email automático, por favor no responder.
              </p>
            </div>
          </div>
        </body>
        </html>
      `,
      attachments: [],
    };

    // Agregar logo como adjunto si existe
    if (logoBuffer) {
      mailOptions.attachments.push({
        filename: "logo.png",
        content: logoBuffer,
        cid: "logo",
      });
    }

    // Agregar PDF si existe
    if (pdfBuffer) {
      mailOptions.attachments.push({
        filename: `Factura_${numeroFactura}.pdf`,
        content: pdfBuffer,
        contentType: "application/pdf",
      });
      logger.info(`📧 [EMAIL] PDF adjunto agregado (${pdfBuffer.length} bytes)`);
    }

    // Agregar XML
    if (xmlBuffer) {
      mailOptions.attachments.push({
        filename: `Factura_${numeroFactura}.xml`,
        content: xmlBuffer,
        contentType: "application/xml",
      });
      logger.info(`📧 [EMAIL] XML adjunto agregado (${xmlBuffer.length} bytes)`);
    }

    // Enviar email
    const info = await transporter.sendMail(mailOptions);

    logger.info(`✅ [EMAIL] Email enviado exitosamente`, {
      messageId: info.messageId,
      to: correo,
      numeroFactura,
    });

    return true;
  } catch (error) {
    logger.error(`❌ [EMAIL] Error al enviar email:`, error);
    throw error;
  }
}

/**
 * 🧪 FUNCIÓN DE PRUEBA: Enviar email básico
 * Endpoint HTTP para probar el envío de emails
 */

exports.probarEmail = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    logger.info("🧪 [TEST EMAIL] Iniciando prueba de envío de email...");

    // Crear transporter
    const transporter = crearTransporterEmail();

    // Configurar email de prueba
    const mailOptions = {
      from: `"${emailConfig.fromName}" <${emailConfig.user}>`,
      to: emailConfig.user, // Enviar al mismo email de prueba
      subject: "🧪 Prueba de Email - Sistema de Facturación",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #007bff;">✅ Prueba de Email Exitosa</h2>
          <p>Si estás leyendo esto, significa que el sistema de envío de emails está <strong>funcionando correctamente</strong>.</p>

          <div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #007bff; margin: 20px 0;">
            <h3 style="margin-top: 0;">Configuración:</h3>
            <ul>
              <li><strong>Remitente:</strong> ${emailConfig.fromName}</li>
              <li><strong>Email:</strong> ${emailConfig.user}</li>
              <li><strong>Servicio:</strong> Gmail</li>
              <li><strong>Estado:</strong> ✅ Operativo</li>
            </ul>
          </div>

          <p style="color: #6c757d; font-size: 14px; margin-top: 30px;">
            Este es un email de prueba generado automáticamente por el sistema de facturación electrónica.
          </p>
        </div>
      `,
    };

    // Enviar email
    logger.info("📤 [TEST EMAIL] Enviando email de prueba...");
    const info = await transporter.sendMail(mailOptions);

    logger.info("✅ [TEST EMAIL] Email enviado exitosamente", {
      messageId: info.messageId,
      response: info.response,
    });

    res.status(200).send({
      success: true,
      mensaje: "✅ Email de prueba enviado exitosamente",
      detalles: {
        messageId: info.messageId,
        from: mailOptions.from,
        to: mailOptions.to,
        subject: mailOptions.subject,
      },
    });
  } catch (error) {
    logger.error("❌ [TEST EMAIL] Error al enviar email:", error);
    res.status(500).send({
      success: false,
      error: error.message,
      stack: error.stack,
    });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// 📄 GENERACIÓN DE PDF DE FACTURAS
// ═══════════════════════════════════════════════════════════════════════════

const PDFDocument = require("pdfkit");

/**
 * Genera PDF profesional según formato oficial del SRI de Ecuador
 * @param {Object} datosFactura - Datos completos de la factura
 * @return {Promise<Buffer>} Buffer del PDF generado
 */
async function generarPDFFactura(datosFactura) {
  return new Promise(async (resolve, reject) => {
    try {
      logger.info("📄 [PDF] Iniciando generación de PDF formato oficial SRI...");

      const doc = new PDFDocument({
        size: "A4",
        margins: {top: 40, bottom: 40, left: 40, right: 40},
      });

      const chunks = [];
      doc.on("data", (chunk) => chunks.push(chunk));
      doc.on("end", () => resolve(Buffer.concat(chunks)));
      doc.on("error", reject);

      let yPos = 40;
      const leftBoxX = 40;
      const leftBoxWidth = 255;
      const rightBoxX = 305;
      const rightBoxWidth = 250;

      // ═══════════════════════════════════════════════════════════════════
      // HEADER: LADO IZQUIERDO (LOGO + DATOS EMPRESA EN RECUADRO)
      // ═══════════════════════════════════════════════════════════════════

      // Logo de la empresa (centrado) - Logo más grande
      try {
        const bucket = admin.storage().bucket();
        const logoFile = bucket.file("logos/LogoRedondoLightLogin.png");
        const [logoBuffer] = await logoFile.download();

        // Logo centrado - Aumentado de 80px a 100px
        const logoWidth = 100;
        const logoX = leftBoxX + (leftBoxWidth - logoWidth) / 2;
        doc.image(logoBuffer, logoX, yPos, {width: logoWidth});

        yPos += 110; // Ajustado para el logo más grande
      } catch (error) {
        logger.warn("⚠️ [PDF] No se pudo cargar logo:", error.message);
        // Si falla el logo, mostrar nombre de empresa
        doc.font("Helvetica-Bold").fontSize(14).fillColor("#000000")
            .text(EMPRESA_CONFIG.RAZON_SOCIAL, leftBoxX, yPos, {
              width: leftBoxWidth,
              align: "center",
            });
        yPos += 30;
      }

      // Recuadro con información de la empresa - ALTURA IGUALADA A 200px
      doc.roundedRect(leftBoxX, yPos, leftBoxWidth, 90, 5)
          .stroke("#000000");

      let boxYPos = yPos + 8; // Reducido para ahorrar espacio

      doc.font("Helvetica-Bold").fontSize(9)
          .text(EMPRESA_CONFIG.RAZON_SOCIAL, leftBoxX + 10, boxYPos, {width: leftBoxWidth - 20});

      boxYPos += 16; // Reducido de 20 a 14

      doc.font("Helvetica-Bold").fontSize(8) // NEGRITA
          .text("Dirección Matriz:", leftBoxX + 10, boxYPos);

      boxYPos += 9; // Reducido de 10 a 9

      doc.font("Helvetica").fontSize(8) // Volver a normal para el contenido
          .text(EMPRESA_CONFIG.DIRECCION_MATRIZ, leftBoxX + 10, boxYPos, {
            width: leftBoxWidth - 20,
          });

      boxYPos += 20; // Reducido de 25 a 14

      // Título en negrilla
      doc.font("Helvetica-Bold").fontSize(8)
          .text("Dirección Sucursal: ", leftBoxX + 10, boxYPos, {continued: true});

      // Contenido en texto normal
      doc.font("Helvetica").fontSize(8)
          .text(EMPRESA_CONFIG.NOMBRE_COMERCIAL);

      boxYPos += 15; // Reducido de 20 a 12

      // Título en negrilla
      doc.font("Helvetica-Bold").fontSize(8)
          .text("OBLIGADO A LLEVAR CONTABILIDAD: ", leftBoxX + 10, boxYPos, {continued: true});

      // Contenido en texto normal
      doc.font("Helvetica").fontSize(8)
          .text(EMPRESA_CONFIG.OBLIGADO_CONTABILIDAD);

      // ═══════════════════════════════════════════════════════════════════
      // HEADER: LADO DERECHO (RUC, FACTURA, AUTORIZACIÓN EN RECUADRO)
      // ═══════════════════════════════════════════════════════════════════

      yPos = 40;

      // Recuadro derecho (bordes redondeados simulados)
      doc.roundedRect(rightBoxX, yPos, rightBoxWidth, 200, 5)
          .stroke("#000000");

      boxYPos = yPos + 10;

      // RUC
      doc.font("Helvetica-Bold").fontSize(11)
          .text(`R.U.C.: ${EMPRESA_CONFIG.RUC}`, rightBoxX + 10, boxYPos);

      boxYPos += 20;

      // FACTURA (centrado y grande)
      doc.font("Helvetica-Bold").fontSize(14)
          .text("FACTURA", rightBoxX + 10, boxYPos, {
            width: rightBoxWidth - 20,
            align: "center",
          });

      boxYPos += 20;

      // Número de factura
      doc.font("Helvetica").fontSize(10)
          .text(`No. ${datosFactura.establecimiento}-${datosFactura.puntoEmision}-${String(datosFactura.secuencial).padStart(9, "0")}`, rightBoxX + 10, boxYPos, {
            width: rightBoxWidth - 20,
            align: "center",
          });

      boxYPos += 20;

      // NÚMERO DE AUTORIZACIÓN
      doc.font("Helvetica-Bold").fontSize(8)
          .text("NÚMERO DE AUTORIZACIÓN", rightBoxX + 10, boxYPos);

      boxYPos += 10;

      doc.font("Helvetica").fontSize(7)
          .text(datosFactura.numeroAutorizacion || datosFactura.claveAcceso, rightBoxX + 10, boxYPos, {
            width: rightBoxWidth - 20,
          });

      boxYPos += 20;

      // FECHA Y HORA DE AUTORIZACIÓN
      doc.font("Helvetica-Bold").fontSize(8)
          .text("FECHA Y HORA DE AUTORIZACIÓN:", rightBoxX + 10, boxYPos);

      boxYPos += 10;

      doc.font("Helvetica").fontSize(8)
          .text(datosFactura.fechaAutorizacion || datosFactura.fechaEmision, rightBoxX + 10, boxYPos);

      boxYPos += 15;

      // AMBIENTE
      doc.fontSize(8)
          .text(`AMBIENTE: ${datosFactura.ambiente === "1" ? "PRUEBAS" : "PRODUCCION"}`, rightBoxX + 10, boxYPos);

      boxYPos += 12;

      // EMISIÓN
      doc.fontSize(8)
          .text("EMISIÓN: NORMAL", rightBoxX + 10, boxYPos);

      boxYPos += 15;

      // CLAVE DE ACCESO con código de barras
      doc.font("Helvetica-Bold").fontSize(8)
          .text("CLAVE DE ACCESO", rightBoxX + 10, boxYPos);

      boxYPos += 12;

      // Generar código de barras para la clave de acceso
      try {
        const barcodeBuffer = await bwipjs.toBuffer({
          bcid: "code128",
          text: datosFactura.claveAcceso,
          scale: 2,
          height: 6, // Reducido de 8 a 6 para evitar que se monte
          includetext: false,
        });

        // Agregar código de barras al PDF (centrado) - Altura reducida
        const barcodeWidth = 200;
        const barcodeX = rightBoxX + (rightBoxWidth - barcodeWidth) / 2;
        doc.image(barcodeBuffer, barcodeX, boxYPos, {width: barcodeWidth, height: 20}); // Reducido de 30 a 20

        boxYPos += 25; // Reducido de 35 a 25
      } catch (error) {
        logger.warn("⚠️ [PDF] No se pudo generar código de barras:", error.message);
      }

      // Clave de acceso en texto (debajo del código de barras)
      doc.font("Courier").fontSize(7)
          .text(datosFactura.claveAcceso, rightBoxX + 10, boxYPos, {
            width: rightBoxWidth - 20,
            align: "center",
            lineGap: 2,
          });

      // ═══════════════════════════════════════════════════════════════════
      // DATOS DEL CLIENTE (Recuadro completo)
      // ═══════════════════════════════════════════════════════════════════

      // Ajustar posición para dar más espacio después de los recuadros superiores (ahora de 200px)
      yPos = 260; // Mantener en 260 ya que ambos recuadros ahora terminan a la misma altura

      // Aumentar altura del recuadro para el nuevo layout
      doc.rect(40, yPos, 515, 60).stroke("#000000");

      boxYPos = yPos + 10;

      // FILA 1: Razón Social (izquierda) | Identificación (derecha)
      doc.font("Helvetica-Bold").fontSize(9)
          .text("Razón Social / Nombres y Apellidos:", 45, boxYPos);

      doc.font("Helvetica-Bold").fontSize(9)
          .text("Identificación:", 305, boxYPos);

      boxYPos += 12;

      doc.font("Helvetica").fontSize(9)
          .text(datosFactura.comprador.razonSocial, 45, boxYPos, {width: 250});

      doc.font("Helvetica").fontSize(9)
          .text(datosFactura.comprador.identificacion, 305, boxYPos);

      boxYPos += 15;

      // Línea divisoria
      doc.moveTo(45, boxYPos - 3).lineTo(550, boxYPos - 3).stroke("#eeeeee");

      // FILA 2: Dirección (izquierda) | Fecha de Emisión (derecha)
      doc.font("Helvetica-Bold").fontSize(9)
          .text("Dirección:", 45, boxYPos);

      doc.font("Helvetica-Bold").fontSize(9)
          .text("Fecha de Emisión:", 305, boxYPos);

      boxYPos += 12;

      doc.font("Helvetica").fontSize(9)
          .text(datosFactura.comprador.street || datosFactura.comprador.direccion || "N/A", 45, boxYPos, {width: 250});

      doc.font("Helvetica").fontSize(9)
          .text(datosFactura.fechaEmision, 305, boxYPos);

      yPos += 70; // Ajustado para el nuevo tamaño del recuadro

      // ═══════════════════════════════════════════════════════════════════
      // TABLA DE PRODUCTOS (con Cod. Auxiliar)
      // ═══════════════════════════════════════════════════════════════════

      const tableTop = yPos;
      // Columnas reajustadas para evitar que se monten sobre los bordes
      const colCodPrin = 40;
      const colCodAux = 105;
      const colCant = 170;
      const colDesc = 205;        // Reducido de 210 a 205
      const colPUnit = 385;       // Reducido de 395 a 385
      const colDescuento = 445;   // Reducido de 460 a 445
      const colTotal = 495;       // Reducido de 510 a 495 para que no se monte

      // Header de tabla con fondo gris
      doc.rect(40, tableTop, 515, 18).fillAndStroke("#eeeeee", "#000000");

      doc.font("Helvetica-Bold").fontSize(8).fillColor("#000000")
          .text("Cod. Principal", colCodPrin + 3, tableTop + 5, {width: 60})
          .text("Cod. Auxiliar", colCodAux + 3, tableTop + 5, {width: 60})
          .text("Cant", colCant + 3, tableTop + 5, {width: 32})
          .text("Descripción", colDesc + 3, tableTop + 5, {width: 175})
          .text("Precio Unitario", colPUnit + 3, tableTop + 5, {width: 57})
          .text("Descuento", colDescuento + 3, tableTop + 5, {width: 47})
          .text("Precio Total", colTotal + 3, tableTop + 5, {width: 55}); // Más espacio para el título

      yPos = tableTop + 18;

      // Filas de productos con altura dinámica
      doc.font("Helvetica").fontSize(8);

      datosFactura.items.forEach((item, index) => {
        // Calcular altura necesaria para todos los campos de texto
        const codigoPrincipal = item.codigo || item.codigoPrincipal || "001";
        const codigoAuxiliar = item.codigoAuxiliar || "001";

        const codigoPrincipalHeight = doc.heightOfString(codigoPrincipal, {width: 60});
        const codigoAuxiliarHeight = doc.heightOfString(codigoAuxiliar, {width: 60});
        const descripcionHeight = doc.heightOfString(item.descripcion, {width: 175});

        // Tomar la altura máxima entre todos los campos de texto
        const maxContentHeight = Math.max(codigoPrincipalHeight, codigoAuxiliarHeight, descripcionHeight);
        const rowHeight = Math.max(18, maxContentHeight + 10); // Mínimo 18, máximo según el contenido más alto

        // Bordes de la fila
        doc.rect(40, yPos, 515, rowHeight).stroke("#000000");

        // Líneas verticales internas
        doc.moveTo(colCodAux, yPos).lineTo(colCodAux, yPos + rowHeight).stroke("#000000");
        doc.moveTo(colCant, yPos).lineTo(colCant, yPos + rowHeight).stroke("#000000");
        doc.moveTo(colDesc, yPos).lineTo(colDesc, yPos + rowHeight).stroke("#000000");
        doc.moveTo(colPUnit, yPos).lineTo(colPUnit, yPos + rowHeight).stroke("#000000");
        doc.moveTo(colDescuento, yPos).lineTo(colDescuento, yPos + rowHeight).stroke("#000000");
        doc.moveTo(colTotal, yPos).lineTo(colTotal, yPos + rowHeight).stroke("#000000");

        // Contenido - centrado verticalmente con anchos ajustados
        const textYOffset = (rowHeight - 10) / 2;

        doc.text(item.codigo || item.codigoPrincipal || "001", colCodPrin + 3, yPos + textYOffset, {width: 60})
            .text(item.codigoAuxiliar || "001", colCodAux + 3, yPos + textYOffset, {width: 60})
            .text(item.cantidad.toFixed(2), colCant + 3, yPos + textYOffset, {width: 32, align: "right"})
            .text(item.descripcion, colDesc + 3, yPos + 5, {width: 175}) // Ajustado a 175
            .text(item.precioUnitario.toFixed(2), colPUnit + 3, yPos + textYOffset, {width: 57, align: "right"})
            .text(item.descuento.toFixed(2), colDescuento + 3, yPos + textYOffset, {width: 47, align: "right"})
            .text(item.subtotal.toFixed(2), colTotal + 3, yPos + textYOffset, {width: 55, align: "right"}); // Ajustado a 55

        yPos += rowHeight;
      });

      yPos += 15;

      // ═══════════════════════════════════════════════════════════════════
      // FOOTER: INFORMACIÓN ADICIONAL (izquierda) + TOTALES (derecha)
      // ═══════════════════════════════════════════════════════════════════

      const footerLeftX = 40;
      const footerLeftWidth = 290;
      const footerRightX = 340;
      const footerRightWidth = 215;

      // ─────────────────────────────────────────────────────────────────
      // LADO IZQUIERDO: Información Adicional en recuadro
      // ─────────────────────────────────────────────────────────────────

      const infoBoxHeight = 70;
      doc.rect(footerLeftX, yPos, footerLeftWidth, infoBoxHeight).stroke("#000000");

      // Header del recuadro
      doc.font("Helvetica-Bold").fontSize(9)
          .text("Información Adicional", footerLeftX + 5, yPos + 5);

      doc.moveTo(footerLeftX, yPos + 18)
          .lineTo(footerLeftX + footerLeftWidth, yPos + 18)
          .stroke("#cccccc");

      let infoYPos = yPos + 22;

      doc.font("Helvetica").fontSize(8)
          .text(`Teléfono: ${datosFactura.comprador.telefono}`, footerLeftX + 5, infoYPos, {width: footerLeftWidth - 10})
          .text(`Email: ${datosFactura.comprador.correo}`, footerLeftX + 5, infoYPos + 12, {width: footerLeftWidth - 10});

      // Tabla de Forma de Pago
      let tableFPY = yPos + infoBoxHeight + 10;

      doc.rect(footerLeftX, tableFPY, footerLeftWidth, 18).fillAndStroke("#eeeeee", "#000000");

      doc.font("Helvetica-Bold").fontSize(8).fillColor("#000000")
          .text("Forma de Pago", footerLeftX + 5, tableFPY + 5, {width: 200})
          .text("Valor", footerLeftX + 210, tableFPY + 5, {width: 75, align: "right"});

      tableFPY += 18;

      doc.rect(footerLeftX, tableFPY, footerLeftWidth, 18).stroke("#000000");

      // 🔧 Mapear código de forma de pago a descripción
      const formasPago = {
        "01": "SIN UTILIZACION DEL SISTEMA FINANCIERO",
        "15": "COMPENSACIÓN DE DEUDAS",
        "16": "TARJETA DE DÉBITO",
        "17": "DINERO ELECTRÓNICO",
        "18": "TARJETA PREPAGO",
        "19": "TARJETA DE CRÉDITO",
        "20": "OTROS CON UTILIZACION DEL SISTEMA FINANCIERO",
        "21": "ENDOSO DE TÍTULOS",
      };

      const codigoFormaPago = datosFactura.formaPago?.codigo || "01";
      const formaPagoTexto = formasPago[codigoFormaPago] || "OTROS CON UTILIZACION DEL SISTEMA FINANCIERO";

      doc.font("Helvetica").fontSize(8)
          .text(formaPagoTexto, footerLeftX + 5, tableFPY + 5, {width: 200})
          .text(datosFactura.totales.total.toFixed(2), footerLeftX + 210, tableFPY + 5, {width: 75, align: "right"});

      // ─────────────────────────────────────────────────────────────────
      // LADO DERECHO: Tabla de Totales Detallados
      // ─────────────────────────────────────────────────────────────────

      const totales = [
        {label: "SUBTOTAL 15%", value: datosFactura.totales.subtotalIva || datosFactura.totales.subtotal},
        {label: "SUBTOTAL 0%", value: 0.00},
        {label: "SUBTOTAL NO OBJETO DE IVA", value: 0.00},
        {label: "SUBTOTAL EXENTO DE IVA", value: 0.00},
        {label: "SUBTOTAL SIN IMPUESTOS", value: datosFactura.totales.subtotal},
        {label: "TOTAL DESCUENTO", value: datosFactura.totales.descuento || 0.00},
        {label: "ICE", value: 0.00},
        {label: "IVA 15%", value: datosFactura.totales.valorIva},
        {label: "PROPINA", value: 0.00},
        {label: "VALOR TOTAL", value: datosFactura.totales.total, bold: true},
      ];

      let totalsYPos = yPos;

      totales.forEach((item, index) => {
        const rowHeight = 16;

        // Borde de la fila
        doc.rect(footerRightX, totalsYPos, footerRightWidth, rowHeight).stroke("#000000");

        // Línea vertical entre label y value
        doc.moveTo(footerRightX + 145, totalsYPos)
            .lineTo(footerRightX + 145, totalsYPos + rowHeight)
            .stroke("#000000");

        // Contenido
        if (item.bold) {
          doc.font("Helvetica-Bold").fontSize(8);
        } else {
          doc.font("Helvetica").fontSize(8);
        }

        doc.text(item.label, footerRightX + 5, totalsYPos + 4, {width: 135})
            .text(item.value.toFixed(2), footerRightX + 150, totalsYPos + 4, {width: 60, align: "right"});

        totalsYPos += rowHeight;
      });

      doc.end();

      logger.info("✅ [PDF] PDF generado exitosamente (formato oficial SRI completo)");
    } catch (error) {
      logger.error("❌ [PDF] Error al generar PDF:", error);
      reject(error);
    }
  });
}

/**
 * 🧪 FUNCIÓN DE PRUEBA: Generar PDF de factura
 * Endpoint HTTP para probar la generación de PDF
 */
exports.probarGenerarPDF = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    logger.info("🧪 [TEST PDF] Iniciando prueba de generación de PDF...");

    // Datos de ejemplo de una factura
    const datosFacturaEjemplo = {
      claveAcceso: "0901202601100306653500110010010000000214719674916",
      fechaEmision: "09/01/2026",
      establecimiento: "001",
      puntoEmision: "001",
      secuencial: 21,
      ambiente: "1",
      fechaAutorizacion: "09/01/2026 12:58:01",
      comprador: {
        razonSocial: "Luis Fernando Palacios Ochoa",
        identificacion: "1003066535001",
        correo: "palaciosluisfer@gmail.com",
        telefono: "0986134645",
      },
      items: [
        {
          cantidad: 1,
          descripcion: "Pruebas del hogar",
          precioUnitario: 65.00,
          descuento: 0.00,
          subtotal: 65.00,
        },
      ],
      totales: {
        subtotal: 69.35,
        valorIva: 10.40,
        total: 79.75,
      },
      formaPago: "Tarjeta de Crédito",
    };

    // Generar PDF
    logger.info("📄 [TEST PDF] Generando PDF...");
    const pdfBuffer = await generarPDFFactura(datosFacturaEjemplo);

    logger.info("✅ [TEST PDF] PDF generado exitosamente");
    logger.info(`📊 [TEST PDF] Tamaño del PDF: ${pdfBuffer.length} bytes`);

    // Enviar PDF como respuesta para descarga
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", "attachment; filename=factura-prueba.pdf");
    res.setHeader("Content-Length", pdfBuffer.length);
    res.send(pdfBuffer);
  } catch (error) {
    logger.error("❌ [TEST PDF] Error al generar PDF:", error);
    res.status(500).send({
      success: false,
      error: error.message,
      stack: error.stack,
    });
  }
});


