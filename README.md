# OCRimageflow Backend API

Sistema de procesamiento inteligente de imágenes con Google Vision OCR, Gemini AI y normalización automática de datos.

## 🚀 Características

- ✅ **Google Vision OCR** - Extracción de texto de imágenes
- ✅ **Gemini AI** - Procesamiento inteligente con IA
- ✅ **Normalización Inteligente** - Limpia y estandariza datos automáticamente
- ✅ **Detección de Industria** - Identifica automáticamente el tipo de producto (moda, muebles, calzado, etc.)
- ✅ **Sistema de Tiers** - Planes: free, starter, basic, pro, enterprise
- ✅ **Autenticación JWT** - Seguridad y control de usuarios
- ✅ **PostgreSQL** - Tracking de uso y logs
- ✅ **AWS S3** - Almacenamiento de imágenes y Excel
- ✅ **Generación de Excel** - Reportes automáticos con imágenes

## 📋 Tiers Disponibles

| Tier | Imágenes/Mes | Imágenes/Batch | OCR Engine |
|------|--------------|----------------|------------|
| **Free** | 10 | 5 | Google Vision |
| **Starter** | 200 | 50 | Google Vision |
| **Basic** | 500 | 100 | Google Vision |
| **Pro** | 2,000 | 200 | Gemini AI |
| **Enterprise** | 10,000 | 500 | Gemini AI |

## 🛠️ Instalación Local

### 1. Clonar el repositorio
```bash
git clone https://github.com/chapab/OCRimageflow.git
cd OCRimageflow/backend
```

### 2. Crear entorno virtual
```bash
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

### 3. Instalar dependencias
```bash
pip install -r requirements.txt
```

### 4. Configurar variables de entorno
```bash
cp .env.example .env
```

Edita `.env` con tus credenciales:
- **DATABASE_URL**: Tu conexión PostgreSQL
- **JWT_SECRET_KEY**: Clave secreta para tokens (genera una con `openssl rand -hex 32`)
- **GOOGLE_CREDENTIALS_JSON**: Tu archivo de credenciales de Google Cloud (ver abajo)
- **GEMINI_API_KEY**: Tu API key de Gemini
- **AWS_ACCESS_KEY_ID** y **AWS_SECRET_ACCESS_KEY**: Credenciales de AWS
- **AWS_BUCKET_NAME**: Nombre de tu bucket S3

### 5. Configurar Google Cloud Vision

#### Opción A: Desarrollo Local
1. Descarga tu archivo JSON de credenciales de Google Cloud
2. Colócalo en una ruta segura
3. En `.env`: `GOOGLE_APPLICATION_CREDENTIALS=/ruta/al/archivo.json`

#### Opción B: Producción (Railway)
1. Convierte tu JSON a Base64:
   ```bash
   # En Linux/Mac:
   base64 -i google-credentials.json | tr -d '\n'
   
   # En Windows PowerShell:
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("google-credentials.json"))
   ```
2. Copia el output y úsalo en: `GOOGLE_CREDENTIALS_JSON=el_base64_aqui`

### 6. Crear base de datos
```bash
psql "postgresql://tu-connection-url" -f schema.sql
```

### 7. Ejecutar servidor
```bash
uvicorn main:app --reload
```

API disponible en: http://localhost:8000

## 📚 API Endpoints

### Autenticación
- `POST /auth/register` - Registrar usuario
  ```json
  {
    "email": "user@example.com",
    "password": "secure_password",
    "name": "John Doe",
    "tier": "starter"
  }
  ```
  
- `POST /auth/login` - Iniciar sesión
  ```json
  {
    "email": "user@example.com",
    "password": "secure_password"
  }
  ```

### Procesamiento de Imágenes
- `POST /process/batch` - Procesar múltiples imágenes (requiere auth)
  - Sube archivos con `multipart/form-data`
  - Retorna: datos normalizados + Excel en S3
  
### Estadísticas
- `GET /usage/stats` - Ver estadísticas de uso (requiere auth)
- `GET /usage/logs` - Ver historial de procesamiento (requiere auth)

### Información
- `GET /` - Información de la API
- `GET /health` - Estado del servicio
- `GET /tiers` - Ver planes disponibles

## 🔐 Autenticación

Todos los endpoints protegidos requieren un token Bearer:

```bash
curl -H "Authorization: Bearer tu_token_aqui" \
  http://localhost:8000/usage/stats
