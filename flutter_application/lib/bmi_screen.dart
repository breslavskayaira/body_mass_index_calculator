import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_colors.dart';
import 'bmi_calculator.dart';
import 'profile_screen.dart';

class BMIScreen extends StatefulWidget {
  const BMIScreen({super.key});

  @override
  State<BMIScreen> createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  double? _bmiResult;
  String? _recommendation;
  String? _errorMessage;
  bool _isLoading = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _calculateAndSaveBMI() async {
    final BmiAssessment assessment;
    try {
      assessment = assessBmi(
        heightText: _heightController.text,
        weightText: _weightController.text,
      );
    } on BmiValidationException catch (error) {
      setState(() {
        _errorMessage = error.message;
        _bmiResult = null;
        _recommendation = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _bmiResult = assessment.bmi;
      _recommendation = assessment.recommendation;
    });

    try {
      final height = tryParseNumber(_heightController.text)!;
      final weight = tryParseNumber(_weightController.text)!;
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Войдите снова, чтобы сохранить расчёт'),
          ),
        );
        return;
      }

      await _supabase.from('body_mass_index_calculations').insert({
        'height': measurementForStorage(heightToCentimeters(height)),
        'weight': measurementForStorage(weight),
        'body_mass_index': assessment.bmi,
        'recommendation': assessment.recommendation,
        'user_id': user.id,
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения данных: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width * 0.9;

    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Индекс массы тела',
                style: TextStyle(
                  color: kAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: cardWidth,
                padding: const EdgeInsets.all(20),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Персональные данные',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Рост (см или м)'),
                    TextField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        hintText: '185',
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Вес (кг)'),
                    TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        hintText: '77',
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: cardWidth,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _calculateAndSaveBMI,
                  style: primaryButtonStyle().copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'РАССЧИТАТЬ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 24, right: 24),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              if (_bmiResult != null && _recommendation != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kResultBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ваш индекс массы тела:',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: kAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _bmiResult!.toStringAsFixed(2),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                          color: kAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _recommendation!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onProfile: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onCalculator,
    this.onProfile,
  });

  final int currentIndex;
  final VoidCallback? onCalculator;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: onCalculator ?? () {},
            child: Text(
              'Калькулятор',
              style: TextStyle(
                color: currentIndex == 0 ? kAccent : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: onProfile ?? () {},
            child: Text(
              'Профиль',
              style: TextStyle(
                color: currentIndex == 1 ? kAccent : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
