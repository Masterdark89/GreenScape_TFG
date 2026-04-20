# TFG

Aplicacion movil desarrollada con Flutter para gestionar funcionalidades orientadas a cliente y trabajador, incluyendo chat, inventario, pago, rutas y perfiles.

## 1. Manual de Instalacion

### 1.1 Objetivo
Este manual explica como desplegar y reproducir la solucion GreenScape en un entorno local de desarrollo.

### 1.2 Requisitos previos

- Sistema operativo: Windows 10/11.
- Flutter SDK instalado y configurado en PATH.
- Dart SDK compatible (incluido con Flutter).
- Editor recomendado: Visual Studio Code o Android Studio.
- Navegador Google Chrome.
- Git instalado (para clonar y versionar).
- Conexion a Internet para descargar dependencias.

### 1.3 Dependencias tecnicas del proyecto

- Flutter
- firebase_core
- cloud_firestore
- flutter_local_notifications
- shared_preferences
- google_fonts
- file_picker

### 1.4 Configuracion inicial del entorno

1. Verificar instalacion de Flutter:

```bash
flutter doctor
```

2. Verificar dispositivos disponibles:

```bash
flutter devices
```

3. Clonar el repositorio:

```bash
git clone https://github.com/Masterdark89/GreenScape_TFG.git
cd GreenScape_TFG
```

Nota: usa una carpeta de trabajo normal del usuario (por ejemplo, Escritorio o Documentos) y evita rutas de cache del sistema.

### 1.5 Configuracion de Firebase

El proyecto ya incluye configuracion de Firebase mediante FlutterFire, con:

- Archivo de opciones: lib/firebase_options.dart
- Reglas de Firestore: firestore.rules
- Indices de Firestore: firestore.indexes.json

Proyecto Firebase configurado: greenscape-757a6.

### 1.6 Instalacion de paquetes

Desde la raiz del proyecto:

```bash
flutter pub get
```

### 1.7 Ejecucion de la aplicacion

- En Chrome (web):

```bash
flutter run -d chrome
```

- En Windows (desktop):

```bash
flutter run -d windows
```

### 1.8 Compilacion para distribucion (opcional)

- Build web:

```bash
flutter build web
```

- Build APK Android:

```bash
flutter build apk --release
```

### 1.9 Problemas comunes y solucion

- Error de dependencias: ejecutar `flutter clean` y luego `flutter pub get`.
- Dispositivo no detectado: revisar `flutter devices` y relanzar emulador/dispositivo.
- Error de Firebase: verificar que firebase_options.dart y reglas/indexes esten presentes.
- Error de entorno Flutter: corregir alertas reportadas por `flutter doctor`.

---


## 2. Manual de Usuario

### 2.1 Descripcion funcional
GreenScape es una aplicacion para gestion operativa entre perfiles de cliente y trabajador, con modulos como:

- Inventario
- Reservas/rutas
- Chat
- Perfil

### 2.2 Acceso y navegacion general

1. Inicia la aplicacion.
2. Accede al perfil segun el flujo definido en la app.
3. Usa la barra de navegacion inferior para moverte entre modulos.

### 2.3 Uso del modulo de Inventario (trabajador)

1. Abrir la pantalla Inventario.
2. Consultar articulos con filtros por:
   - Busqueda
   - Categoria
   - Estado de stock
   - Estado de alquiler
3. Editar un articulo:
   - Pulsar boton Editar en la tarjeta del articulo.
   - Modificar campos necesarios.
   - Guardar cambios.
4. Eliminar un articulo:
   - Pulsar boton Eliminar (debajo de Editar en cada tarjeta).
   - Confirmar eliminacion en el cuadro de dialogo.

Restriccion funcional: si un articulo tiene unidades pendientes de alquilar, el sistema no permite eliminarlo.

### 2.4 Uso del inventario de ruta

1. Entrar en Inventario.
2. Pulsar Editar inventario de ruta.
3. Anadir o ajustar equipamiento por ruta.
4. Guardar cambios para que queden persistidos.

### 2.5 Buenas practicas de uso

- Mantener actualizadas las unidades actuales y totales de cada articulo.
- Revisar periodicamente articulos en bajo stock.
- Evitar eliminar articulos en uso operativo.
- Confirmar cambios sensibles antes de guardar.

### 2.6 Mensajes del sistema y soporte

- La app muestra notificaciones tipo SnackBar al guardar, editar o eliminar.
- Ante errores de sincronizacion o carga, usar la opcion Reintentar.
- Si persisten errores, revisar conectividad y configuracion de Firebase.

---

## 3. Manual de uso del trabajador

### 3.1 Objetivo del rol trabajador
El perfil de trabajador esta orientado a la gestion operativa diaria: control de inventario, seguimiento de rutas, comunicacion por chat y gestion de su propio perfil.

### 3.2 Acceso al panel de trabajador

1. Inicia la aplicacion.
2. Accede con el flujo que te lleve al entorno de trabajador con las credendiales del trabajador.
3. Verifica en la barra inferior que aparecen los modulos: Inventario, Reservas, Chat y Perfil.

### 3.3 Gestion de inventario

1. Abre el modulo Inventario.
2. Usa los filtros de busqueda, categoria, stock y alquiler para localizar articulos.
3. Para editar un articulo:
   - Pulsa Editar en la tarjeta.
   - Cambia los campos necesarios.
   - Pulsa Guardar.
4. Para eliminar un articulo:
   - Pulsa Eliminar (debajo del boton Editar).
   - Confirma la accion en el cuadro de dialogo.

Nota: no se puede eliminar un articulo con unidades pendientes de alquilar.

### 3.4 Gestion de reservas/rutas

1. Entra en Reservas desde la barra inferior.
2. Revisa las rutas asignadas o disponibles segun el estado operativo.
3. Completa las acciones de ruta siguiendo los avisos mostrados por el sistema.
4. Confirma los cambios para que queden registrados.

### 3.5 Uso del chat de trabajador

1. Accede al modulo Chat.
2. Selecciona la conversacion correspondiente.
3. Escribe y envia mensajes de coordinacion con clientes o equipo.
4. Revisa respuestas y notificaciones dentro del mismo modulo.

### 3.6 Gestion de perfil trabajador

1. Accede al modulo Perfil.
2. Consulta tus datos y opciones disponibles.
3. Actualiza la informacion permitida por la app.
4. Guarda los cambios antes de salir.

### 3.7 Incidencias y resolucion rapida

- Si un listado no carga, usa Reintentar y comprueba conexion.
- Si no puedes guardar cambios, revisa que los campos obligatorios esten completos.
- Si aparece error persistente de datos, validar configuracion de Firebase y estado de red.

---
