import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_storage/firebase_storage.dart';

class CertificadoService {
  static Future<void> gerarCertificado({
    required Map<String, dynamic> coletaData,
    required String coletaId,
    required double quantidadeReal,
  }) async {
    try {
      if (!coletaData.containsKey('cnpj') || coletaData['cnpj'] == null) {
        throw Exception('CNPJ não está presente nos dados da coleta.');
      }
      if (quantidadeReal <= 0) {
        throw Exception('Quantidade real inválida: $quantidadeReal');
      }

      final templatePdf = await rootBundle.load('assets/certificado.png');

      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      final outputPdf = pw.Document();
      final pdfImage = pw.MemoryImage(templatePdf.buffer.asUint8List());

      outputPdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(792, 612),
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Stack(
              children: [
                pw.Image(pdfImage, fit: pw.BoxFit.cover),
                pw.Positioned(
                  left: 125,
                  top: 272,
                  child: pw.Text(
                    '${coletaData['tipoEstabelecimento'] ?? 'N/A'}',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
                pw.Positioned(
                  left: 99.5,
                  top: 314.2,
                  child: pw.Text(
                    '${coletaData['document'] ?? 'N/A'}',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
                pw.Positioned(
                  left: 260,
                  top: 360,
                  child: pw.Text(
                    '${quantidadeReal.toStringAsFixed(2)} L',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
                pw.Positioned(
                  left: 390,
                  top: 360,
                  child: pw.Text(
                    DateTime.now().toString().split(' ')[0],
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final localFile = File('${directory.path}/certificado_$coletaId.pdf');
      await localFile.writeAsBytes(await outputPdf.save());

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('certificados')
          .child('$coletaId.pdf');

      final uploadTask = await storageRef.putFile(localFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('certificados')
          .doc(coletaId)
          .set({
        'coletaId': coletaId,
        'userId': coletaData['userId'],
        'collectorId': FirebaseAuth.instance.currentUser?.uid,
        'requestorName': coletaData['requestorName'],
        'downloadUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await localFile.delete();
    } catch (e) {
      throw Exception("Erro ao gerar certificado: $e");
    }
  }
}
