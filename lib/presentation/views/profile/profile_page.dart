import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadUserData();
      context.read<ProfileViewModel>().loadUserStats();
    });
  }

  Widget _buildProfileImage(String? photoURL) {
    if (photoURL != null && photoURL.startsWith('data:image')) {
      // Base64 image
      try {
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.memory(
            bytes,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    } else if (photoURL != null && photoURL.startsWith('http')) {
      // Network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.network(
          photoURL,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person,
              size: 60,
              color: Colors.black,
            );
          },
        ),
      );
    }
    
    // Default icon
    return const Icon(
      Icons.person,
      size: 60,
      color: Colors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, ProfileViewModel>(
      builder: (context, authViewModel, profileViewModel, child) {
        final currentUser = authViewModel.currentUser;
        final userData = profileViewModel.userData;
        final userStats = profileViewModel.userStats;

        String getDisplayName() {
          if (userData?.displayName != null && userData!.displayName!.isNotEmpty) {
            return userData!.displayName!;
          }
          return "User";
        }

        String getEmail() {
          return userData?.email ?? currentUser?.email ?? "No email";
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: profileViewModel.isBusy
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Profile Picture
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFFD6F36B),
                                  child: _buildProfileImage(userData?.photoURL),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.pushNamed(context, '/edit-profile');
                                      if (result == true) {
                                        profileViewModel.loadUserData();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF7A4D),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Name and Email
                            Text(
                              getDisplayName(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              getEmail(),
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),

                            const SizedBox(height: 20),

                            // Stats Row
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6F36B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatItem(
                                    label: 'Days Active',
                                    value: userStats['daysActive']?.toString() ?? '0',
                                    icon: Icons.calendar_today,
                                  ),
                                  const SizedBox(
                                    width: 1,
                                    height: 40,
                                    child: ColoredBox(color: Colors.grey),
                                  ),
                                  _StatItem(
                                    label: 'Foods Scanned',
                                    value: userStats['foodsScanned']?.toString() ?? '0',
                                    icon: Icons.camera_alt,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Menu Items
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _ProfileMenuItem(
                              icon: Icons.person_outline,
                              title: 'Edit Profile',
                              subtitle: 'Update your personal information',
                              onTap: () async {
                                final result = await Navigator.pushNamed(context, '/edit-profile');
                                if (result == true) {
                                  profileViewModel.loadUserData();
                                }
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              subtitle: 'App preferences and notifications',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Settings coming soon!')),
                                );
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'FAQs and contact support',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Help & Support coming soon!')),
                                );
                              },
                            ),
                            _ProfileMenuItem(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              subtitle: 'Log out of your account',
                              onTap: () => _showSignOutDialog(authViewModel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showSignOutDialog(AuthViewModel authViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authViewModel.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFD6F36B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.black54,
      ),
    );
  }
}
