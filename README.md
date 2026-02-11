# Pixorama Heart Reveal 🎨❤️

A Flutter + Serverpod application where users can reveal a secret heart message by painting over it.

## Features
- **5x5 Brush**: Rapid painting with a wide "Area of Effect".
- **Heart Reveal**: Hidden letters turn black when painted with the right colors.
- **Confetti Celebration**: Explosive effect when the heart is fully revealed.
- **Optimized Strokes**: Debounced server communication for smooth dragging.

## Local Development

### Server
1. Navigate to `pixorama_server`.
2. Start Postgres (e.g., via Docker): `docker compose up --build --detach`.
3. Run the server: `dart bin/main.dart`.

### Client
1. Navigate to `pixorama_flutter`.
2. Run the app: `flutter run`.

## Cloud Deployment (Zero Cost)

### 1. Database (Neon.tech)
- Create a free PostgreSQL project on [Neon.tech](https://neon.tech).
- Get your connection details (host, port, name, user, password).

### 2. Backend (Render.com)
- Create a new **Web Service** on [Render.com](https://render.com).
- Connect this GitHub repository.
- Set **Root Directory** to `pixorama_server`.
- Set Environment Variables:
  - `runmode`: `production`
  - `PUBLIC_HOST`: Your Render URL (e.g., `pixorama.onrender.com`)
  - `DB_HOST`: Your Neon host
  - `DB_PORT`: `5432`
  - `DB_NAME`: `neondb` (usually)
  - `DB_USER`: Your Neon user
  - `DB_PASSWORD`: Your Neon password

### 3. Frontend (Flutter Web)
- Build the web app: `cd pixorama_flutter && flutter build web`.
- Host the `build/web` folder on **GitHub Pages**, **Vercel**, or similar.
- Update `assets/config.json` with your backend's Render URL.
