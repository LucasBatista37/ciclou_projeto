import 'package:ciclou_projeto/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectorStatsScreen extends StatefulWidget {
  final String collectorId;
  final UserModel user;

  const CollectorStatsScreen({
    super.key,
    required this.collectorId,
    required this.user,
  });

  @override
  State<CollectorStatsScreen> createState() => _CollectorStatsScreenState();
}

class _CollectorStatsScreenState extends State<CollectorStatsScreen> {
  late Future<DocumentSnapshot> _collectorData;

  @override
  void initState() {
    super.initState();
    _collectorData = FirebaseFirestore.instance
        .collection('collector')
        .doc(widget.collectorId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 76, 175, 80),
        centerTitle: true,
        title: const Text(
          'Estatísticas do Coletor',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _collectorData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Erro ao carregar dados do coletor.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int totalLiters = (data['amountOil'] ?? 0).toDouble().toInt();

          double oilPerMonth = totalLiters / 12;
          double oilPerDay = totalLiters / 365;
          double savedWater = totalLiters * 1000;
          double avoidedCO2 = totalLiters * 5.24;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(totalLiters),
                  const SizedBox(height: 16),
                  _buildStatRow(oilPerMonth, oilPerDay),
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

  Widget _buildHeaderCard(int totalLiters) {
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
            'Total de Óleo Coletado',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalLiters Litros',
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

  Widget _buildStatRow(double oilPerMonth, double oilPerDay) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Média Mensal',
              '${oilPerMonth.toStringAsFixed(2)} Litros', Colors.blue.shade400),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Média Diária',
              '${oilPerDay.toStringAsFixed(2)} Litros', Colors.orange.shade400),
        ),
      ],
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
            'Os dados apresentados refletem as estatísticas atuais do coletor, considerando o volume total coletado e os impactos ambientais associados. Continue seu excelente trabalho! ❤️',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}