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
      direccion: orderData.address?.street || "N/A",
      telefono: userData?.PhoneNumber || orderData.address?.phoneNumber || "",
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

      return {
        codigo: item.productId || "PROD",
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

  await admin.firestore().collection("Facturas").doc(claveAcceso).set(facturaData);

  await guardarLogFacturacion('SUCCESS', 'PASO 9 COMPLETADO: Factura guardada en Firestore', {
    coleccion: 'Facturas',
    documentId: claveAcceso,
    estadoGuardado: estadoFactura,
  }, orderId);
  logger.info(`✅ [generarFactura] Factura guardada en Firestore con estado: ${estadoFactura}`);

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
