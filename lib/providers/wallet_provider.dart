import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:polygonid_flutter_sdk/common/domain/domain_constants.dart';
import 'package:polygonid_flutter_sdk/credential/domain/entities/claim_entity.dart';
import 'package:polygonid_flutter_sdk/iden3comm/domain/entities/common/iden3_message_entity.dart';
import 'package:polygonid_flutter_sdk/iden3comm/domain/entities/credential/request/base.dart';
import 'package:polygonid_flutter_sdk/proof/data/dtos/circuits_to_download_param.dart';
import 'package:polygonid_flutter_sdk/proof/domain/entities/download_info_entity.dart';
import 'package:polygonid_flutter_sdk/sdk/polygon_id_sdk.dart';

import '../config/app_config.dart';

export 'package:polygonid_flutter_sdk/credential/domain/entities/claim_entity.dart'
    show ClaimEntity, ClaimState;

enum WalletStatus { initial, initializing, ready, error }

class WalletProvider extends ChangeNotifier {
  static final _log = Logger();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  WalletStatus _status = WalletStatus.initial;
  String? _genesisDid;   // the full DID string, e.g. did:polygonid:polygon:amoy:...
  String? _privateKey;
  List<ClaimEntity> _credentials = [];
  String? _error;
  bool _isLoading = false;
  double _circuitProgress = 0.0;
  String _statusMessage = 'Starting up...';

  // Pending auth — set when multiple credentials match a proof request scope
  Iden3MessageEntity? _pendingAuthMessage;
  List<ClaimEntity> _pendingMatchingCredentials = [];

  // ---- Getters ----

  WalletStatus get status => _status;
  String? get identifier => _genesisDid;
  bool get hasIdentity => _genesisDid != null && _privateKey != null;
  List<ClaimEntity> get credentials => List.unmodifiable(_credentials);
  String? get error => _error;
  bool get isLoading => _isLoading;
  double get circuitProgress => _circuitProgress;
  String get statusMessage => _statusMessage;
  bool get isReady => _status == WalletStatus.ready;
  bool get hasPendingAuthSelection => _pendingAuthMessage != null;
  List<ClaimEntity> get pendingMatchingCredentials =>
      List.unmodifiable(_pendingMatchingCredentials);

  // ---- SDK Initialization ----

  bool _sdkInitialized = false;

  /// Initialize the Privado ID SDK. Called once from SplashScreen.
  Future<void> initSdk() async {
    _setStatus(WalletStatus.initializing, 'Initializing Privado ID SDK...');

    try {
      if (!_sdkInitialized) {
        try {
          await PolygonIdSdk.init(env: AppConfig.buildEnv());
          _sdkInitialized = true;
        } catch (e) {
          // GetIt double-registration on retry — SDK is already wired up.
          if (e.toString().contains('already registered')) {
            _log.d('SDK already initialized (GetIt), skipping re-init');
            _sdkInitialized = true;
          } else {
            rethrow;
          }
        }
      }

      PolygonIdSdk.I.errorHandling.switchStacktrace(enabled: true);
      PolygonIdSdk.I.errorHandling.stacktraceStream()
          .listen((trace) { if (trace.isNotEmpty) _log.d('[SDK-TRACE] $trace'); });

      await _loadSavedIdentity();
      await _downloadCircuits();

      _setStatus(WalletStatus.ready, 'Ready');
    } catch (e, st) {
      _log.e('SDK init failed', error: e, stackTrace: st);
      _setStatus(WalletStatus.error, 'Initialization failed');
      _setError('SDK initialization failed:\n$e');
    }
  }

  Future<void> _downloadCircuits() async {
    _setMsg('Checking ZK circuit files...');
    Timer? progressTimer;
    try {
      // background_downloader writes to its own temp file in the cache dir
      // (named com.bbflight.background_downloader{random}), not to our path.
      // We scan the cache dir to sum those files for real byte progress.
      final cacheDir = await getTemporaryDirectory();

      final stream = PolygonIdSdk.I.proof.initCircuitsDownloadAndGetInfoStream(
        circuitsToDownload: [
          CircuitsToDownloadParam(
            circuitsName: 'circuits',
            bucketUrl: AppConfig.circuitsBucketUrl,
          ),
        ],
      );

      progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        try {
          int bytes = 0;
          if (cacheDir.existsSync()) {
            for (final f in cacheDir.listSync()) {
              if (f is File &&
                  f.path.contains('com.bbflight.background_downloader')) {
                bytes += f.lengthSync();
              }
            }
          }
          if (bytes > 0) {
            final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
            _setMsg('Downloading ZK circuits: $mb MB');
            notifyListeners();
          }
        } catch (_) {}
      });

