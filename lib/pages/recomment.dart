import 'package:flutter/material.dart';

class RecommendedIngredientsPage extends StatelessWidget {
  const RecommendedIngredientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recommended Ingredients",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink[700],
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
              Colors.pink.shade50,
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
                      color: Colors.pink.withOpacity(0.1),
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
                        color: Colors.pink[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.spa,
                        size: 35,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Recommended Ingredients for Your Skin Concerns",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink[800],
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Find the perfect match for your skin needs",
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

              _sectionTitle(
                "🌞 Skin Dullness and Uneven Tone",
                Colors.orange,
              ),
              _ingredientCard(
                title: "Vitamin C",
                emoji: "🍊",
                color: Colors.orange[200]!,
                content:
                "Helps brighten the skin, fade dark spots, improve overall tone, and protect from free radicals. Best used in the morning followed by sunscreen.",
              ),
              _ingredientCard(
                title: "Niacinamide",
                emoji: "✨",
                color: Colors.blue[200]!,
                content:
                "Reduces discoloration, improves redness, balances oil, and strengthens the skin barrier. Suitable for most skin types.",
              ),

              _sectionTitle(
                "🌿 Sensitive or Irritated Skin",
                Colors.green,
              ),
              _ingredientCard(
                title: "Centella Asiatica (Cica)",
                emoji: "🌱",
                color: Colors.green[200]!,
                content:
                "Calms irritation, reduces inflammation, and supports skin healing.",
              ),
              _ingredientCard(
                title: "Ceramides",
                emoji: "🛡️",
                color: Colors.purple[200]!,
                content:
                "Strengthen the skin barrier, restore moisture, and reduce sensitivity.",
              ),
              _ingredientCard(
                title: "Hyaluronic Acid (HA)",
                emoji: "💧",
                color: Colors.blue[200]!,
                content:
                "Hydrates and keeps skin plump. Works well for sensitive or dry skin.",
              ),

              _sectionTitle(
                "⚡ Oily, Congested, or Acne-Prone Skin",
                Colors.red,
              ),
              _ingredientCard(
                title: "Salicylic Acid (BHA)",
                emoji: "🌀",
                color: Colors.red[200]!,
                content:
                "Cleans inside pores, reduces blackheads, and controls excess oil.",
              ),
              _ingredientCard(
                title: "Benzoyl Peroxide",
                emoji: "🎯",
                color: Colors.red[200]!,
                content:
                "Targets acne-causing bacteria and reduces active breakouts. Strong and may cause dryness.",
              ),
              _ingredientCard(
                title: "Niacinamide",
                emoji: "⚖️",
                color: Colors.blue[200]!,
                content:
                "Helps oil control and calms inflamed skin.",
              ),

              _sectionTitle(
                "🌟 Early Signs of Aging",
                Colors.purple,
              ),
              _ingredientCard(
                title: "Retinol / Retinoids",
                emoji: "🔄",
                color: Colors.purple[200]!,
                content:
                "Increase cell turnover, improve texture, soften fine lines, and boost collagen. Best used at night with moisturizer.",
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink[50]!,
                      Colors.orange[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange[200]!,
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
                            color: Colors.orange[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Important Reminder",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "This information is provided as additional insight from our website to help you understand commonly used skincare ingredients. Every skin type reacts differently. For safe and personalized guidance, please consult a dermatologist or medical professional before starting any active ingredients.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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
      margin: const EdgeInsets.only(top: 25, bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientCard({
    required String title,
    required String emoji,
    required Color color,
    required String content,
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
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