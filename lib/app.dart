import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/passcode_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/claim_credential_screen.dart';
import 'screens/credential_detail_screen.dart';
import 'screens/credentials_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/message_detail_screen.dart';
import 'screens/passcode_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class ZKredApp extends StatelessWidget {
  const ZKredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => PasscodeProvider()),
      ],
      child: MaterialApp(
        title: 'ZKred',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/passcode': (_) => const PasscodeScreen(),
          '/home': (_) => const MainShell(),
          '/scanner': (_) => const ScannerScreen(),
          '/message-detail': (_) => const MessageDetailScreen(),
          '/claim-credential': (_) => const ClaimCredentialScreen(),
          '/credential-detail': (_) => const CredentialDetailScreen(),
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _tabs = const [
    HomeScreen(),
    InboxScreen(),
    CredentialsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ZKColors.shield,
          border: Border(
            top: BorderSide(color: ZKColors.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: ZKColors.shield,
          selectedItemColor: ZKColors.electric,
          unselectedItemColor: ZKColors.textMuted,
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              activeIcon: Icon(Icons.inbox),
              label: 'Inbox',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge),
              label: 'Credentials',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
