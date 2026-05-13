# ZKred Wallet

A proof-of-concept Flutter identity wallet built on the **Privado ID Flutter SDK** (`polygonid_flutter_sdk`). Demonstrates self-sovereign identity (SSI) with zero-knowledge proofs — users can create a DID, receive verifiable credentials from issuers, and authenticate with verifiers without revealing sensitive data.

---

## Features

| Feature | Description |
|---|---|
| **Identity Creation** | Generate a W3C DID stored securely on-device |
| **ZK Authentication** | Scan a verifier's QR → SDK generates ZK proof → sends to verifier |
| **Credential Offers** | Scan an issuer's QR → fetch & store verifiable credentials |
| **Credential Management** | View, inspect and delete credentials |
| **Circuit Download** | First-launch downloads ZK circuit files with progress indicator |

---

## Architecture

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp, routes, theme
├── config/
│   └── app_config.dart          # Network config (blockchain, RPC, contracts)
├── providers/
│   └── wallet_provider.dart     # All SDK interactions via ChangeNotifier
├── screens/
│   ├── splash_screen.dart       # SDK init + circuit download progress
│   ├── home_screen.dart         # Dashboard with identity card + quick actions
│   ├── identity_screen.dart     # Create / view / remove DID
│   ├── credentials_screen.dart  # List all credentials
│   └── scanner_screen.dart      # QR scanner (auth or credential offer)
└── widgets/
    └── credential_card.dart     # Credential list item with detail modal
```

**State management**: `provider` (ChangeNotifier) — simple and sufficient for a POC.  
**Key storage**: `flutter_secure_storage` with Android EncryptedSharedPreferences.

---

## Prerequisites

- **Flutter 3.16+** ([install](https://docs.flutter.dev/get-started/install))
- **Dart 3.0+**
- Android: Android Studio / SDK (API 21+)
- iOS: Xcode 15+, CocoaPods

---

## Setup

### 1. Install Flutter & clone

```bash
# Install Flutter if needed
# https://docs.flutter.dev/get-started/install

cd wallet-demo-latest-sumit

# Generate native project files (android/, ios/ boilerplate)
# This fills in generated files that are not committed (Xcode project, etc.)
flutter create --project-name zkred_wallet --org io.zkred --platforms android,ios .
```

> **Note:** `flutter create .` will NOT overwrite your existing `lib/` or `pubspec.yaml` files.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. iOS setup

```bash
cd ios
pod install
cd ..
```

### 4. Configure network (optional)

Edit `lib/config/app_config.dart` to point to your preferred network:

```dart
// For mainnet:
static const String network = 'main';
static const String web3Url = 'https://polygon-rpc.com/';
// Update idStateContract with the mainnet address from docs.privado.id
```

### 5. Run

```bash
# Android
flutter run -d <android-device-id>

# iOS
flutter run -d <ios-device-id>

# List available devices
flutter devices
```

---

## SDK Version

```yaml
polygonid_flutter_sdk: ^2.4.0
```

Check [pub.dev](https://pub.dev/packages/polygonid_flutter_sdk) or the [GitHub repo](https://github.com/0xPolygonID/polygonid-flutter-sdk) for the latest version.

---

## Key SDK Usage

### Initialize
```dart
await PolygonIdSdk.init(env: EnvEntity(
  blockchain: 'polygon',
  network: 'amoy',
  web3Url: 'https://rpc-amoy.polygon.technology/',
  ...
));
```

### Create Identity
```dart
final identity = await PolygonIdSdk.I.identity.addIdentity();
final did = await PolygonIdSdk.I.identity.getIdentifier(
  privateKey: identity.privateKey,
);
```

### Handle QR (Auth / Credential Offer)
```dart
final message = await PolygonIdSdk.I.iden3comm.getIden3Message(message: qrString);

// Auth (generates ZK proof internally):
await PolygonIdSdk.I.iden3comm.authenticate(
  iden3message: message, identifier: did, privateKey: privateKey,
);

// Credential offer:
await PolygonIdSdk.I.iden3comm.fetchAndSaveClaims(
  credentialRequests: requests, identifier: did, privateKey: privateKey,
);
```

---

## Known Limitations (POC)

- **iOS Simulator** is not supported by the SDK's ZK libraries (device only)
- Circuit files (~50 MB) are downloaded on first launch — needs a network connection
- No backup/restore of identity across devices (for production: implement mnemonic export)
- Contract addresses are for Polygon Amoy testnet — update for production

---

## References

- [Privado ID Docs](https://docs.privado.id)
- [Flutter SDK Docs](https://docs.privado.id/docs/category/flutter-sdk)
- [SDK GitHub](https://github.com/0xPolygonID/polygonid-flutter-sdk)
- [iden3 Protocol](https://docs.iden3.io)
