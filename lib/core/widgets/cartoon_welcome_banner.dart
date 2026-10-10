import 'package:flutter/material.dart';

/// A lightweight, asset-free welcome banner that gives the dashboard a
/// friendly cartoon-adventure identity without introducing image or 3D-engine
/// dependencies. It uses only native Flutter painting and gradients.
class CartoonWelcomeBanner extends StatelessWidget {
  const CartoonWelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF765E), Color(0xFFFFA45B)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFC49B), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26E65D46),
            blurRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 54,
            top: -16,
            child: Icon(Icons.auto_awesome_rounded,
                size: 30, color: Color(0xFFFFE5A5)),
          ),
          const Positioned(
            right: 4,
            bottom: 4,
            child: Icon(Icons.circle, size: 12, color: Color(0xFFFFD36E)),
          ),
          Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9B8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'YOUR OPEN-SOURCE ADVENTURE',
                        style: TextStyle(
                          color: Color(0xFF71372D),
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Small commits.\nBig adventures.',
                      style: TextStyle(
                        color: Color(0xFF3F2425),
                        fontSize: 27,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your next contribution starts here.',
                      style: TextStyle(
                        color: Color(0xFF633B35),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (compact) const SizedBox(height: 12),
              const _CartoonContributor(),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartoonContributor extends StatelessWidget {
  const _CartoonContributor();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD36E),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF71372D), width: 3),
            ),
          ),
          Positioned(
            top: 18,
            child: Container(
              width: 66,
              height: 69,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DB),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF71372D), width: 3),
              ),
            ),
          ),
          const Positioned(
            top: 42,
            left: 36,
            child: _FaceDot(),
          ),
          const Positioned(
            top: 42,
            right: 36,
            child: _FaceDot(),
          ),
          Positioned(
            top: 58,
            child: Container(
              width: 18,
              height: 9,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF71372D), width: 3),
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 0,
            top: 3,
            child: Icon(Icons.star_rounded,
                color: Color(0xFF6C4CE8), size: 30),
          ),
          const Positioned(
            left: 0,
            bottom: 4,
            child: Icon(Icons.bolt_rounded,
                color: Color(0xFF008F86), size: 28),
          ),
        ],
      ),
    );
  }
}

class _FaceDot extends StatelessWidget {
  const _FaceDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 9,
        decoration: const BoxDecoration(
          color: Color(0xFF71372D),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      );
}
