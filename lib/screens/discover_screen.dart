import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../models/user_model.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _influencers = [];
  List<Map<String, dynamic>> _filteredInfluencers = [];

  // Categories for filtering
  final List<String> _categories = [
    'All',
    'Fashion',
    'Beauty',
    'Fitness',
    'Tech',
    'Food',
    'Travel',
    'Gaming',
    'Lifestyle',
  ];

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    // Load mock data
    _loadMockData();
  }

  void _loadMockData() {
    // Mock data for influencers
    _influencers = [
      {
        'id': '1',
        'name': 'Emma Johnson',
        'username': '@emmastyle',
        'category': 'Fashion',
        'followers': '1.2M',
        'engagement': '3.5%',
        'bio':
            'Fashion blogger and style enthusiast. Sharing daily outfit inspirations.',
        'profilePic':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        'verified': true,
      },
      {
        'id': '2',
        'name': 'Alex Chen',
        'username': '@techwithalex',
        'category': 'Tech',
        'followers': '850K',
        'engagement': '4.2%',
        'bio':
            'Tech reviewer and gadget enthusiast. Latest tech news and reviews.',
        'profilePic':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
        'verified': true,
      },
      {
        'id': '3',
        'name': 'Sophia Martinez',
        'username': '@sophiabeauty',
        'category': 'Beauty',
        'followers': '2.1M',
        'engagement': '5.0%',
        'bio':
            'Makeup artist and beauty influencer. Tutorials and product reviews.',
        'profilePic':
            'https://images.unsplash.com/photo-1531123897727-8f129e1688ce',
        'verified': true,
      },
      {
        'id': '4',
        'name': 'Marcus Wilson',
        'username': '@fitnesswithmarcus',
        'category': 'Fitness',
        'followers': '950K',
        'engagement': '4.8%',
        'bio':
            'Personal trainer and fitness coach. Workout tips and nutrition advice.',
        'profilePic':
            'https://images.unsplash.com/photo-1504257432389-52343af06ae3',
        'verified': false,
      },
      {
        'id': '5',
        'name': 'Olivia Kim',
        'username': '@oliviaeats',
        'category': 'Food',
        'followers': '1.5M',
        'engagement': '3.9%',
        'bio':
            'Food blogger and recipe developer. Delicious recipes and restaurant reviews.',
        'profilePic':
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f',
        'verified': true,
      },
      {
        'id': '6',
        'name': 'David Thompson',
        'username': '@traveldavid',
        'category': 'Travel',
        'followers': '1.8M',
        'engagement': '3.2%',
        'bio':
            'Travel photographer and adventurer. Exploring the world one country at a time.',
        'profilePic':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        'verified': true,
      },
      {
        'id': '7',
        'name': 'Mia Rodriguez',
        'username': '@gamingwithmia',
        'category': 'Gaming',
        'followers': '2.5M',
        'engagement': '6.1%',
        'bio': 'Professional gamer and streamer. Gaming tips and live streams.',
        'profilePic':
            'https://images.unsplash.com/photo-1534751516642-a1af1ef26a56',
        'verified': true,
      },
      {
        'id': '8',
        'name': 'James Wilson',
        'username': '@jamesfitness',
        'category': 'Fitness',
        'followers': '780K',
        'engagement': '4.5%',
        'bio':
            'Fitness coach and nutrition expert. Helping you achieve your fitness goals.',
        'profilePic':
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d',
        'verified': false,
      },
      {
        'id': '9',
        'name': 'Lily Wang',
        'username': '@lilystyle',
        'category': 'Fashion',
        'followers': '1.1M',
        'engagement': '3.8%',
        'bio':
            'Fashion designer and style influencer. Creating trends and sharing fashion tips.',
        'profilePic':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        'verified': true,
      },
      {
        'id': '10',
        'name': 'Ryan Park',
        'username': '@techwithryan',
        'category': 'Tech',
        'followers': '920K',
        'engagement': '4.0%',
        'bio':
            'Software engineer and tech enthusiast. Coding tutorials and tech reviews.',
        'profilePic':
            'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79',
        'verified': false,
      },
    ];

    // Initialize filtered list with all influencers
    _filteredInfluencers = List.from(_influencers);
  }

  void _filterInfluencers() {
    setState(() {
      if (_searchQuery.isEmpty && _selectedCategory == 'All') {
        _filteredInfluencers = List.from(_influencers);
      } else {
        _filteredInfluencers =
            _influencers.where((influencer) {
              final nameMatches =
                  influencer['name'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  influencer['username'].toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );

              final categoryMatches =
                  _selectedCategory == 'All' ||
                  influencer['category'] == _selectedCategory;

              return nameMatches && categoryMatches;
            }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      'Discover',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          // Show filter options
                        },
                        iconSize: 28,
                      ),
                      const SizedBox(width: 8),
                    ],
                    systemOverlayStyle: SystemUiOverlayStyle.light,
                  ),

                  // Search bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search influencers...',
                                prefixIcon: const Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon:
                                    _searchQuery.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                              _filterInfluencers();
                                            });
                                          },
                                        )
                                        : null,
                              ),
                              style: const TextStyle(fontSize: 16),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                  _filterInfluencers();
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Categories
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                  _filterInfluencers();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Results count
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        '${_filteredInfluencers.length} influencers found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),

                  // Influencer list
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final influencer = _filteredInfluencers[index];
                      return _buildInfluencerCard(context, influencer);
                    }, childCount: _filteredInfluencers.length),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfluencerCard(
    BuildContext context,
    Map<String, dynamic> influencer,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: GestureDetector(
        onTap: () {
          // Navigate to influencer profile
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Profile image
                    Hero(
                      tag: 'profile-${influencer['id']}',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(
                              '${influencer['profilePic']}?w=200&h=200&fit=crop&crop=faces',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Influencer info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and verification
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  influencer['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (influencer['verified'] == true)
                                Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),

                          // Username
                          Text(
                            influencer['username'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Category and metrics
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  influencer['category'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.people,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                influencer['followers'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.trending_up,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                influencer['engagement'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Bio
                          Text(
                            influencer['bio'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
}
