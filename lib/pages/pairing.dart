import 'package:flutter/material.dart';

class IngredientPairingPage extends StatelessWidget {
  const IngredientPairingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ingredient Pairing Guide",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo[300]!, Colors.indigo[500]!],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.science,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ingredient Combinations & Safe Pairings",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[800],
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Master the art of skincare chemistry",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red[200]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Some ingredient combinations can cause irritation or reduce effectiveness",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _sectionTitle(
                "🚫 Combinations to Avoid",
                Colors.red,
              ),
              _pairingCard(
                title: "Retinol + AHA/BHA",
                type: "DANGEROUS",
                icon: Icons.block,
                color: Colors.red[300]!,
                content:
                "Both exfoliate deeply and may cause dryness, peeling, and irritation when used together. Use on alternate nights instead.",
                tips: "Alternate nights • Start slowly",
              ),
              _pairingCard(
                title: "Vitamin C + Retinol",
                type: "NOT RECOMMENDED",
                icon: Icons.do_not_disturb,
                color: Colors.orange[700]!,
                content:
                "They require different pH levels and may become unstable when layered together. Use Vitamin C in the morning and Retinol at night.",
                tips: "AM/PM separation",
              ),
              _pairingCard(
                title: "Vitamin C + AHA/BHA",
                type: "IRRITATING",
                icon: Icons.sentiment_very_dissatisfied,
                color: Colors.orange[300]!,
                content:
                "Both are acidic and may increase redness or stinging. Use separately.",
                tips: "Space out usage",
              ),
              _pairingCard(
                title: "Retinol + Benzoyl Peroxide",
                type: "DANGEROUS",
                icon: Icons.block,
                color: Colors.red[300]!,
                content:
                "May deactivate each other and cause irritation. Use on different days or follow dermatologist guidance.",
                tips: "Different days • Consult professional",
              ),

              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[50]!,
                      Colors.teal[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green[200]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "These combinations are generally safe and effective",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _sectionTitle(
                "✅ Safe and Effective Combinations",
                Colors.green,
              ),
              _pairingCard(
                title: "Retinol + Moisturizer",
                type: "RECOMMENDED",
                icon: Icons.favorite,
                color: Colors.green[300]!,
                content:
                "Helps minimize irritation, strengthen barrier, and improve comfort during retinol use.",
                tips: "Always buffer • Reduce irritation",
              ),
              _pairingCard(
                title: "Vitamin C + Sunscreen",
                type: "POWER COMBO",
                icon: Icons.wb_sunny,
                color: Colors.yellow[400]!,
                content:
                "Great morning pairing that protects skin from free radicals and supports brightness.",
                tips: "Daily AM routine",
              ),
              _pairingCard(
                title: "Niacinamide + Most Actives",
                type: "VERSATILE",
                icon: Icons.handshake,
                color: Colors.blue[300]!,
                content:
                "Works well with retinol, HA, AHA/BHA, and stable Vitamin C. Helps soothe and support the barrier.",
                tips: "Universal pairing • Calming",
              ),
              _pairingCard(
                title: "HA + AHA/BHA",
                type: "BALANCED",
                icon: Icons.balance,
                color: Colors.purple[300]!,
                content:
                "Hydrates the skin after exfoliation and reduces tightness or dryness.",
                tips: "Hydrate after exfoliation",
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.indigo[50]!,
                      Colors.purple[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.indigo[200]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services,
                            color: Colors.indigo,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Professional Guidance",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "This pairing guide serves as additional insight from our website. Every skin condition is unique, and tolerance varies from person to person. If you are new to active ingredients or have sensitive skin, please consult a dermatologist before combining strong actives.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Consult a professional for personalized advice"),
                            backgroundColor: Colors.indigo,
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_search, size: 20),
                      label: const Text("Seek Professional Advice"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 15),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pairingCard({
    required String title,
    required String type,
    required IconData icon,
    required Color color,
    required String content,
    required String tips,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700]!,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tip: $tips",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}