# 🔄 GUÍA: Actualizar OCRimageflow en GitHub

## 📋 Situación Actual

Tienes en GitHub el código de TaskFlow (gestor de tareas genérico), pero necesitas el código correcto de **OCRimageflow** con:
- ✅ Google Vision OCR
- ✅ Gemini AI
- ✅ Normalización inteligente
- ✅ Tu código original convertido a FastAPI

---

## 🎯 PASO 1: Descargar el Código Correcto

1. **Descarga** la carpeta `ocrflow-backend` que acabo de crear
2. **Guárdala** en tu PC (ejemplo: en Escritorio)

---

## 🎯 PASO 2: Reemplazar el Código en GitHub

### Opción A: Borrar y Resubir (Más Simple)

```powershell
# 1. Ve a tu carpeta actual
cd C:\Users\ab04\OneDrive\Escritorio\taskflow-mvp

# 2. Borra todo el contenido de backend/
Remove-Item -Path backend\* -Recurse -Force

# 3. Copia el nuevo backend
Copy-Item -Path ..\ocrflow-backend\* -Destination backend\ -Recurse

# 4. Verifica que los archivos estén ahí
dir backend

# 5. Agrega los cambios
git add .

# 6. Commit
git commit -m "Replace with OCRimageflow: Google Vision + Gemini AI + Smart Normalization"

# 7. Sube a GitHub
git push origin main
```

### Opción B: Desde Cero (Si prefieres empezar limpio)

```powershell
# 1. Elimina la carpeta anterior
Remove-Item -Path C:\Users\ab04\OneDrive\Escritorio\taskflow-mvp -Recurse -Force

# 2. Renombra la nueva carpeta
Rename-Item -Path C:\Users\ab04\OneDrive\Escritorio\ocrflow-backend -NewName OCRimageflow

# 3. Entra a la carpeta
cd C:\Users\ab04\OneDrive\Escritorio\OCRimageflow

# 4. Inicializa Git
git init

# 5. Conecta con tu repo
git remote add origin https://github.com/chapab/OCRimageflow.git

# 6. Agrega todos los archivos
git add .

# 7. Commit
git commit -m "OCRimageflow: Complete backend with Google Vision + Gemini AI"

# 8. Forzar push (esto reemplazará todo en GitHub)
git push -u origin main --force
```

---

## 🎯 PASO 3: Verificar en GitHub

1. Ve a: https://github.com/chapab/OCRimageflow
2. Deberías ver:
   ```
   OCRimageflow/
   ├── .env.example
   ├── main.py
   ├── requirements.txt
   ├── schema.sql
   ├── test_api.py
   └── README.md
   ```

---

## 🎯 PASO 4: Configurar Railway

### 1. Crear PostgreSQL
1. Ve a https://railway.app
2. **New Project** → **Provision PostgreSQL**
3. Espera a que se cree
4. Click en PostgreSQL → **Connect** → Copia el `DATABASE_URL`

### 2. Ejecutar Schema
1. En Railway → PostgreSQL → **Data** (o Query)
2. Abre tu archivo `schema.sql` local
3. Copia TODO el contenido
4. Pégalo en Railway
5. Click **Execute** o **Run**

### 3. Crear Servicio Web
1. Railway → **+ New** → **GitHub Repo**
2. Selecciona `chapab/OCRimageflow`
3. Railway detectará Python automáticamente

### 4. Configurar Variables de Entorno

En Railway Dashboard → Tu servicio → **Variables**, agrega:

```bash
# Database (la que copiaste en el paso 1)
DATABASE_URL=postgresql://postgres:...

# JWT Secret (genera uno nuevo con el comando de abajo)
JWT_SECRET_KEY=tu-clave-secreta-aqui

# Google Cloud Vision
GOOGLE_CREDENTIALS_JSON=base64-del-json-aqui

# Gemini AI
GEMINI_API_KEY=AIzaSyCjNvD8QMwniuVhowsdd-Iv5Mk6LZTr3wM

# AWS S3 (cuando lo configures)
AWS_ACCESS_KEY_ID=tu-key
AWS_SECRET_ACCESS_KEY=tu-secret
AWS_BUCKET_NAME=tu-bucket
AWS_REGION=us-east-1

# Puerto
PORT=8000
```

#### 🔑 Generar JWT_SECRET_KEY

**En PowerShell:**
```powershell
# Genera una clave aleatoria
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})
```

**Otra opción:**
```
tu-super-clave-secreta-muy-larga-y-aleatoria-2024
```

#### 📄 Convertir google-credentials.json a Base64

**En PowerShell:**
```powershell
$path = "C:\Users\ab04\OneDrive\Escritorio\google-credentials.json"
$bytes = [System.IO.File]::ReadAllBytes($path)
$base64 = [System.Convert]::ToBase64String($bytes)
$base64 | Set-Clipboard
Write-Host "✅ Base64 copiado al portapapeles!"
```

Luego pega el valor en Railway como `GOOGLE_CREDENTIALS_JSON`.

---

## 🎯 PASO 5: Deploy

Railway hará deploy automáticamente. Espera 2-3 minutos.

### Verificar que funciona:

```bash
# Reemplaza con tu URL de Railway
curl https://tu-app.up.railway.app/health
```

Deberías ver:
```json
{
  "status": "healthy",
  "database": "connected",
  "ocr": "ready"
}
```

---

## 🎯 PASO 6: Probar la API

### Opción 1: Desde tu PC (Python)

```powershell
cd C:\Users\ab04\OneDrive\Escritorio\OCRimageflow
python test_api.py
```

Cambia `BASE_URL` en `test_api.py` a tu URL de Railway.

### Opción 2: Swagger UI

Ve a: `https://tu-app.up.railway.app/docs`

Aquí puedes probar todos los endpoints visualmente.

---

## 🆘 Troubleshooting

### Error: "Google Vision failed"
```bash
# Verifica que el Base64 esté correcto
# Prueba generarlo de nuevo
```

### Error: "Database connection failed"
```bash
# Verifica que DATABASE_URL esté correcta
# Confirma que ejecutaste schema.sql
```

### Error: "Module not found"
```bash
# Railway debería instalar automáticamente
# Verifica que requirements.txt esté en la raíz
```

---

## ✅ Checklist Final

- [ ] Código actualizado en GitHub
- [ ] PostgreSQL creado en Railway
- [ ] schema.sql ejecutado
- [ ] Variables de entorno configuradas
- [ ] Deploy exitoso
- [ ] `/health` responde OK
- [ ] Puedes registrar un usuario
- [ ] Puedes hacer login

---

## 🎉 ¡Siguiente Paso!

Una vez que todo funcione, podemos:
1. Configurar AWS S3 para guardar imágenes
2. Probar con imágenes reales
3. Crear el frontend React

¿Listo para actualizar GitHub? 🚀