```

## 🧪 Probar la API

### Con cURL
```bash
# 1. Registrarse
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "name": "Test User",
    "tier": "starter"
  }'

# 2. Procesar imágenes
curl -X POST http://localhost:8000/process/batch \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -F "files=@image1.jpg" \
  -F "files=@image2.jpg"
```

### Con Postman
1. Importa la colección desde `/docs` (Swagger UI)
2. Configura el token en Authorization → Bearer Token
3. Prueba los endpoints

## 🚀 Deploy en Railway

### 1. Crear PostgreSQL en Railway
- Ve a https://railway.app
- New Project → Provision PostgreSQL
- Copia el `DATABASE_URL`

### 2. Crear servicio Web
- Add Service → GitHub Repo
- Selecciona tu repositorio `OCRimageflow`
- Railway detectará el `requirements.txt` automáticamente

### 3. Configurar variables de entorno
En Railway Dashboard → Variables, agrega:
```
DATABASE_URL=postgresql://...
JWT_SECRET_KEY=tu-clave-secreta
GOOGLE_CREDENTIALS_JSON=base64_del_json
GEMINI_API_KEY=tu-api-key
AWS_ACCESS_KEY_ID=tu-key
AWS_SECRET_ACCESS_KEY=tu-secret
AWS_BUCKET_NAME=tu-bucket
AWS_REGION=us-east-1
PORT=8000
```

### 4. Ejecutar schema.sql
- En Railway → PostgreSQL → Query
- Copia y pega todo el contenido de `schema.sql`
- Execute

### 5. Deploy
- Railway hará deploy automáticamente
- Obtendrás una URL pública: `https://tu-app.up.railway.app`

## 📖 Documentación Interactiva

Una vez corriendo, visita:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🔍 Cómo Funciona

### 1. Usuario sube imágenes
```
POST /process/batch con imágenes
```

### 2. Sistema procesa cada imagen
- Detecta tier del usuario
- Verifica límites
- Extrae texto con Google Vision o Gemini
- Normaliza campos detectados
- Identifica industria (moda, muebles, etc.)

### 3. Normalización inteligente
- **Campos**: "pre$io" → "precio_unitario"
- **Valores**: "10.5 KF" → "10.5 kg"
- **Tallas**: "medium" → "M"
- **Precios**: "25" → "$25.00"

### 4. Detección de industria
Analiza palabras clave:
- **Fashion**: camisa, talla, composición
- **Furniture**: silla, mesa, dimensiones
- **Footwear**: zapato, suela
- **Baby**: bebé, meses, infantil
- **Textile**: tela, rollo, yardas

### 5. Genera Excel + sube a S3
- Crea Excel con columnas ordenadas por industria
- Inserta imágenes en miniatura
- Sube a S3
- Retorna URL para descarga

## 🆘 Solución de Problemas

### Error: "Google Vision failed"
- Verifica que `GOOGLE_CREDENTIALS_JSON` esté correctamente en Base64
- O que `GOOGLE_APPLICATION_CREDENTIALS` apunte al archivo correcto

### Error: "Gemini OCR failed"
- Verifica tu `GEMINI_API_KEY`
- Confirma que el tier del usuario es 'pro' o 'enterprise'

### Error: "S3 upload failed"
- Verifica credenciales AWS
- Confirma que el bucket existe y tiene permisos correctos

### Error: "Database connection failed"
- Verifica el `DATABASE_URL`
- Asegúrate que la base de datos existe
- Confirma que ejecutaste `schema.sql`

## 📝 Próximas Mejoras

- [ ] Frontend React
- [ ] Webhooks para notificaciones
- [ ] API de búsqueda en datos procesados
- [ ] Dashboard de analytics
- [ ] Exportación a CSV/JSON
- [ ] Integración con Zapier

## 📄 Licencia

MIT

## 👨‍💻 Contacto

¿Preguntas? Abre un issue en GitHub.
