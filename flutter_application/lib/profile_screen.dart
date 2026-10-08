import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_colors.dart';
import 'auth_screen.dart';
import 'bmi_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Map<String, dynamic>>> _userDataFuture;
  String _userName = 'Имя Фамилия';
  String _userEmail = '';

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _applyProfile();
    _userDataFuture = _loadUserData();
  }

  void _applyProfile() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata;
    final fullName = metadata?['full_name']?.toString().trim();
    final firstName = metadata?['first_name']?.toString().trim() ?? '';
    final lastName = metadata?['last_name']?.toString().trim() ?? '';
    final combined = '$firstName $lastName'.trim();

    _userName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (combined.isNotEmpty ? combined : 'Имя Фамилия');
    _userEmail = user.email ?? '';
  }

  Future<List<Map<String, dynamic>>> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('body_mass_index_calculations')
        .select('created_at, height, weight, body_mass_index, recommendation')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(local.year, local.month, local.day);
    final time = _formatTime(local);

    if (date == today) return 'Сегодня, $time';
    if (date == yesterday) return 'Вчера, $time';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}, $time';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatIndex(dynamic value) {
    if (value is num) return value.toStringAsFixed(2);
    return double.parse(value.toString()).toStringAsFixed(2);
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: cardDecoration(
                      shadow: Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(color: kAccent, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, size: 40, color: kAccent),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: _signOut,
                          child: const Text(
                            'Выйти',
                            style: TextStyle(color: kAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: cardDecoration(
                      shadow: Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: const Text(
                      'Активность',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: kAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _userDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: kAccent),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Не удалось загрузить историю расчётов',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final history = snapshot.data ?? [];
                      if (history.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'История расчётов пока пуста',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return Column(
                        children: history.map((item) {
                          final createdAt = DateTime.parse(
                            item['created_at'] as String,
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: cardDecoration(
                              shadow: Colors.grey.withValues(alpha: 0.2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Время расчёта',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(createdAt),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _Metric(
                                        label: 'Рост',
                                        value: item['height'].toString(),
                                      ),
                                    ),
                                    Expanded(
                                      child: _Metric(
                                        label: 'Вес',
                                        value: item['weight'].toString(),
                                      ),
                                    ),
                                    Expanded(
                                      child: _Metric(
                                        label: 'Индекс массы тела',
                                        value: _formatIndex(
                                          item['body_mass_index'],
                                        ),
                                        emphasize: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Рекомендация',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  item['recommendation']?.toString() ?? '',
                                  style: const TextStyle(color: kMuted),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onCalculator: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BMIScreen()),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            color: emphasize ? kAccent : Colors.black,
          ),
        ),
      ],
    );
  }
}
