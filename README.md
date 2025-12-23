TubosLab
Aplicación móvil para optimizar la toma de muestras sanguíneas en hospitales
TubosLab es un prototipo funcional (MPV) de una aplicación móvil desarrollada para apoyar al personal clínico en la correcta selección y cantidad de tubos necesarios para la toma de muestras sanguíneas, reduciendo errores, desperdicio de insumos y reprocesos en el laboratorio clínico.
El proyecto se basa en una problemática real detectada en el Hospital Clínico Magallanes (Chile), donde se identificó una acumulación aproximada de 2.500 tubos sobrantes en un semestre, producto de errores en la selección de tubos y duplicación de muestras.
Objetivo del Proyecto
Desarrollar un producto mínimo viable de una aplicación móvil que:
•	Permita consultar exámenes de laboratorio
•	Indique qué tubos usar y cuántos
•	Valide compatibilidades
•	Evite duplicaciones innecesarias de muestras
Funcionalidades Implementadas:
1.	Consulta de Exámenes
•	Búsqueda dinámica por nombre
•	Normalización de texto para mejorar resultados
•	Filtro por área del laboratorio (Hematología, Bioquímica, etc.)
2.	Agrupación Inteligente de Tubos
•	Carrito de exámenes múltiples
•	Algoritmo que agrupa exámenes compatibles
•	Optimización de la cantidad total de tubos requeridos
3.	Información del Examen
•	Tipo de tubo (con código de color)
•	Volumen de sangre requerido
•	Anticoagulante
•	Área del laboratorio
4.	Manual Digital
•	Acceso a manual de toma de muestras en formato PDF
•	Visualización integrada en la aplicación
5.	Historial y Estadísticas
•	Historial de consultas del usuario
•	Registro de consultas para estadísticas administrativas
6.	Gestión de Usuarios y Roles
•	Usuario anónimo (consulta básica)
•	Personal clínico autenticado (historial)
•	Administrador (CRUD completo)
Tipos de Usuarios
Rol	Funcionalidades
Usuario Anónimo	Consulta básica de exámenes
Personal Clínico	Autenticación, historial, consultas avanzadas
Administrador	CRUD de exámenes, estadísticas

Arquitectura del Sistema:
Frontend
•	Flutter 3.35.1
•	Dart 3.9.0
•	Arquitectura en capas + enfoque MVVM
•	Gestión de estado con ValueNotifier y Streams
Backend (Firebase)
•	Firebase Authentication
•	Cloud Firestore (NoSQL)
•	Reglas de seguridad y control de acceso por roles (RBAC)
Servicios Implementados
•	AuthService – Autenticación y roles
•	FirestoreService – CRUD y búsquedas
•	CarritoService – Lógica de agrupación de tubos
•	HistoryService – Historial local
•	CacheService – Persistencia offline
•	AppConfigService – Configuración dinámica

Modelo de Datos (Firestore)
Colecciones principales:
•	examenes: información de exámenes y requisitos de toma de muestra
•	users: perfiles y roles de usuario
•	app_config: configuraciones globales (manual digital)
•	exam_queries: registro de consultas para estadísticas administrativas
Pruebas Realizadas:
Tipo de Prueba	Estado
Conexión Firestore	Completo
Búsqueda dinámica	Completo
Filtrado por área	Completo
Carrito y agrupación	Completo
CRUD administrador	Completo
Autenticación	Completo
Historial local	Completo
Manual PDF	Parcial

Cumplimiento de Requerimientos
•	17 de 21 requerimientos funcionales implementados
•	100% de los requerimientos Must Have cumplidos
•	Prototipo funcional dentro del alcance definido

Gestión del Proyecto
•	Metodología ágil (Scrum)
•	Planificación por sprints
•	Control de tareas en Notion
•	Control de versiones con Git y GitHub
•	Uso de ramas (main, feature/base, feature/admin-statistic)
•	Commits documentados

Instalación y Ejecución
Requisitos
•	Flutter SDK ≥ 3.35
•	Dart ≥ 3.9
•	Android Studio o emulador Android
•	Cuenta Firebase configurada
Pasos
git clone https://github.com/Nubedev23/TubosLab.git
cd TubosLab
flutter pub get
flutter run
Nota: Se requiere configurar Firebase (google-services.json) para ejecución completa.

Estado del Proyecto
•	Proyecto académico cerrado.
•	Prototipo funcional (MPV).
•	Preparado para futuras fases de implementación institucional
Trabajo Futuro
•	Ampliar catálogo de exámenes (incluyendo derivados)
•	Implementar versión web para estaciones de enfermería
•	Incorporar disponibilidad por horario (rutina / urgencia)
•	Validación formal en entorno productivo
MBQ
Ingeniería en Computación
Proyecto académico - Chile, 2025
