import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF0F5),
              Color(0xFFE6F7FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),

                  _buildStoryCard(),
                  const SizedBox(height: 25),

                  _buildTeamSection(),
                  const SizedBox(height: 25),

                  _buildValuesSection(),
                  const SizedBox(height: 25),

                  _buildContactCard(),
                  const SizedBox(height: 20),

                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4EC),
                borderRadius: BorderRadius.circular(70),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                size: 70,
                color: Color(0xFFFF6B9D),
              ),
            ),
            Positioned(
              top: 10,
              right: 30,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.star,
                  size: 20,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 30,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: const Icon(
                  Icons.star,
                  size: 16,
                  color: Color(0xFF00CED1),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'About ',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B9D),
                  fontFamily: 'ComicNeue',
                ),
              ),
              TextSpan(
                text: 'Me',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A5ACD),
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '🌸 Where Skincare Meets Happiness 🌸',
          style: TextStyle(
            fontSize: 16,
            color: Colors.purple[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFF0F5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.bookmark_added,
                  color: Color(0xFFFF6B9D),
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'My Cute Story ✨',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B9D),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 15),

              Expanded(
                child: Text(
                  "Once upon a time... a skincare lover decided that taking care of your skin should feel like a fun self-care party, not a boring chore! 🎉\n"
                  "\nI believe every skincare routine deserves a sprinkle of joy, a dash of cuteness, and lots of happy vibes! My mission? To make you smile every time you open my app - because glowing skin starts with a happy heart! 💖\n"
                  "\nI\'m not just about products; I'm about creating moments of self-love and confidence that make you go ‘Aww, I feel amazing!’ 🌟",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Center(
            child: Container(
              height: 3,
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFB6C1),
                    const Color(0xFFFF69B4),
                    const Color(0xFFFFB6C1),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    final List<Map<String, dynamic>> teamMembers = [
      {
        'emoji': '👸',
        'name': 'Cute CEO',
        'role': 'Chief Enthusiasm Officer',
        'color': Color(0xFFFFF0F5),
        'funFact': 'Can identify skincare by smell! 👃✨',
      },
      {
        'emoji': '🧚‍♀️',
        'name': 'Fairy Dev',
        'role': 'Code Magician',
        'color': Color(0xFFF0F8FF),
        'funFact': 'Makes bugs disappear like magic! 🪄',
      },
      {
        'emoji': '🎨',
        'name': 'Design Unicorn',
        'role': 'Pixel Perfectionist',
        'color': Color(0xFFF5F0FF),
        'funFact': 'Thinks in pastel colors! 🦄',
      },
      {
        'emoji': '🧸',
        'name': 'Customer Bear',
        'role': 'Happiness Helper',
        'color': Color(0xFFFFF8E1),
        'funFact': 'Sends virtual hugs with every reply! 🤗',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text(
            'Meet Dea\'s Cute Team 🎀',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A5ACD),
            ),
          ),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: teamMembers.length,
            itemBuilder: (context, index) {
              final member = teamMembers[index];
              return Container(
                width: 150,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 10,
                  right: index == teamMembers.length - 1 ? 0 : 10,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  color: member['color'] as Color,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              member['emoji'],
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          member['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          member['role'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[600],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            member['funFact'],
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValuesSection() {
    final List<Map<String, dynamic>> values = [
      {
        'icon': Icons.favorite,
        'title': 'Self-Love First 💝',
        'description': 'Because you deserve to feel amazing every day!',
        'color': Color(0xFFFFE4E6),
      },
      {
        'icon': Icons.emoji_emotions,
        'title': 'Joyful Experience 😊',
        'description': 'Skincare should make you smile, not stress!',
        'color': Color(0xFFFFF4E6),
      },
      {
        'icon': Icons.spa,
        'title': 'Gentle Care 🌱',
        'description': 'Like a soft hug for your skin!',
        'color': Color(0xFFE6FFFA),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text(
            'My Cute Values 🌈',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B9D),
            ),
          ),
        ),

        const SizedBox(height: 15),

        ...values.map((value) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: value['color'] as Color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        value['icon'] as IconData,
                        color: const Color(0xFFFF6B9D),
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            value['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF0F5),
            const Color(0xFFF0F8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail, color: Color(0xFFFF6B9D)),
              SizedBox(width: 10),
              Text(
                'Say Hello! 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A5ACD),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'I\'d love to hear from you! Whether you have questions, feedback, or just want to share your skincare journey with me - I\'m all ears! 👂💕',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 25),

          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              _buildContactButton(
                icon: Icons.email,
                label: 'Email me',
                color: Color(0xFFFF6B9D),
                onTap: () {},
              ),
              _buildContactButton(
                icon: Icons.phone,
                label: 'Call Us',
                color: Color(0xFF6A5ACD),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton('🌸', Color(0xFFFFB6C1)),
              const SizedBox(width: 15),
              _buildSocialButton('✨', Color(0xFFFFD700)),
              const SizedBox(width: 15),
              _buildSocialButton('🐰', Color(0xFF87CEEB)),
              const SizedBox(width: 15),
              _buildSocialButton('🍦', Color(0xFFFFA07A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(String emoji, Color bgColor) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22.5),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(const Color(0xFFFFB6C1)),
            const SizedBox(width: 8),
            _buildDot(const Color(0xFFFFD700)),
            const SizedBox(width: 8),
            _buildDot(const Color(0xFF87CEEB)),
            const SizedBox(width: 8),
            _buildDot(const Color(0xFF98FB98)),
            const SizedBox(width: 8),
            _buildDot(const Color(0xFFDDA0DD)),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          'Made with 💖 and lots of cute vibes!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '© 2025 Skincare Cute App • All the happy rights reserved!',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),

        const SizedBox(height: 5),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🌟 ',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Stay Glowy!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.pink[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' 🌟',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}