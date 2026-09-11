import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../authentication/data/auth_repository.dart';
import '../../training/data/teams_repository.dart';
import '../../training/domain/team.dart';
import '../../training/presentation/widgets/swimmer_selector_widget.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final email = user?.email ?? 'Unknown Email';
    final profileAsync = ref.watch(profileProvider);

    // Get name from profile, fallback to email
    final name = profileAsync.maybeWhen(
      data: (profile) {
        if (profile != null) {
          final fullName = profile['full_name'];
          if (fullName != null &&
              fullName is String &&
              fullName.trim().isNotEmpty) {
            return fullName;
          }
        }
        return email.split('@').first;
      },
      orElse: () => email.split('@').first,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF001B33), Color(0xFF000B1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Profile',
              style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF0EA5E9), width: 4),
                      ),
                      child: const Icon(Icons.person,
                          size: 64, color: Color(0xFF0EA5E9)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Edit Profile
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Edit Profile',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Swimmer Profiles Section
              const SwimmerSelectorWidget(),
              const SizedBox(height: 32),

              // Default Team Selection
              _buildDefaultTeamSection(context, ref),
              const SizedBox(height: 24),

              // Account Type Section
              _buildAccountTypeSection(context, ref),
              const SizedBox(height: 24),

              // Settings Sections
              _buildSettingsSection(
                title: 'Account',
                items: [
                  _SettingsItem(
                      icon: Icons.person_outline,
                      label: 'Personal Information',
                      onTap: () {}),
                  _SettingsItem(
                      icon: Icons.notifications_none,
                      label: 'Notifications',
                      onTap: () {}),
                  _SettingsItem(
                      icon: Icons.lock_outline,
                      label: 'Privacy & Security',
                      onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingsSection(
                title: 'App',
                items: [
                  _SettingsItem(
                      icon: Icons.language,
                      label: 'Language',
                      trailing: 'English',
                      onTap: () {}),
                  _SettingsItem(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      isSwitch: true,
                      onTap: () {}),
                ],
              ),
              const SizedBox(height: 32),

              // Debug: Show JWT Token Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    final session =
                        Supabase.instance.client.auth.currentSession;
                    if (session != null) {
                      debugPrint('');
                      debugPrint(
                          '═══════════════════════════════════════════════════════════');
                      debugPrint('🔑 JWT TOKEN (Copy this for testing):');
                      debugPrint(
                          '═══════════════════════════════════════════════════════════');
                      debugPrint(session.accessToken);
                      debugPrint(
                          '═══════════════════════════════════════════════════════════');
                      debugPrint('');
                      debugPrint('📋 Full curl command:');
                      debugPrint(
                          'curl -X POST https://haljddborueaplgigsia.supabase.co/functions/v1/suggest-goals \\');
                      debugPrint('  -H "Content-Type: application/json" \\');
                      debugPrint(
                          '  -H "Authorization: Bearer ${session.accessToken}" \\');
                      debugPrint(
                          '  -H "apikey: sb_publishable_bk_IWh1vezTJqe3j9xGcvg_-vvmvzaL"');
                      debugPrint('');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('JWT token printed to console! Check logs.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No session found. Please log in.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F9FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bug_report,
                          color: Color(0xFF0EA5E9), size: 20),
                      const SizedBox(width: 8),
                      Text('Debug: Show JWT Token',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFF0EA5E9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(authRepositoryProvider).signOut();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Text('Log Out',
                          style: GoogleFonts.outfit(
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Account?'),
                        content: const Text(
                            'This action cannot be undone. All your data will be permanently lost.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (context.mounted) {
                        await ref.read(authRepositoryProvider).deleteAccount();
                        // Router will auto redirect to welcome
                      }
                    }
                  },
                  child: Text('Delete Account',
                      style: GoogleFonts.outfit(
                          color: Colors.red.withValues(alpha: 0.6),
                          fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Version 1.0.0',
                  style:
                      GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultTeamSection(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);
    final defaultTeamIdAsync = ref.watch(defaultTeamIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Training',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: teamsAsync.when(
            data: (teams) {
              return defaultTeamIdAsync.when(
                data: (defaultTeamId) {
                  Team? defaultTeam;
                  if (defaultTeamId != null) {
                    try {
                      defaultTeam =
                          teams.firstWhere((t) => t.id == defaultTeamId);
                    } catch (e) {
                      defaultTeam = teams.isNotEmpty ? teams.first : null;
                    }
                  } else {
                    defaultTeam = teams.isNotEmpty ? teams.first : null;
                  }

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.group,
                          color: Color(0xFF0F172A), size: 20),
                    ),
                    title: Text(
                      'Default Team',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      defaultTeam?.name ?? 'No team selected',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFCBD5E1)),
                    onTap: () => _showTeamSelectionDialog(
                        context, ref, teams, defaultTeamId),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  );
                },
                loading: () => const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Loading...'),
                ),
                error: (_, __) => const ListTile(
                  title: Text('Error loading default team'),
                ),
              );
            },
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading teams...'),
            ),
            error: (_, __) => const ListTile(
              title: Text('Error loading teams'),
            ),
          ),
        ),
      ],
    );
  }

  void _showTeamSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    List<Team> teams,
    String? currentTeamId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Default Team', style: GoogleFonts.spaceGrotesk()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teams.length + 1, // +1 for "None" option
            itemBuilder: (context, index) {
              if (index == 0) {
                // "None" option
                return ListTile(
                  title: const Text('No default team'),
                  leading: Icon(
                    currentTeamId == null
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: currentTeamId == null
                        ? const Color(0xFF0EA5E9)
                        : Colors.grey,
                  ),
                  onTap: () async {
                    await ref
                        .read(profileRepositoryProvider)
                        .setDefaultTeam(null);
                    if (context.mounted) {
                      ref.invalidate(defaultTeamIdProvider);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Default team cleared')),
                      );
                    }
                  },
                );
              }

              final team = teams[index - 1];
              return ListTile(
                title: Text(team.name),
                subtitle: team.location != null ? Text(team.location!) : null,
                leading: Icon(
                  currentTeamId == team.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: currentTeamId == team.id
                      ? const Color(0xFF0EA5E9)
                      : Colors.grey,
                ),
                onTap: () async {
                  await ref
                      .read(profileRepositoryProvider)
                      .setDefaultTeam(team.id);
                  if (context.mounted) {
                    ref.invalidate(defaultTeamIdProvider);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Default team set to ${team.name}')),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeSection(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Account Type',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: profileAsync.when(
            data: (profile) {
              // Safely get role from profile
              String currentRole = 'parent';
              if (profile != null && profile['role'] != null) {
                final roleValue = profile['role'];
                if (roleValue is String) {
                  currentRole = roleValue;
                }
              }
              final roleLabel = currentRole == 'parent'
                  ? 'Parent Account'
                  : 'Swimmer Account';
              final roleDescription = currentRole == 'parent'
                  ? 'Manage multiple swimmer profiles'
                  : 'View and manage your own profile';

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    currentRole == 'parent'
                        ? Icons.family_restroom
                        : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  roleLabel,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  roleDescription,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                trailing:
                    const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                onTap: () => _showRoleChangeDialog(context, ref, currentRole),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              );
            },
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading...'),
            ),
            error: (_, __) => const ListTile(
              title: Text('Error loading account type'),
            ),
          ),
        ),
      ],
    );
  }

  void _showRoleChangeDialog(
      BuildContext context, WidgetRef ref, String currentRole) {
    final newRole = currentRole == 'parent' ? 'swimmer' : 'parent';
    final newRoleLabel =
        newRole == 'parent' ? 'Parent Account' : 'Swimmer Account';
    final newRoleDescription = newRole == 'parent'
        ? 'You can manage multiple swimmer profiles for your children or athletes.'
        : 'You can view and manage your own swimmer profile.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Account Type',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert to $newRoleLabel?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              newRoleDescription,
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0EA5E9), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF0EA5E9), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can change this back anytime from your profile settings.',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0EA5E9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(profileRepositoryProvider).updateRole(newRole);
                if (context.mounted) {
                  ref.invalidate(profileProvider);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account type changed to $newRoleLabel'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error changing account type: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Change to $newRoleLabel',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
      {required String title, required List<_SettingsItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title,
              style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.icon, color: Colors.white, size: 20),
                    ),
                    title: Text(item.label,
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    trailing: item.isSwitch
                        ? Switch(value: false, onChanged: (val) {})
                        : item.trailing != null
                            ? Text(item.trailing!,
                                style:
                                    GoogleFonts.outfit(color: Colors.white70))
                            : const Icon(Icons.chevron_right,
                                color: Color(0xFFCBD5E1)),
                    onTap: item.onTap,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (index != items.length - 1)
                    Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.1),
                        indent: 60),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isSwitch;
  final VoidCallback onTap;

  _SettingsItem(
      {required this.icon,
      required this.label,
      this.trailing,
      this.isSwitch = false,
      required this.onTap});
}
