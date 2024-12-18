import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequesterStatsScreen extends StatefulWidget {
  final String userId;

  const RequesterStatsScreen({super.key, required this.userId});

  @override
  State<RequesterStatsScreen> createState() => _RequesterStatsScreenState();
}

class _RequesterStatsScreenState extends State<RequesterStatsScreen> {
  late Future<double> _totalOilCollected;

  @override
  void initState() {
    super.initState();
    _totalOilCollected = _calculateTotalOilCollected();
  }

  Future<double> _calculateTotalOilCollected() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('coletas')
          .where('userId', isEqualTo: widget.userId)
          .get();

      double totalOil = 0.0;

      print('Documentos retornados: ${querySnapshot.docs.length}');

      for (var doc in querySnapshot.docs) {
        // Verifica se o campo existe antes de tentar acessá-lo
        if (doc.data().containsKey('quantidadeReal')) {
          totalOil += double.tryParse(doc['quantidadeReal'].toString()) ?? 0.0;
        } else {
          print('Documento ${doc.id} não possui o campo "quantidadeReal".');
        }
      }

      print('Total de óleo coletado: $totalOil');
      return totalOil;
    } catch (e) {
      print('Erro ao calcular o total de óleo: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 76, 175, 80),
        centerTitle: true,
        title: const Text(
          'Estatísticas do Solicitante',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<double>(
        future: _totalOilCollected,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar estatísticas.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          final totalLiters = snapshot.data ?? 0.0;
          final double savedWater = totalLiters * 1000;
          final double avoidedCO2 = totalLiters * 5.24;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(totalLiters),
                  const SizedBox(height: 16),
                  _buildImpactCard(savedWater),
                  const SizedBox(height: 16),
                  _buildCO2Card(avoidedCO2),
                  const SizedBox(height: 16),
                  _buildSummarySection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(double totalLiters) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 83, 190, 88),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total de Óleo Enviado',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalLiters.toStringAsFixed(1)} Litros',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(double savedWater) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade500,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Água Preservada',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${savedWater.toStringAsFixed(0)} Litros',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCO2Card(double avoidedCO2) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emissões Evitadas de CO₂',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${avoidedCO2.toStringAsFixed(2)} Kg',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo Geral',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Os dados apresentados refletem as estatísticas atuais do solicitante, considerando o volume total enviado e os impactos ambientais associados.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
