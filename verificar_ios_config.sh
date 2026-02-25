#!/bin/bash

# Script de verificación de configuración iOS
# Ejecutar desde la raíz del proyecto: ./verificar_ios_config.sh

echo "🔍 VERIFICANDO CONFIGURACIÓN iOS PARA MEN'S LOCKER CLOTHING EC."
echo "================================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar si estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: No estás en el directorio raíz del proyecto Flutter${NC}"
    echo "   Por favor ejecuta este script desde: /ruta/al/proyecto/tienda_ropa/"
    exit 1
fi

echo -e "${GREEN}✅ Directorio del proyecto correcto${NC}"
echo ""

# Verificar estructura iOS
echo "📁 Verificando estructura de carpetas iOS..."
if [ -d "ios" ]; then
    echo -e "${GREEN}✅ Carpeta ios/ existe${NC}"
else
    echo -e "${RED}❌ Carpeta ios/ NO existe${NC}"
    exit 1
fi

if [ -d "ios/Runner.xcodeproj" ]; then
    echo -e "${GREEN}✅ Runner.xcodeproj existe${NC}"
else
    echo -e "${RED}❌ Runner.xcodeproj NO existe${NC}"
fi

if [ -d "ios/Runner.xcworkspace" ]; then
    echo -e "${GREEN}✅ Runner.xcworkspace existe${NC}"
else
    echo -e "${YELLOW}⚠️  Runner.xcworkspace NO existe (se generará al compilar)${NC}"
fi

echo ""

# Verificar Info.plist
echo "📄 Verificando Info.plist..."
if [ -f "ios/Runner/Info.plist" ]; then
    echo -e "${GREEN}✅ Info.plist existe${NC}"

    # Verificar permisos
    if grep -q "NSCameraUsageDescription" "ios/Runner/Info.plist"; then
        echo -e "${GREEN}✅ Permiso de cámara configurado${NC}"
    else
        echo -e "${RED}❌ Permiso de cámara NO configurado${NC}"
    fi

    if grep -q "NSPhotoLibraryUsageDescription" "ios/Runner/Info.plist"; then
        echo -e "${GREEN}✅ Permiso de fotos configurado${NC}"
    else
        echo -e "${RED}❌ Permiso de fotos NO configurado${NC}"
    fi

    # Verificar nombre de la app
    if grep -q "Men's Locker Clothing Ec." "ios/Runner/Info.plist"; then
        echo -e "${GREEN}✅ Nombre de la app configurado correctamente${NC}"
    else
        echo -e "${YELLOW}⚠️  Nombre de la app no coincide${NC}"
    fi
else
    echo -e "${RED}❌ Info.plist NO existe${NC}"
fi

echo ""

# Verificar Bundle Identifier
echo "🆔 Verificando Bundle Identifier..."
if grep -q "ec.menslockerclothing.app" "ios/Runner.xcodeproj/project.pbxproj"; then
    echo -e "${GREEN}✅ Bundle ID configurado: ec.menslockerclothing.app${NC}"
else
    echo -e "${RED}❌ Bundle ID NO configurado correctamente${NC}"
fi

echo ""

# Verificar Firebase
echo "🔥 Verificando configuración Firebase..."
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ GoogleService-Info.plist existe${NC}"
else
    echo -e "${RED}❌ GoogleService-Info.plist NO existe${NC}"
    echo -e "${YELLOW}   ⚠️  IMPORTANTE: Debes descargar este archivo desde Firebase Console${NC}"
    echo -e "${YELLOW}   📄 Consulta: FIREBASE_IOS_CONFIG.md${NC}"
fi

echo ""

# Verificar Podfile
echo "📦 Verificando Podfile..."
if [ -f "ios/Podfile" ]; then
    echo -e "${GREEN}✅ Podfile existe${NC}"
else
    echo -e "${RED}❌ Podfile NO existe${NC}"
fi

echo ""

# Verificar íconos
echo "🎨 Verificando íconos de la app..."
if [ -d "ios/Runner/Assets.xcassets/AppIcon.appiconset" ]; then
    echo -e "${GREEN}✅ Carpeta de íconos existe${NC}"

    icon_count=$(ls -1 ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png 2>/dev/null | wc -l)
    if [ $icon_count -gt 0 ]; then
        echo -e "${GREEN}✅ Íconos generados ($icon_count archivos)${NC}"
    else
        echo -e "${YELLOW}⚠️  No se encontraron archivos de íconos${NC}"
    fi
else
    echo -e "${RED}❌ Carpeta de íconos NO existe${NC}"
fi

echo ""

# Verificar versión mínima de iOS
echo "📱 Verificando versión mínima de iOS..."
if grep -q "IPHONEOS_DEPLOYMENT_TARGET = 12.0" "ios/Runner.xcodeproj/project.pbxproj"; then
    echo -e "${GREEN}✅ Versión mínima: iOS 12.0${NC}"
else
    echo -e "${YELLOW}⚠️  Versión mínima de iOS no está clara${NC}"
fi

echo ""

# Resumen
echo "================================================================"
echo "📊 RESUMEN DE VERIFICACIÓN"
echo "================================================================"
echo ""

# Contar verificaciones exitosas
successful=0
warnings=0
errors=0

# Aquí podrías hacer un conteo más detallado si quisieras

echo "📄 DOCUMENTOS DE AYUDA DISPONIBLES:"
echo "   - INSTRUCCIONES_INSTALACION_IOS.md"
echo "   - FIREBASE_IOS_CONFIG.md"
echo "   - CHECKLIST_INSTALACION_IOS.md"
echo ""

echo "🎯 PRÓXIMOS PASOS:"
echo "   1. Si falta GoogleService-Info.plist, descárgalo de Firebase"
echo "   2. Lleva el proyecto a la Mac"
echo "   3. Sigue INSTRUCCIONES_INSTALACION_IOS.md"
echo "   4. Usa CHECKLIST_INSTALACION_IOS.md como guía"
echo ""

echo -e "${GREEN}✅ Verificación completada${NC}"
echo ""

