import 'package:ciclou_projeto/components/generate_payment_screen.dart';
import 'package:ciclou_projeto/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> generateSolicitantePixPayment({
  required String amount,
  required UserModel user,
  required String documentId,
  required String proposalId,
}) async {
  await generateFixedPixPayment(
    amount: amount,
    user: user,
    documentId: documentId,
    proposalId: proposalId,
    payerEmail: user.email
  );

  await FirebaseFirestore.instance
      .collection('coletas')
      .doc(documentId)
      .collection('propostas')
      .doc(proposalId)
      .update({
    'qrCodeSolicitante': 'Valor do QR Code do solicitante',
    'qrCodeTextSolicitante': 'Texto associado ao QR Code',
    'statusSolicitante': 'Pendente',
  });
}