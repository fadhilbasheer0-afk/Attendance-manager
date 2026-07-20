import 'package:url_launcher/url_launcher.dart';

const kAbsentAlertMessage =
    "Dear Parent, your child was absent for today's tuition class.";

Future<bool> openWhatsAppAbsentAlert(String phoneE164OrLocal) async {
  return openWhatsAppMessage(phoneE164OrLocal, kAbsentAlertMessage);
}

Future<bool> openWhatsAppMessage(
    String phoneE164OrLocal, String message) async {
  final digits = phoneE164OrLocal.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;
  final uri = Uri.parse(
    'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
