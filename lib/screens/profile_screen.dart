import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:toko_game/providers/auth_provider.dart';
import 'package:toko_game/providers/theme_provider.dart';
import 'package:toko_game/screens/auth/login_screen.dart';
import 'package:toko_game/screens/feedback_screen.dart';
import 'package:toko_game/screens/transaction_history_screen.dart';
import 'package:toko_game/utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _showAddressFields = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _steamIdController;
  late TextEditingController
      _profilePictureUrlController; // Add this controller

  // Address controllers
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final userData = Provider.of<AuthProvider>(context, listen: false).userData;

    _usernameController =
        TextEditingController(text: userData?['username'] ?? '');
    _emailController = TextEditingController(text: userData?['email'] ?? '');
    _steamIdController =
        TextEditingController(text: userData?['steamId'] ?? '');
    _profilePictureUrlController =
        TextEditingController(text: userData?['profilePicture'] ?? '');

    // Initialize address controllers
    _streetController = TextEditingController(text: userData?['street'] ?? '');
    _cityController = TextEditingController(text: userData?['city'] ?? '');
    _zipCodeController =
        TextEditingController(text: userData?['zipCode'] ?? '');
    _countryController =
        TextEditingController(text: userData?['country'] ?? '');

    // Show address fields if any of them has data
    _showAddressFields = _streetController.text.isNotEmpty ||
        _cityController.text.isNotEmpty ||
        _zipCodeController.text.isNotEmpty ||
        _countryController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _steamIdController.dispose();
    _profilePictureUrlController.dispose(); // Dispose the new controller
    _streetController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // Modified to preview the entered URL instead of picking from gallery
  Future<void> _previewImageUrl() async {
    final url = _profilePictureUrlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        // No need to set _imageFile as we're using URL directly
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Prepare update data to match backend API
      final updateData = {
        'username': _usernameController.text.trim(),
        'steamId': _steamIdController.text.trim(),
        'profilePicture': _profilePictureUrlController.text
            .trim(), // Add this field to updateData
      };

      // Add address data if the user has opted to show and fill address fields
      if (_showAddressFields) {
        updateData['street'] = _streetController.text.trim();
        updateData['city'] = _cityController.text.trim();
        updateData['zipCode'] = _zipCodeController.text.trim();
        updateData['country'] = _countryController.text.trim();
      }

      final success = await authProvider.updateProfile(updateData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );

        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authProvider.logout();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userData = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_round),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: userData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Center(
                    child: Column(
                      children: [
                        // Modified avatar section to handle URL-based images
                        _isEditing
                            ? Column(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor:
                                        AppColors.primaryColor.withOpacity(0.1),
                                    backgroundImage:
                                        _profilePictureUrlController
                                                .text.isNotEmpty
                                            ? NetworkImage(
                                                _profilePictureUrlController
                                                    .text)
                                            : null,
                                    child: _profilePictureUrlController
                                            .text.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppColors.primaryColor,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  // URL input field
                                  TextFormField(
                                    controller: _profilePictureUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'Profile Picture URL',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.image_outlined),
                                      hintText:
                                          'Enter the URL of your profile picture',
                                    ),
                                    onChanged: (_) => setState(
                                        () {}), // Refresh to show preview
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: null, // Disable tap when not editing
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor:
                                      AppColors.primaryColor.withOpacity(0.1),
                                  backgroundImage: userData['profilePicture'] !=
                                              null &&
                                          userData['profilePicture']
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(
                                          userData['profilePicture'].toString())
                                      : null,
                                  child: userData['profilePicture'] == null ||
                                          userData['profilePicture']
                                              .toString()
                                              .isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: AppColors.primaryColor,
                                        )
                                      : null,
                                ),
                              ),

                        const SizedBox(height: 16),
                        if (!_isEditing)
                          Text(
                            userData['username'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (!_isEditing)
                          Text(
                            userData['email'] ?? 'email@example.com',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (!_isEditing &&
                            userData['steamId'] != null &&
                            userData['steamId'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Chip(
                              avatar: const Icon(Icons.gamepad, size: 16),
                              label: Text('Steam ID: ${userData['steamId']}'),
                              backgroundColor:
                                  AppColors.primaryColor.withOpacity(0.1),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Edit Profile Form
                  if (_isEditing)
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            enabled: false, // Email is not editable
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _steamIdController,
                            decoration: const InputDecoration(
                              labelText: 'Steam ID (optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.gamepad_outlined),
                              hintText: 'Enter your Steam ID for digital games',
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Address toggle
                          CheckboxListTile(
                            title: const Text('Add Shipping Address'),
                            subtitle:
                                const Text('For physical game deliveries'),
                            value: _showAddressFields,
                            activeColor: AppColors.primaryColor,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setState(() {
                                _showAddressFields = value ?? false;
                              });
                            },
                          ),

                          // Address fields
                          if (_showAddressFields) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _streetController,
                              decoration: const InputDecoration(
                                labelText: 'Street Address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                              validator: _showAddressFields
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Street address is required';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.location_city_outlined),
                                    ),
                                    validator: _showAddressFields
                                        ? (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'City is required';
                                            }
                                            return null;
                                          }
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _zipCodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'ZIP Code',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(
                                          Icons.markunread_mailbox_outlined),
                                    ),
                                    validator: _showAddressFields
                                        ? (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'ZIP code is required';
                                            }
                                            return null;
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Country',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.public_outlined),
                              ),
                              validator: _showAddressFields
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Country is required';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                          ],

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = false;
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Save Profile'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Profile Actions
                  if (!_isEditing)
                    Column(
                      children: [
                        // Edit profile button
                        _buildProfileAction(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),

                        // Order history
                        _buildProfileAction(
                          icon: Icons.history_outlined,
                          title: 'Purchase History',
                          subtitle: 'View your game purchase history',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TransactionHistoryScreen(),
                              ),
                            );
                          },
                        ),

                        // Feedback
                        _buildProfileAction(
                          icon: Icons.feedback_outlined,
                          title: 'Feedback',
                          subtitle:
                              'Send feedback about the Mobile Programming course',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FeedbackScreen(),
                              ),
                            );
                          },
                        ),

                        const Divider(),

                        // Logout
                        _buildProfileAction(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out from your account',
                          iconColor: Colors.red,
                          onTap: _logout,
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileAction({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primaryColor).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
    );
  }
}
