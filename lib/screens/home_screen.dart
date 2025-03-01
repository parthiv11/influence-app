import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Initialize slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuint),
    );

    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'Influence',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        centerTitle: false,
                        titlePadding: const EdgeInsets.only(
                          left: 20,
                          bottom: 16,
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {},
                          iconSize: 28,
                        ),
                        const SizedBox(width: 8),
                      ],
                      systemOverlayStyle: SystemUiOverlayStyle.light,
                    ),

                    // Welcome section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<UserModel?>(
                              future: authService.ensureUserProfileExists(),
                              builder: (context, snapshot) {
                                String name = "there";
                                if (snapshot.hasData && snapshot.data != null) {
                                  name = snapshot.data!.name.split(' ').first;
                                }
                                return Text(
                                  'Hello, $name',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find your perfect influencer match today',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Featured animation
                    SliverToBoxAdapter(
                      child: Container(
                        height: 300,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Animated background
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                          ],
                                        ),
                                      ),
                                      child: CustomPaint(
                                        painter: BubblePainter(
                                          animation: _pulseController,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Animated icons
                              Positioned(
                                top: 40,
                                left: 30,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 100,
                                right: 40,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          1.1 - (_pulseAnimation.value - 1.0),
                                      child: Icon(
                                        Icons.thumb_up,
                                        size: 36,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: 80,
                                left: 50,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          1.05 +
                                          (_pulseAnimation.value - 1.0) * 0.5,
                                      child: Icon(
                                        Icons.star,
                                        size: 48,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Frosted glass overlay
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: ClipRRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      color: Colors.black.withOpacity(0.3),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Discover Top Influencers',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Connect with creators who match your brand',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Quick actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildQuickActionCard(
                                  context,
                                  icon: Icons.search,
                                  title: 'Discover',
                                  onTap: () {
                                    Navigator.pushNamed(context, '/discover');
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildQuickActionCard(
                                  context,
                                  icon: Icons.message_outlined,
                                  title: 'Messages',
                                  onTap: () {
                                    Navigator.pushNamed(context, '/chat');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildQuickActionCard(
                                  context,
                                  icon: Icons.person_outline,
                                  title: 'Profile',
                                  onTap: () {
                                    Navigator.pushNamed(context, '/profile');
                                  },
                                ),
                                const SizedBox(width: 16),
                                _buildQuickActionCard(
                                  context,
                                  icon: Icons.trending_up,
                                  title: 'Analytics',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recent activity
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Activity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildActivityItem(
                              context,
                              icon: Icons.star_outline,
                              title: 'New influencers available',
                              subtitle: 'Check out the latest additions',
                              time: '2h ago',
                            ),
                            const SizedBox(height: 12),
                            _buildActivityItem(
                              context,
                              icon: Icons.notifications_active_outlined,
                              title: 'Profile views increased',
                              subtitle: 'Your profile is getting attention',
                              time: '1d ago',
                            ),
                            const SizedBox(height: 12),
                            _buildActivityItem(
                              context,
                              icon: Icons.update,
                              title: 'App updated',
                              subtitle: 'New features available',
                              time: '2d ago',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for animated bubbles
class BubblePainter extends CustomPainter {
  final Animation animation;
  final Color color;

  BubblePainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw animated circles
    final circleCount = 12;
    for (int i = 0; i < circleCount; i++) {
      final progress = (i / circleCount) + animation.value * 0.2;
      final modProgress = progress % 1.0;

      final x = size.width * (0.2 + 0.6 * i / circleCount);
      final y = size.height * (0.2 + 0.6 * modProgress);
      final radius = size.width * 0.05 * (1 + animation.value * 0.2);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
