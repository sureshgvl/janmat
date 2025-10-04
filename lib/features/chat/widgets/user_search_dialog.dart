import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user_model.dart';
import '../services/private_chat_service.dart';
import '../controllers/chat_controller.dart';

class UserSearchDialog extends StatefulWidget {
  const UserSearchDialog({super.key});

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PrivateChatService _privateChatService = PrivateChatService();
  final ChatController _chatController = Get.find<ChatController>();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Try multiple search strategies for better case-insensitive results
      final searchResults = <UserModel>{}; // Use Set to avoid duplicates

      // Strategy 1: Original query
      final snapshot1 = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      // Strategy 2: Lowercase query
      final lowerQuery = query.toLowerCase();
      final snapshot2 = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: lowerQuery)
          .where('name', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .limit(10)
          .get();

      // Strategy 3: Uppercase query
      final upperQuery = query.toUpperCase();
      final snapshot3 = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: upperQuery)
          .where('name', isLessThanOrEqualTo: upperQuery + '\uf8ff')
          .limit(10)
          .get();

      // Strategy 4: Title case query
      final titleQuery = query.split(' ').map((word) =>
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
      ).join(' ');
      final snapshot4 = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: titleQuery)
          .where('name', isLessThanOrEqualTo: titleQuery + '\uf8ff')
          .limit(10)
          .get();

      // Combine all results and convert to UserModel
      final allDocs = {...snapshot1.docs, ...snapshot2.docs, ...snapshot3.docs, ...snapshot4.docs};

      for (final doc in allDocs.take(20)) {
        final data = doc.data();
        final user = UserModel(
          uid: doc.id,
          name: data['name'] ?? 'Unknown',
          phone: data['phone'] ?? '',
          email: data['email'],
          role: data['role'] ?? 'voter',
          roleSelected: data['roleSelected'] ?? false,
          profileCompleted: data['profileCompleted'] ?? false,
          electionAreas: [],
          districtId: data['districtId'] ?? '',
          xpPoints: data['xpPoints'] ?? 0,
          premium: data['premium'] ?? false,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
          photoURL: data['photoURL'],
        );
        searchResults.add(user);
      }

      final users = searchResults.toList();

      // Filter out current user
      final currentUserId = _chatController.currentUser?.uid;
      users.removeWhere((user) => user.uid == currentUserId);

      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startPrivateChat(UserModel selectedUser) async {
    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Use controller's method to start private chat
      final chatRoom = await _chatController.startPrivateChat(
        selectedUser.uid,
        selectedUser.name,
      );

      Get.back(); // Close loading

      if (chatRoom != null) {
        // Close search dialog
        Get.back();

        // Navigate to the chat room
        _chatController.selectChatRoom(chatRoom);

        Get.snackbar(
          'Success',
          'Private chat started with ${selectedUser.name}',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to start private chat',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      Get.back(); // Close loading
      debugPrint('Error starting private chat: $e');
      Get.snackbar(
        'Error',
        'Failed to start private chat',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.message, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Start Private Chat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _searchUsers(value);
                  } else {
                    setState(() => _searchResults = []);
                  }
                },
              ),
            ),

            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty && _searchController.text.length >= 2
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '${user.role.capitalizeFirst} • ${user.phone}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.message),
                                onPressed: () => _startPrivateChat(user),
                                color: Theme.of(context).primaryColor,
                              ),
                              onTap: () => _startPrivateChat(user),
                            );
                          },
                        ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

