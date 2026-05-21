# IPI Avaré - App Flutter

App mobile da Igreja Presbiteriana de Avaré, construído com Flutter.

## Pré-requisitos

1. **Flutter SDK** (>= 3.22.0)
   - [Download Flutter](https://docs.flutter.dev/get-started/install/windows)
   - Após instalar, execute `flutter doctor` para verificar dependências

2. **Git** (para clonar o repositório)

3. **Editor**: VS Code (recomendado) ou Android Studio
   - Extensão VS Code: [Flutter](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

---

## Setup do Projeto

```bash
# 1. Navegue até a pasta do app
cd apps/mobile2

# 2. Gere os arquivos de plataforma (Android/iOS)
flutter create --project-name church_app_mobile .

# 3. Instale as dependências
flutter pub get

# 4. (Opcional) Gere código com build_runner
dart run build_runner build
```

---

## Configuração do Google Sign-In

### 1. Console Google Cloud

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione o projeto ou crie um novo
3. Vá em **APIs e Serviços > Credenciais**
4. Crie ou edite o **ID do cliente OAuth 2.0 para Android**:
   - **Nome do pacote**: `com.igreja.church_app_mobile`
   - **SHA-1 de debug**:
     ```bash
     keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - **SHA-1 de release** (da sua keystore):
     ```bash
     keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
     ```
5. Crie o **ID do cliente OAuth 2.0 para Web**:
   - Use o mesmo `webClientId` configurado no código

### 2. Arquivos de Configuração

**Android** (`android/app/google-services.json`):
- Baixe o `google-services.json` do Console Google (Firebase ou Cloud Console)
- Coloque em: `android/app/google-services.json`

**iOS** (`ios/Runner/GoogleService-Info.plist`):
- Baixe o `GoogleService-Info.plist` do Console Google
- Coloque em: `ios/Runner/GoogleService-Info.plist`

### 3. AndroidManifest.xml

Edite `android/app/src/main/AndroidManifest.xml` e adicione:

```xml
<application ...>
    <meta-data
        android:name="com.google.android.gms.version"
        android:value="@integer/google_play_services_version" />
</application>
```

---

## Build do APK

### Debug (para teste rápido)

```bash
flutter build apk --debug
```
APK gerado em: `build/app/outputs/flutter-apk/app-debug.apk`

### Release (para distribuição)

#### 1. Gerar Keystore (apenas na primeira vez)

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

#### 2. Criar `android/key.properties`

```properties
storePassword=suasenha
keyPassword=suasenha
keyAlias=upload
storeFile=upload-keystore.jks
```

#### 3. Build Release

```bash
flutter build apk --release
```
APK gerado em: `build/app/outputs/flutter-apk/app-release.apk`

### AppBundle (Play Store)

```bash
flutter build appbundle --release
```
Bundle gerado em: `build/app/outputs/bundle/release/app-release.aab`

---

## Comandos Úteis

```bash
# Rodar o app
flutter run

# Rodar no dispositivo específico
flutter run -d <device-id>

# Listar dispositivos
flutter devices

# Limpar cache
flutter clean

# Verificar configuração
flutter doctor

# Atualizar dependências
flutter pub upgrade

# Análise estática
flutter analyze
```

---

## Estrutura do Projeto

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # MaterialApp.router
├── core/
│   ├── config/               # API config, theme
│   ├── constants/            # App constants
│   ├── network/              # Dio client, interceptors
│   ├── router/               # GoRouter config
│   └── utils/                # Validators, formatters, storage
├── shared/
│   ├── models/               # User, API response models
│   ├── providers/            # Auth, theme providers
│   └── widgets/              # Reusable UI components
└── features/
    ├── auth/                 # Login, splash
    ├── dashboard/            # Home screen
    ├── prayers/              # Prayer feed, detail, create
    ├── events/               # Calendar, event detail
    ├── schedules/            # Schedule list
    ├── members/              # Member list, detail
    ├── finance/              # Dashboard, transactions
    ├── notifications/        # Notification list
    └── settings/             # Profile, settings
```

---

## Solução de Problemas

### Google Sign-In não funciona

1. **SHA-1 incorreto**: O erro `10` no Android indica SHA-1 não cadastrado
   - Verifique: `keytool -list -v -keystore ...` e confira se o SHA-1 está no Console Google
   - Você precisa cadastrar **TANTO** o SHA-1 de debug quanto o de release

2. **google-services.json ausente ou incorreto**:
   - Verifique se o arquivo está em `android/app/google-services.json`
   - O `package_name` dentro do JSON deve ser `com.igreja.church_app_mobile`

3. **Web client ID incorreto**:
   - O `serverClientId` no código deve corresponder ao Web Client ID do Console Google
   - Edite em `lib/features/auth/presentation/screens/login_screen.dart`

### Erro de conexão com API

Por padrão, a API aponta para `http://10.0.2.2:3000` (Android Emulator → host local).
Para alterar, use a variável de ambiente:

```bash
flutter run --dart-define=API_URL=https://api.ipiavare.com.br
```

Ou edite `lib/core/config/theme/api_config.dart` (na verdade `lib/core/config/api_config.dart`).

---

## Tecnologias

| Categoria | Pacote |
|-----------|--------|
| Estado | flutter_riverpod + riverpod_annotation |
| Roteamento | go_router |
| HTTP | dio |
| Google Sign-In | google_sign_in |
| Armazenamento | flutter_secure_storage |
| Gráficos | fl_chart |
| Formatação | intl |
| Skeleton | shimmer |
| Imagens | cached_network_image |
| Geração de código | build_runner + riverpod_generator |
