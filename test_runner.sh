#!/bin/bash

# Script para ejecutar todos los tests de TubosLab
# Basado en el Plan de Pruebas v1.0 - Diciembre 2025

echo "🧪 Iniciando Suite de Pruebas TubosLab"
echo "========================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contador de resultados
TESTS_PASSED=0
TESTS_FAILED=0

# Función para ejecutar tests y capturar resultado
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo "📋 Ejecutando: $test_name"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASÓ${NC}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FALLÓ${NC}: $test_name"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# ============================================
# FASE 1: PRUEBAS UNITARIAS (Sprint 3-4)
# ============================================
echo "🔬 FASE 1: Pruebas Unitarias"
echo "----------------------------"

run_test "Servicio Firestore" "flutter test test/services/firestore_service_test.dart"
run_test "Servicio Carrito" "flutter test test/services/carrito_service_test.dart"
run_test "Servicio Auth" "flutter test test/services/auth_service_test.dart"
run_test "Servicio Cache" "flutter test test/services/cache_service_test.dart"

# ============================================
# FASE 2: PRUEBAS FUNCIONALES (Sprint 4-5)
# ============================================
echo ""
echo "⚙️ FASE 2: Pruebas Funcionales"
echo "------------------------------"

run_test "CP-001: Registro de Exámenes" "flutter test test/functional/cp001_registro_examenes_test.dart"
run_test "CP-002: Consulta de Examen" "flutter test test/functional/cp002_consulta_examen_test.dart"
run_test "CP-003: Visualización de Detalles" "flutter test test/functional/cp003_detalle_examen_test.dart"
run_test "CP-008: Control de Acceso" "flutter test test/functional/cp008_control_acceso_test.dart"

# ============================================
# FASE 3: PRUEBAS DE WIDGETS
# ============================================
echo ""
echo "🎨 FASE 3: Pruebas de Widgets"
echo "-----------------------------"

run_test "Pantalla Bienvenida" "flutter test test/widgets/pantalla_bienvenida_test.dart"
run_test "Pantalla Búsqueda" "flutter test test/widgets/pantalla_busqueda_test.dart"
run_test "Pantalla Carrito" "flutter test test/widgets/pantalla_carrito_test.dart"

# ============================================
# FASE 4: PRUEBAS DE INTEGRACIÓN (Sprint 5)
# ============================================
echo ""
echo "🔗 FASE 4: Pruebas de Integración"
echo "---------------------------------"

run_test "E2E: Flujo de Búsqueda" "flutter test integration_test/app_test.dart --dart-define=TESTING=true"

# ============================================
# PRUEBAS DE SEGURIDAD
# ============================================
echo ""
echo "🔒 Pruebas de Seguridad"
echo "----------------------"

run_test "CS-001: Autenticación Obligatoria" "flutter test test/security/cs001_auth_required_test.dart"
run_test "CS-002: Reglas Firestore" "flutter test test/security/cs002_firestore_rules_test.dart"

# ============================================
# REPORTE FINAL
# ============================================
echo ""
echo "========================================"
echo "📊 REPORTE FINAL DE PRUEBAS"
echo "========================================"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
PASS_RATE=0

if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED / $TOTAL_TESTS) * 100}")
fi

echo "Total de Pruebas: $TOTAL_TESTS"
echo -e "${GREEN}✓ Pasaron: $TESTS_PASSED${NC}"
echo -e "${RED}✗ Fallaron: $TESTS_FAILED${NC}"
echo "Tasa de Éxito: $PASS_RATE%"
echo ""

# Criterio de Aceptación: 100% de "Must Have"
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON!${NC}"
    echo "✅ Criterio de Aceptación: CUMPLIDO"
    exit 0
else
    echo -e "${RED}❌ ALGUNOS TESTS FALLARON${NC}"
    echo "⚠️  Criterio de Aceptación: NO CUMPLIDO"
    echo "Por favor revisa los tests fallidos antes de continuar."
    exit 1
fi