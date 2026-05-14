# **Documentación técnica – TubosLab**
> Versión: 2.0
> Fecha: Mayo 2026
> Autor: MBQ
---
## Índice
1.	*Visión General del Sistema*
2.	*Arquitectura de la Aplicación*
3.	*Capa de Servicios (Services)*
4.	*Capa de Modelos (Models)*
5.	*Capa de Presentación (Pantallas)*
6.	*Flujos de Navegación*
7.	*Gestión de Estado*
8.	*Base de Datos (Firebase Firestore)*
9.	*Seguridad y Autenticación*
---
##**1. Visión General del Sistema**
**1.1 ¿Qué es TubosLab?**
TubosLab es una aplicación móvil que digitaliza y optimiza el proceso de consulta de requisitos para la toma de muestras de laboratorio clínico. Resuelve el problema de "¿Qué tubo necesito para este examen?" de forma rápida y precisa.
**1.2 Problema que Resuelve**
En un laboratorio clínico:
* Existen diferentes exámenes con diferentes recipientes
* El examen puede tener diferente manejo si se realiza en el lugar, si es de urgencias o es derivado.
* El transporte de la muestra importa según qué examen se esté realizando.
* Existen tipos de tubos diferentes con anticoagulantes específicos
* Un error en la toma de muestra puede invalidar un resultado de examen
* El personal necesita consultar manuales físicos constantemente

TubosLab centraliza esta información y la hace accesible en segundos desde cualquier dispositivo (celulares, Tablet o pc).
**1.3 Tipos de Usuarios**
USUARIOS DE TUBOSLAB          
1. ANÓNIMOS (Público General)         
→ Búsqueda de exámenes            
→ Ver detalles                  
2. PERSONAL CLÍNICO (Autenticados)    
→ Todo lo de anónimos 
→ Carrito de exámenes         
→ Resumen de tubos             
→ Historial personal                
→ Manual de procedimientos         
3. ADMINISTRADORES                    
→ Todo lo anterior               
→ CRUD de exámenes                 
→ Configurar manual PDF             
→ Panel de estadísticas             
---
**2. Arquitectura de la Aplicación**
**2.1 Patrón de Arquitectura: MVVM**
**2.2 Principios de Diseño Aplicados**
Singleton Pattern
¿Por qué?
* Garantiza una sola instancia del servicio en toda la app
* Evita crear múltiples conexiones a Firebase
* Facilita el acceso desde cualquier parte del código
* UI solo se preocupa de mostrar datos
* Servicios manejan toda la lógica de negocio
* Modelos solo definen la estructura de datos
---
**3. Capa de Servicios (Services)**
**3.1 AuthService (auth_service.dart)**
Propósito: Gestionar toda la autenticación de usuarios.
Responsabilidades:
1.	Login con email/password
2.	Login anónimo
3.	Logout
4.	Gestión de roles (admin/user)
5.	Verificar estado de autenticación
**3.2 FirestoreService (firestore_service.dart)**
Propósito: Gestionar TODAS las operaciones con la base de datos Firestore.
Responsabilidades:
1.	CRUD completo de exámenes
2.	Búsqueda y filtrado
3.	Normalización de texto
4.	Caché local
5.	Gestión de roles
**3.3 CarritoService (carrito_service.dart)**
Propósito: Gestionar el carrito de exámenes y generar el resumen de tubos necesarios.
**Responsabilidades:**
1.	Agregar/remover exámenes
2.	Verificar si un examen está en el carrito
3.	Limpiar carrito
4.	Agrupar exámenes por tubo (clave del negocio)
La Lógica del Negocio:
PROBLEMA:
Usuario solicita: Perfil hepático + Hemograma + Perfil lipídico
PREGUNTA: ¿Cuántos tubos necesita?
RESPUESTA DEL CARRITO SERVICE:
- Tubo Verde (Heparina de litio): x1 → para perfil hepático y perfil lipídico
- Tubo Lila (EDTA): x1 → para Hemograma
TOTAL: 2 tubos (NO 3)
**3.4 CacheService (cache_service.dart)**
Propósito: Guardar datos localmente para funcionamiento offline.
Responsabilidades:
1.	Guardar exámenes en caché
2.	Guardar búsquedas recientes
3.	Guardar historial de solicitudes
4.	Verificar expiración de caché
Tecnología: SharedPreferences
**3.5 HistoryService (history_service.dart)**
Propósito: Gestionar historial de consultas del usuario.
Responsabilidades:
1.	Guardar cada consulta de examen
2.	Obtener historial del usuario actual
3.	Generar estadísticas personales
4.	Limpiar historial
**3.6 StatsService (stats_service.dart)**
Propósito: Registrar métricas globales para el panel de administrador.
Responsabilidades:
1.	Registrar cada consulta en Firestore
2.	Actualizar última actividad del usuario
3.	Proveer datos para el panel de estadísticas
**3.7 AnalyticsService (analytics_service.dart)**
4.	Propósito: Integración con Firebase Analytics para métricas de uso.
**Analytics vs Stats**
A.	Firebase Analytics:
B.	Eventos automáticos (aperturas de app, crashes)
C.	Eventos personalizados
D.	Dashboards en Firebase Console
E.	Métricas agregadas (no datos crudos)