      await for (final info in stream) {
        if (info is DownloadInfoOnProgress) {
          final total = info.contentLength;
          if (total > 0 && info.downloaded > 0) {
            // Server did provide Content-Length — show percentage
            progressTimer.cancel();
            _circuitProgress = info.downloaded / total;
            _setMsg(
                'Downloading ZK circuits: ${(_circuitProgress * 100).toInt()}%');
          }
          // else let the timer poll show the MB counter
        } else if (info is DownloadInfoOnDone) {
          progressTimer.cancel();
          _circuitProgress = 1.0;
          _setMsg('ZK circuits ready');
          break;
        } else if (info is DownloadInfoOnError) {
          progressTimer.cancel();
          _log.w('Circuit download error: ${info.errorMessage}');
          break;
        }
      }
    } catch (e) {
      // Circuits may already be present — not a fatal error
      _log.w('Circuit download: $e');
    } finally {
      progressTimer?.cancel();
    }
    _circuitProgress = 1.0;
    notifyListeners();
  }

  Future<void> _loadSavedIdentity() async {
    _setMsg('Loading saved identity...');
    _privateKey = await _storage.read(key: AppConfig.keyPrivateKey);
    _genesisDid = await _storage.read(key: AppConfig.keyGenesisDid);
    if (_genesisDid != null) _log.d('Loaded identity: $_genesisDid');
  }

  // ---- Identity Management ----

  /// Create a new self-sovereign identity (DID) and persist to secure storage.
  Future<void> createIdentity() async {
    _setLoading(true);
    _clearError();
    try {
      final identity = await PolygonIdSdk.I.identity.addIdentity();
      _privateKey = identity.privateKey;
      _genesisDid = await PolygonIdSdk.I.identity.getDidIdentifier(
        privateKey: _privateKey!,
        blockchain: AppConfig.blockchain,
        network: AppConfig.network,
      );

      await _storage.write(key: AppConfig.keyPrivateKey, value: _privateKey);
      await _storage.write(key: AppConfig.keyGenesisDid, value: _genesisDid);

      _log.d('Identity created: $_genesisDid');
      notifyListeners();
    } catch (e, st) {
      _log.e('Create identity failed', error: e, stackTrace: st);
      _setError('Failed to create identity:\n$e');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove the current identity and immediately create a fresh one.
  Future<void> regenerateIdentity() async {
    if (!hasIdentity) return;
    _setLoading(true);
    _clearError();
    try {
      await PolygonIdSdk.I.identity.removeIdentity(
        genesisDid: _genesisDid!,
        privateKey: _privateKey!,
      );
      await _storage.delete(key: AppConfig.keyPrivateKey);
      await _storage.delete(key: AppConfig.keyGenesisDid);
      _privateKey = null;
      _genesisDid = null;
      _credentials = [];

      final identity = await PolygonIdSdk.I.identity.addIdentity();
      _privateKey = identity.privateKey;
      _genesisDid = await PolygonIdSdk.I.identity.getDidIdentifier(
        privateKey: _privateKey!,
        blockchain: AppConfig.blockchain,
        network: AppConfig.network,
      );
      await _storage.write(key: AppConfig.keyPrivateKey, value: _privateKey);
      await _storage.write(key: AppConfig.keyGenesisDid, value: _genesisDid);

      _log.d('Identity regenerated: $_genesisDid');
      notifyListeners();
    } catch (e, st) {
      _log.e('Regenerate identity failed', error: e, stackTrace: st);
      _setError('Failed to regenerate identity:\n$e');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove the current identity from wallet and wipe stored keys.
  Future<void> removeIdentity() async {
    if (!hasIdentity) return;
    _setLoading(true);
    _clearError();
    try {
      await PolygonIdSdk.I.identity.removeIdentity(
        genesisDid: _genesisDid!,
        privateKey: _privateKey!,
      );
      await _storage.delete(key: AppConfig.keyPrivateKey);
      await _storage.delete(key: AppConfig.keyGenesisDid);
      _privateKey = null;
      _genesisDid = null;
      _credentials = [];
      notifyListeners();
    } catch (e, st) {
      _log.e('Remove identity failed', error: e, stackTrace: st);
      _setError('Failed to remove identity:\n$e');
    } finally {
      _setLoading(false);
    }
  }

  // ---- Credential Management ----

  /// Fetch all credentials from local wallet storage.
  Future<void> loadCredentials() async {
    if (!hasIdentity) return;
    _setLoading(true);
    _clearError();
    try {
      _credentials = await PolygonIdSdk.I.credential.getClaims(
        genesisDid: _genesisDid!,
        privateKey: _privateKey!,
      );
      notifyListeners();
    } catch (e, st) {
      _log.e('Load credentials failed', error: e, stackTrace: st);
      _setError('Failed to load credentials:\n$e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a single credential by its ID.
  Future<void> removeCredential(String claimId) async {
    if (!hasIdentity) return;
    _setLoading(true);
    _clearError();
    try {
      await PolygonIdSdk.I.credential.removeClaim(
        claimId: claimId,
        genesisDid: _genesisDid!,
        privateKey: _privateKey!,
      );
      _credentials.removeWhere((c) => c.id == claimId);
      notifyListeners();
    } catch (e, st) {
      _log.e('Remove credential failed', error: e, stackTrace: st);
      _setError('Failed to remove credential:\n$e');
    } finally {
      _setLoading(false);
    }
  }

  // ---- QR / iden3comm Message Handling ----

  /// Resolve any input into a raw iden3comm JSON string.
  /// Handles:
  ///  - Raw JSON (passed through as-is)
  ///  - Deep links: https://wallet.privado.id#request_uri=<encoded-url>
  ///  - Bare https:// URLs pointing directly to iden3comm JSON
  Future<String> _resolveMessage(String raw) async {
    final trimmed = raw.trim();

    // Deep link with request_uri fragment/query param
    if (trimmed.contains('request_uri=')) {
      final uri = Uri.parse(trimmed);
      String? encodedUri = uri.fragment.isNotEmpty
          ? _extractParam(uri.fragment, 'request_uri')
          : _extractParam(uri.query, 'request_uri');

      if (encodedUri != null) {
        return _fetchUrl(Uri.parse(Uri.decodeComponent(encodedUri)));
      }
    }

    // Bare https:// or http:// URL — fetch it directly
    if (trimmed.startsWith('https://') || trimmed.startsWith('http://')) {
      return _fetchUrl(Uri.parse(trimmed));
    }

    return trimmed;
  }

  Future<String> _fetchUrl(Uri uri) async {
    _setMsg('Fetching request from issuer...');
    final response = await http.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Issuer returned HTTP ${response.statusCode}');
    }
    return response.body;
  }

  String? _extractParam(String source, String key) {
    final prefix = '$key=';
    final idx = source.indexOf(prefix);
    if (idx == -1) return null;
    final start = idx + prefix.length;
    final end = source.indexOf('&', start);
    return end == -1 ? source.substring(start) : source.substring(start, end);
  }

  /// Parse and process any iden3comm QR code string.
  /// Handles: auth requests (ZK proof) and credential offers.
  /// Returns true on success.
  Future<bool> handleQrMessage(String qrContent) async {
    if (!hasIdentity) {
      _setError('Please create an identity first.');
      return false;
    }
    _setLoading(true);
    _clearError();

    try {
      final resolved = await _resolveMessage(qrContent);
      final message = await PolygonIdSdk.I.iden3comm
          .getIden3Message(message: resolved);

      switch (message.messageType) {
        case Iden3MessageType.authRequest:
          await _handleAuth(message);
          break;
        case Iden3MessageType.credentialOffer:
        case Iden3MessageType.onchainCredentialOffer:
          await _handleCredentialOffer(message);
          break;
        default:
          throw Exception(
              'Unsupported message type: ${message.messageType}');
      }
      // If _handleAuth found multiple matches it set hasPendingAuthSelection
      // without completing the auth — return false so the UI can show the picker.
      if (hasPendingAuthSelection) return false;
      return true;
    } catch (e, st) {
      _log.e('Handle QR failed', error: e, stackTrace: st);
      _setError('Failed to process QR code:\n$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate with a verifier using authenticateV2 (matches SDK example app).
  /// If the callback returns a credential offer, handle it automatically.
  /// When multiple credentials match the proof scope, sets pending selection state
  /// and returns without running auth — caller must check [hasPendingAuthSelection].
  Future<void> _handleAuth(Iden3MessageEntity message) async {
    _setMsg('Finding matching credentials...');

    // Check how many credentials match this proof request
    final matching = await PolygonIdSdk.I.iden3comm.getClaimsFromIden3Message(
      message: message,
      genesisDid: _genesisDid!,
      privateKey: _privateKey!,
    );
    final validMatching =
        matching.whereType<ClaimEntity>().toList();

    _log.d('Matching credentials for auth: ${validMatching.length}');

    if (validMatching.length > 1) {
      // Pause — let the UI show a credential picker
      _pendingAuthMessage = message;
      _pendingMatchingCredentials = validMatching;
      notifyListeners();
      return;
    }

    await _runAuthenticate(message);
  }

  /// Execute authenticateV2 directly, optionally using only [selectedCredential].
  /// If [selectedCredential] is provided, non-selected matching credentials are
  /// temporarily removed from storage so the SDK picks the right one, then restored.
  Future<void> _runAuthenticate(Iden3MessageEntity message,
      [ClaimEntity? selectedCredential]) async {
    List<ClaimEntity> removed = [];
    try {
      if (selectedCredential != null) {
        // Fetch all current matching credentials
        final allMatching =
            await PolygonIdSdk.I.iden3comm.getClaimsFromIden3Message(
          message: message,
          genesisDid: _genesisDid!,
          privateKey: _privateKey!,
        );
        // Remove everyone except the selected one
        for (final c in allMatching.whereType<ClaimEntity>()) {
          if (c.id != selectedCredential.id) {
            await PolygonIdSdk.I.credential.removeClaim(
              claimId: c.id,
              genesisDid: _genesisDid!,
              privateKey: _privateKey!,
            );
            removed.add(c);
          }
        }
      }

      _setMsg('Generating ZK proof...');
      final env = await PolygonIdSdk.I.getEnv();
      final identity = await PolygonIdSdk.I.identity.getIdentity(
        genesisDid: _genesisDid!,
        privateKey: _privateKey!,
      );

      final next = await PolygonIdSdk.I.iden3comm.authenticateV2(
        message: message,
        genesisDid: _genesisDid!,
        privateKey: _privateKey!,
        profileNonce: GENESIS_PROFILE_NONCE,
        identityEntity: identity,
        env: env,
      );
      _log.d('Auth complete — follow-up: ${next?.messageType ?? "null"}');

      if (next == null) {
        _setMsg('Auth successful — waiting for credential from issuer...');
        return;
      }

      switch (next.messageType) {
        case Iden3MessageType.credentialOffer:
        case Iden3MessageType.onchainCredentialOffer:
          await _handleCredentialOffer(next);
          break;
        default:
          _log.d('Follow-up message type ${next.messageType} — no action');
      }
    } finally {
      // Always restore any temporarily removed credentials
      if (removed.isNotEmpty) {
        try {
          await PolygonIdSdk.I.credential.saveClaims(
            claims: removed,
            genesisDid: _genesisDid!,
            privateKey: _privateKey!,
          );
          _log.d('Restored ${removed.length} temporarily removed credential(s)');
          await loadCredentials();
        } catch (e) {
          _log.e('Failed to restore credentials', error: e);
        }
      }
    }
  }

  /// Called by the UI after the user selects a credential from the picker.
  /// Completes the pending auth flow using [selected].
  Future<bool> confirmAuthWithCredential(ClaimEntity selected) async {
    if (_pendingAuthMessage == null) return false;
    _setLoading(true);
    _clearError();
    final message = _pendingAuthMessage!;
    _pendingAuthMessage = null;
    _pendingMatchingCredentials = [];
    try {
      await _runAuthenticate(message, selected);
      return true;
    } catch (e, st) {
      _log.e('Auth with selected credential failed', error: e, stackTrace: st);
      _setError('Failed to process QR code:\n$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel a pending credential-selection auth.
  void cancelPendingAuth() {
    _pendingAuthMessage = null;
    _pendingMatchingCredentials = [];
    notifyListeners();
  }

  /// Fetch credentials from an issuer via a credential offer message.
  Future<void> _handleCredentialOffer(Iden3MessageEntity message) async {
    _setMsg('Fetching credentials from issuer...');
    // SDK verifies the concrete type internally; cast is safe here
    // because messageType == credentialOffer guarantees the underlying class
    final offerMsg = message as CredentialOfferMessageEntity;
    await PolygonIdSdk.I.iden3comm.fetchAndSaveClaims(
      message: offerMsg,
      genesisDid: _genesisDid!,
      privateKey: _privateKey!,
    );
    await loadCredentials();
    _log.d('Credentials fetched and saved');
  }

  // ---- Helpers ----

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setStatus(WalletStatus s, String msg) {
    _status = s;
    _statusMessage = msg;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() => _error = null;

  void _setMsg(String msg) {
    _statusMessage = msg;
    notifyListeners();
  }
}
