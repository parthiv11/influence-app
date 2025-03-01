import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final FirestoreService _firestoreService;
  late final AuthService _authService;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  bool isLoading = true;
  UserModel userData = UserModel(uid: ''); // Initialize with a default value
  Map<String, dynamic> metrics = {};
  List<String> linkedAccounts = [];

  late TabController _tabController;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    websiteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String? userId = _authService.currentUserId;
      if (userId != null) {
        print('DEBUG: Loading profile for user $userId');

        // Ensure user profile exists in Firestore
        final UserModel? ensuredUser =
            await _authService.ensureUserProfileExists();
        if (ensuredUser != null) {
          print('DEBUG: User profile ensured/created successfully');
          setState(() {
            userData = ensuredUser;
            nameController.text = ensuredUser.name;
            bioController.text = ensuredUser.bio;
            websiteController.text = ensuredUser.website;

            // Extract linked accounts - safely handle null or incorrect types
            if (ensuredUser.socialAccounts != null) {
              linkedAccounts = List<String>.from(
                ensuredUser.socialAccounts!.keys,
              );
            } else {
              linkedAccounts = [];
            }

            // Load metrics - safely handle null or incorrect types
            if (ensuredUser.metrics != null) {
              metrics = Map<String, dynamic>.from(ensuredUser.metrics!);
            } else {
              metrics = {
                'totalFollowers': 0,
                'engagementRate': 0.0,
                'lastUpdated': DateTime.now().toIso8601String(),
              };
            }

            isLoading = false;
          });
          print('DEBUG: User profile loaded successfully');
        } else {
          print('DEBUG: User profile could not be ensured/created');
          setState(() {
            isLoading = false;
          });
          // Show a snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not load or create user profile. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('DEBUG: No current user ID available');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR loading user data: $e');
      setState(() {
        isLoading = false;
      });
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85, // Reduced quality to improve upload speed
    );

    if (image != null) {
      setState(() {
        isLoading = true;
      });

      try {
        print('DEBUG: Starting profile image upload');
        // Show a quick loading message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploading image...')));

        final String imageUrl = await _firestoreService.uploadProfileImage(
          image,
        );

        if (imageUrl.isNotEmpty) {
          print('DEBUG: Image uploaded successfully: $imageUrl');

          // No need to update UserModel first - the uploadProfileImage already updates Firestore
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the user data to display the new image
          await _loadUserData();
        }
      } catch (e) {
        print('ERROR uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final String? userId = _authService.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to save profile'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print('DEBUG: Starting profile update');

      // Get updated values from controllers
      final String name = nameController.text.trim();
      final String bio = bioController.text.trim();
      final String website = websiteController.text.trim();

      // Basic validation
      if (name.isEmpty) {
        throw Exception('Name cannot be empty');
      }

      print('DEBUG: Updating user model with new values');

      // Direct update to Firestore with only the changed fields
      final Map<String, dynamic> updates = {};

      if (name != userData.name) updates['name'] = name;
      if (bio != userData.bio) updates['bio'] = bio;
      if (website != userData.website) updates['website'] = website;

      if (updates.isNotEmpty) {
        print('DEBUG: Saving changes to Firestore: $updates');
        await _firestoreService.updateUserField(userId, 'name', name);
        await _firestoreService.updateUserField(userId, 'bio', bio);
        await _firestoreService.updateUserField(userId, 'website', website);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('DEBUG: No changes detected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Refresh user data
      await _loadUserData();
      print('DEBUG: Profile data refreshed');
    } catch (e) {
      print('ERROR saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _signOut() async {
    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      print('DEBUG: Starting sign out process');

      // Save a reference to the ScaffoldMessenger before navigation
      final scaffoldMsg = ScaffoldMessenger.of(context);

      // Sign out of all services
      try {
        await _googleSignIn.signOut();
        print('DEBUG: Google sign out complete');
      } catch (e) {
        print('DEBUG: Google sign out error: $e');
      }

      try {
        await FacebookAuth.instance.logOut();
        print('DEBUG: Facebook sign out complete');
      } catch (e) {
        print('DEBUG: Facebook sign out error: $e');
      }

      try {
        await _auth.signOut();
        print('DEBUG: Firebase auth sign out complete');
      } catch (e) {
        print('DEBUG: Firebase auth sign out error: $e');
      }

      // Add a small delay to ensure Firebase has time to process the sign out
      await Future.delayed(const Duration(milliseconds: 500));

      print('DEBUG: Sign out completed successfully');

      // Show success message
      scaffoldMsg.showSnackBar(
        const SnackBar(content: Text('Successfully signed out')),
      );

      // Navigate to login screen in separate try-catch
      try {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        print('DEBUG: Navigation error: $e');
      }
    } catch (e) {
      print('DEBUG: Error during sign out: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to sign out: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('DEBUG: Testing Firebase connection...');

      // Test Firestore read
      final docRef = FirebaseFirestore.instance
          .collection('_test')
          .doc('connection_test');

      // Write test data
      await docRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': Theme.of(context).platform.toString(),
          'screen':
              '${MediaQuery.of(context).size.width}x${MediaQuery.of(context).size.height}',
        },
        'testMessage':
            'Profile screen test ${DateTime.now().toIso8601String()}',
      });

      print('DEBUG: Test write successful');

      // Read the data back
      final snapshot = await docRef.get();
      print('DEBUG: Test read successful: ${snapshot.data()}');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase connection test: SUCCESS'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('ERROR: Firebase test failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Influencer Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
            tooltip: 'Sign Out',
            color: Colors.redAccent, // Make the icon red to stand out
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF9146FF), // Twitch purple
                ),
              )
              : Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(icon: Icon(Icons.person), text: "Profile"),
                      Tab(icon: Icon(Icons.insert_chart), text: "Metrics"),
                      Tab(icon: Icon(Icons.link), text: "Connections"),
                    ],
                    indicatorColor: const Color(0xFF9146FF), // Twitch purple
                    labelColor: const Color(0xFF9146FF), // Twitch purple
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(),
                        _buildMetricsTab(),
                        _buildConnectionsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF18181B), // Twitch dark
        selectedItemColor: const Color(0xFF9146FF), // Twitch purple
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 3, // Profile selected
        onTap: (index) {
          if (index == 0) {
            // Navigate to Home
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to Home...")),
            );
            // Eventually replace with actual navigation
          } else if (index == 1) {
            // Navigate to Discover
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to Discover...")),
            );
            // Eventually replace with actual navigation
          } else if (index == 2) {
            // Navigate to chat screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          }
          // Index 3 is already Profile, so no action needed
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildDrawer() {
    final userType = userData.userType ?? 'influencer';
    final name = userData.name.isEmpty ? 'User' : userData.name;
    final email = userData.email.isEmpty ? '' : userData.email;
    final profilePic = userData.profilePic;

    return Drawer(
      backgroundColor: const Color(0xFF18181B), // Twitch dark
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9146FF), Color(0xFF7A3CDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      profilePic != null && profilePic.isNotEmpty
                          ? CachedNetworkImageProvider(profilePic)
                          : null,
                  child:
                      profilePic == null || profilePic.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          )
                          : null,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  userType == 'influencer' ? '🎮 Influencer' : '🏢 Brand',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.home, 'Home', () {
            Navigator.pop(context); // Close drawer
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to Home...")),
            );
          }),
          _buildDrawerItem(Icons.explore, 'Discover', () {
            Navigator.pop(context); // Close drawer
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Navigating to Discover...")),
            );
          }),
          _buildDrawerItem(Icons.message, 'Messages', () {
            Navigator.pop(context); // Close drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          }),
          _buildDrawerItem(Icons.people, 'Connections', () {}),
          _buildDrawerItem(Icons.notifications, 'Notifications', () {}),
          _buildDrawerItem(Icons.insights, 'Analytics', () {}),
          const Divider(color: Colors.grey),
          _buildDrawerItem(Icons.settings, 'Settings', () {}),
          _buildDrawerItem(Icons.help, 'Help & Support', () {}),
          _buildDrawerItem(Icons.exit_to_app, 'Sign Out', _signOut),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      hoverColor: const Color(0xFF26262C),
    );
  }

  void _showSearchDialog() {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: const Text('Search', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for brands or influencers',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
              ElevatedButton(
                onPressed: () {
                  // Implement search functionality
                  final query = searchController.text.trim();
                  Navigator.pop(context);
                  if (query.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Searching for: $query')),
                    );
                    // Navigate to search results page
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9146FF),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileHeader() {
    final profilePic = userData.profilePic;
    final userType = userData.userType ?? 'influencer';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9146FF), Color(0xFF7A3CDB)], // Twitch purples
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _uploadProfileImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          profilePic != null && profilePic.isNotEmpty
                              ? CachedNetworkImageProvider(profilePic)
                              : null,
                      child:
                          profilePic == null || profilePic.isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7A3CDB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userData.name ?? 'Your Name',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (userType == 'influencer') const SizedBox(width: 8),
                        if (userType == 'influencer')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  userType == 'influencer'
                                      ? 'Influencer'
                                      : 'Brand',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData.bio ?? 'Your bio',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (userData.website != null && userData.website.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.link,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userData.website,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                metrics['totalFollowers']?.toString() ?? '0',
                'Followers',
              ),
              _buildStatItem(
                '${metrics['engagementRate']?.toString() ?? '0'}%',
                'Engagement',
              ),
              _buildStatItem(linkedAccounts.length.toString(), 'Networks'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Edit Profile",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Display Name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Bio",
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: websiteController,
                    decoration: InputDecoration(
                      labelText: "Website",
                      prefixIcon: const Icon(Icons.language),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category/Niche selection
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Content Categories",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildCategoryChip("Gaming", true),
                      _buildCategoryChip("Beauty", false),
                      _buildCategoryChip("Fitness", false),
                      _buildCategoryChip("Tech", false),
                      _buildCategoryChip("Food", false),
                      _buildCategoryChip("Travel", false),
                      _buildCategoryChip("Fashion", false),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: const Color(
                          0xFF9146FF,
                        ), // Twitch purple
                      ),
                      onPressed: _saveProfile,
                      child: const Text(
                        "Save Profile",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Location and rate card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Brand Collaboration Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text("Location"),
                    subtitle: Text("New York, USA"),
                    dense: true,
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.attach_money),
                    title: Text("Rate per post"),
                    subtitle: Text("\$500 - \$1,500"),
                    dense: true,
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text("Available for"),
                    subtitle: Text("Sponsored posts, Reviews, Campaigns"),
                    dense: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Collaboration Details"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26262C),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        // Show dialog to edit collaboration details
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Add Firebase test button for debugging
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Firebase Connection Test",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Test your Firebase connection with a simple read/write operation",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bug_report),
                      label: const Text("Test Firebase Connection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _testFirebaseConnection,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        // Handle category selection
      },
      backgroundColor: const Color(0xFF26262C),
      selectedColor: const Color(0xFF9146FF),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildConnectionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Manage Brand Connections",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Link your social accounts to showcase your audience reach",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Social accounts section
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Linked Social Accounts",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSocialAccountTile(
                    "Google",
                    Icons.g_mobiledata,
                    Colors.red,
                    linkedAccounts.contains('google'),
                  ),
                  _buildSocialAccountTile(
                    "Facebook",
                    Icons.facebook,
                    Colors.blue,
                    linkedAccounts.contains('facebook'),
                  ),
                  _buildSocialAccountTile(
                    "Instagram",
                    Icons.camera_alt,
                    Colors.purple,
                    linkedAccounts.contains('instagram'),
                  ),
                  _buildSocialAccountTile(
                    "TikTok",
                    Icons.music_note,
                    Colors.black,
                    linkedAccounts.contains('tiktok'),
                  ),
                  _buildSocialAccountTile(
                    "Twitch",
                    Icons.videogame_asset,
                    const Color(0xFF9146FF),
                    linkedAccounts.contains('twitch'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Active brand deals
          const Text(
            "Active Brand Collaborations",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Sample brand deals
          _buildBrandDealCard(
            "TechGadgets",
            "Product Review Campaign",
            "In Progress • Ends in 14 days",
            "assets/brand1.png",
          ),

          _buildBrandDealCard(
            "FitLife Supplements",
            "Sponsored Content Series",
            "Negotiating • Awaiting response",
            "assets/brand2.png",
          ),

          const SizedBox(height: 24),

          // Connect with new brands button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Discover New Brands"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9146FF),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                // Navigate to brand discovery page
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandDealCard(
    String brandName,
    String campaignTitle,
    String status,
    String logoPath,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF26262C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  brandName.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9146FF),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brandName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(campaignTitle, style: const TextStyle(fontSize: 14)),
                  Text(
                    status,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () {
                // Navigate to chat with this brand
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              tooltip: "Message",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialAccountTile(
    String name,
    IconData icon,
    Color color,
    bool isLinked,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(name),
        subtitle: Text(isLinked ? "Connected" : "Not connected"),
        trailing: ElevatedButton(
          onPressed: () async {
            if (!isLinked) {
              // Connect account
              if (name == "Google") {
                await _authService.signInWithGoogle(context);
              } else if (name == "Facebook") {
                await _authService.signInWithFacebook(context);
              }
              // Refresh data after connection
              _loadUserData();
            } else {
              // Disconnect account
              _showDisconnectDialog(name.toLowerCase());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isLinked ? Colors.red : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(isLinked ? "Disconnect" : "Connect"),
        ),
      ),
    );
  }

  void _showDisconnectDialog(String provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Disconnect $provider?"),
            content: Text(
              "Are you sure you want to disconnect your $provider account? This will remove access to your metrics data.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final String? userId = _authService.currentUserId;
                  if (userId != null) {
                    try {
                      // Remove the social account from the user document
                      await _firestoreService.removeSocialAccount(
                        userId,
                        provider,
                      );

                      // Refresh data
                      _loadUserData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$provider account disconnected"),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error disconnecting account: $e"),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Disconnect"),
              ),
            ],
          ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue is String) {
        // If it's an ISO date string
        final date = DateTime.parse(dateValue);
        return DateFormat('MMM d, yyyy').format(date);
      } else if (dateValue is Timestamp) {
        // If it's a Firestore Timestamp
        final date = dateValue.toDate();
        return DateFormat('MMM d, yyyy').format(date);
      } else {
        // Default case
        return "Unknown";
      }
    } catch (e) {
      print('Error formatting date: $e');
      return "Unknown";
    }
  }

  Widget _buildMetricsTab() {
    final followers = metrics['totalFollowers'] ?? 0;
    final engagement = metrics['engagementRate'] ?? 0.0;
    final lastUpdated =
        metrics['lastUpdated'] ?? DateTime.now().toIso8601String();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Performance Metrics",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "Last updated: ${_formatDate(lastUpdated)}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Followers",
                  followers.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  "Engagement",
                  "$engagement%",
                  Icons.favorite,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Follower Growth",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildFollowerChart()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // This would trigger a refresh of the metrics
              _loadUserData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh Metrics"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowerChart() {
    // Mock data for the chart
    final List<FlSpot> spots = [
      FlSpot(0, 1000),
      FlSpot(1, 1500),
      FlSpot(2, 1700),
      FlSpot(3, 1900),
      FlSpot(4, 2100),
      FlSpot(5, 2300),
      FlSpot(6, metrics['totalFollowers']?.toDouble() ?? 2500),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Now',
                ];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Text(
                    labels[value.toInt()],
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.deepPurple.withAlpha(51),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
