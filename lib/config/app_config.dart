import 'package:polygonid_flutter_sdk/common/domain/entities/chain_config_entity.dart';
import 'package:polygonid_flutter_sdk/common/domain/entities/env_entity.dart';

// Network configuration for Privado ID on Polygon Amoy testnet.
// See https://docs.privado.id for updated contract addresses and network details.
class AppConfig {
  // Chain details (used for DID generation and chain config)
  static const String blockchain = 'polygon';
  static const String network = 'amoy';
  static const String chainId = '80002'; // Polygon Amoy chain ID

  // Amoy RPC
  static const String rpcUrl = 'https://rpc-amoy.polygon.technology/';

  // Privado ID state contract on Polygon Amoy testnet
  static const String stateContractAddr =
      '0x1a4cC30f2aA0377b0c3bc9848766D90cb4404124';

  // Public IPFS gateway (no auth needed for schema lookups in POC)
  static const String ipfsUrl = 'https://ipfs.io';

  // Privado ID push notification service
  static const String pushUrl = 'https://push-staging.polygonid.com/api/v1';

  // Combined V2+V3 circuit zip from circuits.privado.id (replaces dead circuits.polygonid.me)
  static const String circuitsBucketUrl =
      'https://circuits.privado.id/v1.0.1/keys.zip';

  // Secure storage keys
  static const String keyPrivateKey = 'zkred_private_key';
  static const String keyGenesisDid = 'zkred_genesis_did';

  /// Build the EnvEntity for SDK initialization
  // 32-byte key to unlock SDK internal stacktrace (debug only)
  static const String stacktraceKey = 'zkred-debug-trace-key-32bytesXXX';

  static EnvEntity buildEnv() {
    return EnvEntity(
      pushUrl: pushUrl,
      ipfsUrl: ipfsUrl,
      stacktraceEncryptionKey: stacktraceKey,
      chainConfigs: {
        chainId: ChainConfigEntity(
          blockchain: blockchain,
          network: network,
          rpcUrl: rpcUrl,
          stateContractAddr: stateContractAddr,
        ),
      },
      didMethods: const [],
    );
  }
}
