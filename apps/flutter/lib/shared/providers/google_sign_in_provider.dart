import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb
        ? const String.fromEnvironment(
            'GOOGLE_WEB_CLIENT_ID',
            defaultValue:
                '520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com',
          )
        : null,
    serverClientId: kIsWeb
        ? null
        : const String.fromEnvironment(
            'GOOGLE_WEB_CLIENT_ID',
            defaultValue:
                '520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com',
          ),
  );
});
