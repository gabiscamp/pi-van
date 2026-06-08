# Firebase Setup — VanGo

> Projeto já configurado: `app-de-van-5f05d`  
> Este documento serve de referência para reconfiguração ou novo ambiente.

---

## Projeto Firebase existente

| Campo | Valor |
|---|---|
| Project ID | `app-de-van-5f05d` |
| Project Number | `688654083193` |
| Android App ID | `1:688654083193:android:ee6d2c056025c909ade0a8` |
| iOS App ID | `1:688654083193:ios:62921e79299bfe9dade0a8` |
| Web App ID | `1:688654083193:web:07e305605b5e95ecade0a8` |
| Hosting URL | `https://app-de-van-5f05d.web.app` |

---

## Serviços ativos

- **Authentication** — Email/senha
- **Cloud Firestore** — Banco de dados (plano Spark gratuito)
- **Firebase Hosting** — PWA / Web app

---

## Arquivos de configuração no projeto

```
pi_van/
├── google-services.json          → Android (gerado pelo Firebase Console)
├── firebase.json                 → Configuração FlutterFire + Hosting
├── lib/firebase_options.dart     → Gerado pelo FlutterFire CLI
└── ios/Runner/GoogleService-Info.plist  → iOS
```

---

## Como reconfigurar do zero (se necessário)

### 1. Instalar FlutterFire CLI
```powershell
dart pub global activate flutterfire_cli
```

### 2. Configurar o projeto
```powershell
cd pi_van
flutterfire configure --project=app-de-van-5f05d
```

### 3. Firebase CLI para hosting
```powershell
npm install -g firebase-tools
firebase login
firebase use app-de-van-5f05d
```

---

## Deploy

### Web (PWA)
```powershell
flutter build web --no-tree-shake-icons
firebase deploy --only hosting
```

### Android APK
```powershell
flutter build apk --release
# Arquivo: build\app\outputs\flutter-apk\app-release.apk
```

---

## Regras do Firestore

As regras atuais permitem leitura/escrita para qualquer usuário autenticado.
Para enrijecer em produção, ver [firestore.md](firestore.md).

Para publicar novas regras:
```powershell
firebase deploy --only firestore:rules
```

---

## Plano e custos

O projeto está no **plano Spark (gratuito)**:

| Recurso | Limite gratuito |
|---|---|
| Firestore — leituras | 50.000/dia |
| Firestore — gravações | 20.000/dia |
| Hosting — armazenamento | 10 GB |
| Hosting — transferência | 360 MB/dia |
| Authentication | Ilimitado |

> Para adicionar Cloud Functions (notificações em background) seria necessário upgrade para o plano **Blaze (pay-as-you-go)** — requer cartão de crédito mas tem nível gratuito equivalente ao Spark.

---

## Notificações push (Cloud Functions — não ativo)

As Cloud Functions foram desenvolvidas mas não implantadas por exigir plano Blaze.
Os arquivos estão na branch `sprint_4` em `pi_van/functions/src/index.ts` caso seja necessário ativar no futuro.

Funções desenvolvidas:
- `onStudentLiberado` — notifica motorista quando aluno marca liberado
- `onDriverLocationUpdate` — notifica aluno quando motorista está a 300m
