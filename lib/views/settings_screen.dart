import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:roomer/constants/app_colors.dart';
import 'package:roomer/services/auth_service.dart';
import 'package:roomer/views/login_screen.dart';
import 'package:roomer/widgets/roommate_theme_tile.dart';
import 'package:roomer/widgets/primary_button.dart'; // Imported the reusable custom button widget
import 'custom_alert.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String _groupId = '';
  String _groupName = 'Loading...';
  List<String> _memberIds = [];
  Map<String, String> _memberNames = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndGroup();
  }

  // Fetch current user details and associated group information from Firestore
  void _loadUserProfileAndGroup() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Fetch logged-in user profile attributes
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        var userData = userDoc.data() as Map<String, dynamic>;
        String gid = userData['groupId']?.toString() ?? '';

        if (mounted) {
          setState(() {
            _userName = userData['name'] ?? 'Roommate';
            _userEmail = user.email ?? 'No Email';
            _groupId = gid;
          });
        }

        // 2. Load group profile and resolve registry maps for members
        if (gid.isNotEmpty) {
          DocumentSnapshot groupDoc = await FirebaseFirestore.instance
              .collection('groups')
              .doc(gid)
              .get();
          if (groupDoc.exists && groupDoc.data() != null) {
            var groupData = groupDoc.data() as Map<String, dynamic>;
            List members = groupData['members'] ?? [];
            String gName = groupData['groupName'] ?? 'My Boarding Group';

            if (mounted) {
              setState(() {
                _groupName = gName;
                _memberIds = List<String>.from(members);
              });
            }

            Map<String, String> namesTemp = {};
            for (String uid in members) {
              DocumentSnapshot mDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();
              if (mDoc.exists && mDoc.data() != null) {
                namesTemp[uid] =
                    (mDoc.data() as Map<String, dynamic>)['name'] ?? 'Roommate';
              }
            }
            if (mounted) setState(() => _memberNames = namesTemp);
          }
        }
      }
    }
  }

  // Remove existing transaction documents associated with the active group ID
  void _resetGroupData() async {
    if (_groupId.isEmpty) return;

    setState(() => _memberIds = []);
    try {
      var expensesRef = FirebaseFirestore.instance.collection('expenses');
      var snapshot = await expensesRef
          .where('groupId', isEqualTo: _groupId)
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        CustomAlert.show(
          context: context,
          message: 'All group expenses wiped successfully!',
          isSuccess: true,
        );
        _loadUserProfileAndGroup();
      }
    } catch (e) {
      if (mounted)
        CustomAlert.show(
          context: context,
          message: 'Failed to reset data',
          isSuccess: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile section layout header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 45,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  _userEmail,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Boarding group core details card configuration
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Boarding Group Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Icon(
                        Icons.home_work_rounded,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Group Name: ',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.border),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Group Code: ',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _groupId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        onPressed: () async {
                          if (_groupId.isNotEmpty) {
                            await Clipboard.setData(
                              ClipboardData(text: _groupId),
                            );
                            if (mounted) {
                              CustomAlert.show(
                                context: context,
                                message: 'Group code copied to clipboard!',
                                isSuccess: true,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Active occupants dynamic list view allocation
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Roommates List',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _memberIds.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _memberIds.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: AppColors.scaffoldBg,
                          ),
                          itemBuilder: (context, index) {
                            String uid = _memberIds[index];
                            String name = _memberNames[uid] ?? 'Loading...';

                            return RoommateThemeTile(
                              name: name,
                              status: 'Active Member',
                              trailingAmountOrStatus: 'Active',
                              trailingColor: AppColors.secondary,
                              leadingIcon: Icons.person,
                              iconColor: AppColors.primary,
                              isSettingsMode: true,
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // High-risk state triggers allocated within explicit danger zones
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.1),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                        ),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text(
                        'Reset All Expenses',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              icon: const Icon(
                                Icons.construction_rounded,
                                color: AppColors.primary,
                                size: 40,
                              ),
                              title: const Text(
                                'Future Development',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                'This feature is scheduled for a future update. Once fully implemented, it will request real-time approval from all roommates before resetting the expense data.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  color: Colors.black54,
                                ),
                              ),
                              actions: [
                                Center(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'Understood',
                                        style: TextStyle(
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Linked the centralized primary custom button widget
          PrimaryButton(
            text: 'Log Out',
            backgroundColor: AppColors.textDark,
            icon: Icons.logout_rounded,
            onPressed: () async {
              // 1. Sign out from Firebase
              await _authService.signOut();

              // 2. Redirect to LoginScreen and clear all history
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // Clears everything from the stack
                );
              }
            },
          ),
          const SizedBox(height: 30),

          // Metadata release identity footer logs
          const Center(
            child: Column(
              children: [
                Text(
                  'Roomer v1.2',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Developed by Geeth Kalhara',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
