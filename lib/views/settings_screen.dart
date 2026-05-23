import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; 
import 'package:roomer/services/auth_service.dart';
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

  // Fetch current user info and all group members live from Firestore
  void _loadUserProfileAndGroup() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Fetch logged-in user profile details
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

        // 2. Fetch group details & roommates dynamically
        if (gid.isNotEmpty) {
          DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(gid).get();
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
              DocumentSnapshot mDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
              if (mDoc.exists && mDoc.data() != null) {
                namesTemp[uid] = (mDoc.data() as Map<String, dynamic>)['name'] ?? 'Roommate';
              }
            }
            if (mounted) setState(() => _memberNames = namesTemp);
          }
        }
      }
    }
  }

  // Danger Zone Logic: Clear group expenses safely
  void _resetGroupData() async {
    if (_groupId.isEmpty) return;

    setState(() => _memberIds = []); 
    try {
      var expensesRef = FirebaseFirestore.instance.collection('expenses');
      var snapshot = await expensesRef.where('groupId', isEqualTo: _groupId).get();
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        CustomAlert.show(context: context, message: 'All group expenses wiped successfully! 🧹', isSuccess: true);
        _loadUserProfileAndGroup(); 
      }
    } catch (e) {
      if (mounted) CustomAlert.show(context: context, message: 'Failed to reset data', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Premium Profile Header Graphical Display
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, size: 45, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 12),
                Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(_userEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Boarding Group Info Card (Name & Code Display)
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Boarding Group Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  const SizedBox(height: 15),
                  
                  // Group Name Row
                  Row(
                    children: [
                      const Icon(Icons.home_work_rounded, color: Color(0xFF475569), size: 20),
                      const SizedBox(width: 12),
                      const Text('Group Name: ', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                      Expanded(
                        child: Text(_groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  
                  // Group Code Row with Copy to Clipboard functionality
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: Color(0xFF475569), size: 20),
                          const SizedBox(width: 12),
                          const Text('Group Code: ', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(
                            _groupId, 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF10B981), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF10B981), size: 18),
                        onPressed: () async {
                          if (_groupId.isNotEmpty) {
                            await Clipboard.setData(ClipboardData(text: _groupId));
                            if (mounted) {
                              CustomAlert.show(context: context, message: 'Group code copied to clipboard! 📋', isSuccess: true);
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

          // Dynamic Manage Members Card From Live Firebase Database
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Roommates List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  _memberIds.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _memberIds.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            String uid = _memberIds[index];
                            String name = _memberNames[uid] ?? 'Loading...';
                            String initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
                            return _buildSettingMemberTile(name, initial);
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Danger Zone Card (Wipe all data logic linked)
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 15)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                        foregroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                        ),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text('Reset All Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _resetGroupData,
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // Custom Log Out Account Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B), 
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log Out Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  CustomAlert.show(context: context, message: 'Logged out successfully! 👋', isSuccess: true);
                }
              },
            ),
          ),
          const SizedBox(height: 30),

          // Version Tag Presentation footer
          const Center(
            child: Column(
              children: [
                Text('Roomer v1.2', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('Developed by The Zenon Studio', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Refactored Reusable Member List Component
  Widget _buildSettingMemberTile(String name, String initial) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFDBEAFE),
        child: Text(initial, style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Active',
          style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}