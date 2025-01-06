import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:developer' as developer;

class CertificadoService {
  static Future<void> gerarCertificado({
    required Map<String, dynamic> coletaData,
    required String coletaId,
    required double quantidadeReal,
  }) async {
    try {
      final templatePdf = await rootBundle.load('assets/certificado.png');

      final fontData =
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
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
                    '${coletaData['cnpj'] ?? 'N/A'}',
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
                    '${DateTime.now().toString().split(' ')[0]}',
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file =
          File('${directory.path}/certificado_$coletaId.pdf');
      await file.writeAsBytes(await outputPdf.save());

      await FirebaseFirestore.instance
          .collection('certificados')
          .doc(coletaId)
          .set({
        'coletaId': coletaId,
        'userId': coletaData['userId'],
        'collectorId': FirebaseAuth.instance.currentUser?.uid,
        'requestorName': coletaData['requestorName'],
        'filePath': file.path,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      developer.log("Erro ao gerar certificado: $e",
          error: e, stackTrace: stack);
      throw Exception("Erro ao gerar certificado: $e");
    }
  }
}
