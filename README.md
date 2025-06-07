# 📸 Rally Fotográfico

Aplicación móvil multiplataforma desarrollada en Flutter que permite la gestión de un concurso de fotografía (rally). Los participantes pueden registrarse, subir imágenes, votar y consultar resultados. Los administradores pueden aprobar imágenes, ver estadísticas y finalizar el rally.

![Flutter](https://img.shields.io/badge/flutter-3.19.0-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/firebase-integrated-orange?logo=firebase)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📲 Características

- Registro e inicio de sesión con correo electrónico (Firebase Auth).
- Gestión de roles: participante y administrador.
- Subida y aprobación de imágenes.
- Votación de imágenes con estrellas (1–5).
- Visualización de galería, puntuaciones y autores.
- Tema claro / oscuro personalizable por el usuario.
- Finalización de rally con podium automático (top 3).
- Administración de usuarios (solo administradores).
- Backend sin servidor (Firebase Firestore, Storage, Auth).

---

## 🛠️ Tecnologías

- **Frontend**: Flutter 3.x (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Dependencias principales**:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_storage`
  - `image_picker`
  - `flutter_lints`
  - `flutter_launcher_icons`

---

## 📦 Estructura del Proyecto

```bash
lib/
├── main.dart                  # Punto de entrada
├── firebase_options.dart      # Configuración de Firebase
├── screens/                   # Pantallas de la app
│   ├── home.dart
│   ├── login.dart
│   ├── signUp.dart
│   ├── rally.dart
│   ├── imageDetail.dart
│   ├── users.dart
│   ├── endRally.dart
│   └── options.dart
├── models/                    # Modelos de datos (User, Imagen, Rally)
├── services/                  # Lógica de negocio y acceso a Firebase
test/                          # Pruebas unitarias
