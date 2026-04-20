# Sistema de Chat Bidireccional - Guía de Uso

## 📋 Resumen de Cambios

Se ha implementado un sistema completo de mensajería bidireccional que permite:
- ✅ **Clientes y Trabajadores** pueden comunicarse entre sí
- ✅ **Lista de conversaciones** con vista previa del último mensaje
- ✅ **Chat individual** para cada conversación
- ✅ **Persistencia en base de datos** SQLite
- ✅ **Historial de mensajes** completo

---

## 🏗️ Estructura de Archivos Creados/Modificados

### 1. **Nuevos Archivos de Modelos**

#### `lib/models/chat_message.dart`
Contiene dos clases principales:
- **`ChatMessage`**: Representa un mensaje individual
  - `id`: Identificador único
  - `conversationId`: ID de la conversación
  - `senderEmail`: Email del remitente
  - `senderName`: Nombre del remitente
  - `senderRole`: Rol ('cliente' o 'trabajador')
  - `text`: Contenido del mensaje
  - `timestamp`: Fecha y hora
  - `isFile`: Indica si es un archivo
  - `fileSize`: Tamaño del archivo (opcional)
  - `filePath`: Ruta del archivo (opcional)

- **`Conversation`**: Representa una conversación entre dos usuarios
  - `id`: Identificador único (formato: `clientEmail_workerEmail`)
  - `clientEmail`: Email del cliente
  - `clientName`: Nombre del cliente
  - `workerEmail`: Email del trabajador
  - `workerName`: Nombre del trabajador
  - `lastMessageTime`: Hora del último mensaje
  - `lastMessagePreview`: Vista previa del último mensaje
  - `unreadCount`: Cantidad de mensajes no leídos

### 2. **Nueva Base de Datos**

#### `lib/data/chat_database.dart`
Gestiona toda la persistencia de datos de chat:

**Métodos principales:**
- `getOrCreateConversation()`: Crea o obtiene una conversación
- `getConversationsForUser()`: Obtiene todas las conversaciones de un usuario
- `insertMessage()`: Inserta un nuevo mensaje
- `getMessages()`: Obtiene todos los mensajes de una conversación
- `updateConversationLastMessage()`: Actualiza el último mensaje

---

## 📱 Pantallas Modificadas

### **Chat del Cliente** (`lib/pantalla/chatCliente.dart`)

#### Estructura de dos pantallas:

1. **`ChatScreen`** - Lista de Conversaciones
   - Muestra todas las conversaciones del cliente
   - Botón flotante para iniciar nuevo chat con soporte
   - Indicador de mensajes no leídos
   - Fecha/hora del último mensaje

2. **`ClientIndividualChatScreen`** - Chat Individual
   - Historial de mensajes completo
   - Campo de entrada de mensajes
   - Botón de adjuntar archivos
   - Scroll automático al nuevo mensaje
   - Interfaz de burbujas de chat estilo WhatsApp

---

### **Chat del Trabajador** (`lib/pantalla/chatTrabajador.dart`)

#### Estructura de dos pantallas:

1. **`WorkerChatScreen`** - Lista de Clientes
   - Muestra todos los clientes con conversaciones
   - Avatar con inicial del nombre
   - Vista previa del último mensaje
   - Indicador de mensajes no leídos
   - Hora del último mensaje

2. **`WorkerIndividualChatScreen`** - Chat Individual
   - Misma funcionalidad que cliente
   - Burbujas de chat diferenciadas por rol
   - Información del cliente en el AppBar
   - Gestión automática de scroll

---

## 🔄 Flujo de Funcionamiento

### **Desde el Cliente:**
```
1. Usuario inicia sesión (email almacenado en CurrentUserSession)
2. Accede a Chat → ChatScreen
3. Ve lista de conversaciones o botón para iniciar nueva
4. Hace clic en "Iniciar Chat con Soporte"
5. Se crea conversación automáticamente
6. Abre ClientIndividualChatScreen
7. Puede escribir y ver historial de mensajes
```

### **Desde el Trabajador:**
```
1. Usuario (trabajador) inicia sesión
2. Accede a Chat → WorkerChatScreen
3. Ve lista de clientes con los que ha chateado
4. Hace clic en un cliente
5. Abre WorkerIndividualChatScreen
6. Puede ver el historial y responder mensajes
```

---

## 💾 Base de Datos

**Archivo:** `greenscape_chat.db`

### Tabla `conversations`
```sql
CREATE TABLE conversations (
  id TEXT PRIMARY KEY,
  client_email TEXT NOT NULL,
  client_name TEXT NOT NULL,
  worker_email TEXT NOT NULL,
  worker_name TEXT NOT NULL,
  last_message_time INTEGER NOT NULL,
  last_message_preview TEXT NOT NULL,
  unread_count INTEGER DEFAULT 0
)
```

### Tabla `messages`
```sql
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id TEXT NOT NULL,
  sender_email TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  sender_role TEXT NOT NULL,
  text TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  is_file INTEGER DEFAULT 0,
  file_size TEXT,
  file_path TEXT,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id)
)
```

---

## 🔐 Gestión de Sesión

La sessión del usuario se mantiene con `CurrentUserSession`:
- El email se almacena al iniciar sesión
- Se utiliza para identificar remitentes en mensajes
- Se valida antes de enviar mensajes

---

## 🎨 Características de Diseño

✅ **Burbujas de Chat:**
- Verde claro para mensajes del usuario
- Gris claro para mensajes del otro
- Bordes redondeados dinámicos

✅ **Timestamps:**
- Formato HH:MM en los chats
- Fecha completa en lista de conversaciones
- "Hoy", "Ayer" o fecha en lista

✅ **Indicadores:**
- Badges rojos con cantidad de no leídos
- Avatares con iniciales del nombre
- Iconos de archivos adjuntos

---

## 📝 Próximas Mejoras Sugeridas

1. **Indicadores de "escribiendo..."**
2. **Confirmación de lectura** (read receipts)
3. **Descarga real de archivos**
4. **Búsqueda en conversaciones**
5. **Notificaciones push**
6. **Sincronización con backend remoto**
7. **Encriptación end-to-end**

---

## 🐛 Troubleshooting

### "Sin conversaciones aún"
- Es normal al inicio
- El cliente debe iniciar chat con soporte
- El trabajador verá clientes cuando los clientes inicien conversaciones

### Mensajes no se envían
- Verifica que `CurrentUserSession.currentUserEmail` no es null
- Revisa que tienes permisos de escritura en la BD

### Errores de compilación
- Ejecuta `flutter pub get`
- Ejecuta `flutter clean && flutter pub get` si persiste
