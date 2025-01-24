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
      print('Iniciando geração de certificado para coletaId: $coletaId');
      print('Dados da coleta recebidos: $coletaData');
      print('Quantidade real: $quantidadeReal');

      // Validar dados necessários
      if (!coletaData.containsKey('cnpj') || coletaData['cnpj'] == null) {
        throw Exception('CNPJ não está presente nos dados da coleta.');
      }
      if (quantidadeReal <= 0) {
        throw Exception('Quantidade real inválida: $quantidadeReal');
      }

      // Carregar recursos
      print('Carregando template do certificado...');
      final templatePdf = await rootBundle.load('assets/certificado.png');

      print('Carregando fonte...');
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final ttf = pw.Font.ttf(fontData.buffer.asByteData());

      // Criar o PDF
      print('Criando o PDF...');
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
                    DateTime.now().toString().split(' ')[0],
                    style: pw.TextStyle(font: ttf, fontSize: 18),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Salvar o PDF localmente
      print('Salvando o PDF localmente...');
      final directory = await getApplicationDocumentsDirectory();
      final localFile = File('${directory.path}/certificado_$coletaId.pdf');
      await localFile.writeAsBytes(await outputPdf.save());

      print('PDF salvo com sucesso: ${localFile.path}');

      // Upload do PDF para o Firebase Storage
      print('Fazendo upload do PDF para o Firebase Storage...');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('certificados')
          .child('$coletaId.pdf');

      final uploadTask = await storageRef.putFile(localFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('Upload concluído. URL de download: $downloadUrl');

      // Salvar informações no Firestore
      print('Salvando informações do certificado no Firestore...');
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

      print('Certificado salvo no Firestore com sucesso.');

      // Excluir arquivo local
      await localFile.delete();
      print('Arquivo local excluído.');
    } catch (e) {
      print('Erro ao gerar certificado: $e');
      throw Exception("Erro ao gerar certificado: $e");
    }
  }
}
