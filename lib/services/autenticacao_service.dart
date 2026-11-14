
import 'package:local_auth/local_auth.dart';

class AutenticacaoService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> autenticar() async {
    try {
      final bool possuiBiometria =
      await _auth.canCheckBiometrics;

      final bool dispositivoSuportado =
      await _auth.isDeviceSupported();

      if (!possuiBiometria || !dispositivoSuportado) {
        return false;
      }

      final biometrias =
      await _auth.getAvailableBiometrics();

      if (biometrias.isEmpty) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason:
        'Confirme sua identidade para acessar seus lembretes.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      return false;
    }
  }
}