F.	StatsService (Firestore):
G.	Datos crudos de cada consulta
H.	Accesible programáticamente
I.	Panel personalizado en la app
J.	Control total sobre los datos
---
**3.8 AppConfigService (app_config_service.dart)**
Propósito: Gestionar configuraciones globales de la app.
Responsabilidades:
1.	URL del manual PDF
2.	Otras configuraciones futuras
---
**4. Capa de Modelos (Models)**
**4.1 Examen (examen.dart)**
Propósito: Representar un examen de laboratorio.
¿Por qué nombre_normalizado?
- Firestore Query Limitaciones:
- No soporta búsqueda por "contiene"
- No soporta case-insensitive nativo
- No soporta búsqueda sin tildes
- Solución: Campo normalizado
Original: "Hemograma Completo"
Normalizado: "hemograma completo"
- Query eficiente:
WHERE nombre_normalizado >= "hemo"
AND nombre_normalizado < "hemo\uf8ff"
---
**4.2 QueryHistory (query_history.dart)**
Propósito: Representar una consulta en el historial personal.

**5. Capa de Presentación (Pantallas)**
**5.1 PantallaBienvenida (pantalla_bienvenida.dart)**
Propósito: Punto de entrada de la aplicación.
Funcionalidades:
1.	Muestra 3 opciones de acceso
2.	Se adapta según el rol del usuario
3.	Navegación a diferentes flujos
Adaptación por Rol:
Usuario NO logueado:
- Iniciar Búsqueda      
- Personal Clínico       
- Soy Administrador    ← Lleva a login
Usuario con rol 'admin':
-	Iniciar Búsqueda   
-	Personal Clínico  
-	Panel Admin             ← Acceso directo
---
**5.2 PantallaPrincipal (pantalla_principal.dart)**
Propósito: Contenedor con navegación por tabs (BottomNavigationBar).
Badge del Carrito:
- ValueListenableBuilder escucha cambios en el carrito
    - Se reconstruye automáticamente cuando:
    - Se agrega un examen
    - Se remueve un examen
    - Se limpia el carrito
**5.3 PantallaBusqueda (pantalla_busqueda.dart)**
Propósito: Búsqueda y filtrado de exámenes.
Flujo Completo de Búsqueda:
>Usuario escribe "hemo"
       >    ↓
>_onSearchChanged() detecta cambio
         >↓
>setState() actualiza _currentQuery = "hemo"
         >↓
>StreamBuilder detecta cambio en query
        > ↓
>Llama: firestoreService.streamExamenesBusqueda("hemo", null)
        > ↓
>Firestore ejecuta query normalizada
      >   ↓
>Stream emite List<Examen> con resultados
      >   ↓
>builder() recibe snapshot con datos
>         ↓
>ListView.builder reconstruye lista
 >        ↓
>Usuario ve resultados filtrados en tiempo real
---
**5.4 PantallaDetalleExamen (pantalla_detalle_examen.dart)**
Propósito: Mostrar información completa de un examen.

**5.5 PantallaCarrito (pantalla_carrito.dart)**
Propósito: Mostrar exámenes seleccionados.

**5.6 PantallaResumenExamen (pantalla_resumen_examen.dart)**
Propósito: Mostrar resumen consolidado de tubos necesarios.
Visualización del Resumen:
Muestras requeridas              
2 recipientes necesarios         
Química clínica - Verde               
Anticoagulante: Heparina de litio         
2 exámenes en este tubo       x 1   
• Perfil hepático                     
• Perfin lipídico             
Hematología - Lila                  
Anticoagulante: EDTA K2            
1 examen en este tubo         x 1   
• Hemograma Completo                
[✓ Confirmar y Finalizar]         
---
**5.7 PantallaManual (pantalla_manual.dart)**
Propósito: Acceso al manual de procedimientos en PDF.

**5.8 PantallaEstadisticas (pantalla_estadisticas.dart)**
Propósito: Mostrar estadísticas personales del usuario.

**5.9 PantallaAdmin (pantalla_admin.dart)**
Propósito: Panel de administración CRUD.

**6. Flujos de Navegación**
**6.1 Flujo de Usuario Anónimo**
PantallaBienvenida
      ↓ (Tap "Iniciar Búsqueda")
AuthService.signInAnonymously()
      ↓
PantallaPrincipal (Tab: Búsqueda)
      ↓ (Buscar examen)
StreamBuilder actualiza en tiempo real
      ↓ (Tap en examen)
PantallaDetalleExamen
      ↓ (Back)
PantallaPrincipal
      ↓ (Tap tab "Manual")
_buildLoginRequired() ← Bloqueado
**6.2 Flujo de Personal Clínico**
PantallaBienvenida
      ↓ (Tap "Personal Clínico")
PantallaLoginClinico
      ↓ (Ingresar credenciales)
AuthService.signIn(email, password)
      ↓
Firebase Auth valida
      ↓
_listenToUserRole() lee Firestore
      ↓
userRoleStream emite 'user'
      ↓
PantallaPrincipal
      ↓ (Buscar y agregar al carrito)
CarritoService.agregarExamen()
      ↓
Badge se actualiza automáticamente
      ↓ (Tap ícono carrito)
PantallaCarrito
      ↓ (Procesar Solicitud)
PantallaResumenExamen
      ↓
Muestra tubos agrupados
      ↓ (Confirmar)
Guarda en historial local
Limpia carrito
Navega a inicio
**6.3 Flujo de Administrador**
PantallaBienvenida
      ↓ (Tap "Soy Administrador")
PantallaLoginAdmin
      ↓ (Credenciales admin)
AuthService.signIn(email, password)
      ↓
Firebase Auth valida
      ↓
_listenToUserRole() lee Firestore
      ↓
Firestore retorna {role: 'admin'}
      ↓
userRoleStream emite 'admin'
      ↓
PantallaAdmin
      ↓ (Crear Nuevo Examen)
PantallaGestionExamen (sin ID)
      ↓ (Llenar formulario)
FirestoreService.saveExamen()
      ↓
Firestore crea documento
      ↓
Stream actualiza lista automáticamente
      ↓ (Ver estadísticas)
PantallaEstadisticasAdmin
      ↓
Muestra métricas globales

**7. Gestión de Estado**
**7.1 Singleton + Streams (AuthService)**
- Emisor de eventos reactivo
**7.2 ValueNotifier (CarritoService)**
- Estado observable
**7.3 StreamBuilder (Firestore)**
- Stream de datos en tiempo real
Comparación de Enfoques:
SINGLETON + STREAM (AuthService)           
Uso: Estado global que rara vez cambia     
Ejemplo: Rol del usuario                   
Ventaja: Múltiples listeners, eventos      
VALUENOTIFIER (CarritoService)              
Uso: Estado local que cambia frecuentemente 
Ejemplo: Lista del carrito            
Ventaja: Lightweight, fácil de usar         

STREAMBUILDER (Firestore)                  
Uso: Datos en tiempo real desde BD          
Ejemplo: Lista de exámenes                  
Ventaja: Sincronización automática          
---
**8. Base de Datos (Firebase Firestore)**
**8.1 Estructura de Colecciones**
firestore/
│
├── examenes/
│   ├── {examenId}/
│   │   ├── nombre: "Hemograma Completo"
│   │   ├── nombre_normalizado: "hemograma completo"
│   │   ├── descripcion: "..."
│   │   ├── tubo: "Lila"
│   │   ├── anticoagulante: "EDTA K2"
│   │   ├── volumen_ml: 3.5
│   │   ├── area: "Hematología"
│   │   ├── ultima_actualizacion: timestamp
│   │   └── updated_by: "admin_uid"
│
├── users/
│   ├── {userId}/
│   │   ├── role: "admin" | "user"
│   │   ├── last_active: timestamp
│   │   └── last_updated: timestamp
│
├── consultas_examenes/
│   ├── {consultaId}/
│   │   ├── examen_id: "glicemia"
│   │   ├── examen_nombre: "Glicemia"
│   │   ├── tubo: "Gris"
│   │   ├── area: "Bioquímica"
│   │   ├── user_id: "user123"
│   │   └── timestamp: timestamp
│
└── app_config/
    └── manual/
        ├── pdf_url: "https://..."
        └── last_updated: timestamp
**8.2 Índices Necesarios**
/Firestore Console → Indexes → Create Index
Collection: examenes
Fields:
  - nombre_normalizado (Ascending)
  - area (Ascending)
Query scope: Collection
---
**9. Seguridad y Autenticación**
**9.1 Reglas de Seguridad Firestore**
rules_version = '2';
    - Exámenes: Leer todos, escribir solo admin
    -Usuarios: Leer propio o ser admin    
  - Consultas: Crear todos, leer solo admin
  -Config: Leer todos, escribir solo admin

