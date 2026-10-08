import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_colors.dart';
import 'bmi_screen.dart';
import 'registration_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.message});

  final String? message;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.message;
    WidgetsBinding.instance.addPostFrameCallback((_) => checkAuth());
  }

  Future<void> checkAuth() async {
    if (!mounted || _supabase.auth.currentSession == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BMIScreen()),
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (_supabase.auth.currentSession == null) {
        setState(() => _errorMessage = 'Неверный email или пароль');
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BMIScreen()),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = localizeAuthError(error.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Неизвестная ошибка при авторизации');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width * 0.9;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Вход в приложение',
                  style: TextStyle(
                    color: kAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(20),
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: UnderlineInputBorder(),
                          ),
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => login(),
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                            border: UnderlineInputBorder(),
                          ),
                          validator: validatePassword,
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegistrationScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Зарегистрироваться',
                            style: TextStyle(
                              color: kAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: cardWidth,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : login,
                    style: primaryButtonStyle(),
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
                            'ВОЙТИ',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 24,
                      right: 24,
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Введите email';
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  if (!valid) return 'Введите корректный email';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Введите пароль';
  if (value.length < 6) return 'Пароль должен быть не менее 6 символов';
  return null;
}

String localizeAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('auth session missing')) {
    return 'Сессия не найдена. Войдите снова.';
  }
  if (lower.contains('email signups are disabled') ||
      lower.contains('email_provider_disabled') ||
      lower.contains('provider is not enabled')) {
    return 'В Supabase выключен вход по почте. Включите Email и отключите только Confirm email.';
  }
  if (lower.contains('rate limit')) {
    return 'Слишком много писем на почту. Подождите около часа или отключите подтверждение почты в Supabase.';
  }
  if (lower.contains('invalid login') ||
      lower.contains('invalid credentials')) {
    return 'Неверный email или пароль';
  }
  if (lower.contains('already registered') ||
      lower.contains('already been registered') ||
      lower.contains('user already')) {
    return 'Пользователь с такой почтой уже зарегистрирован';
  }
  if (lower.contains('email not confirmed')) {
    return 'Подтвердите почту, чтобы войти';
  }
  if (lower.contains('password')) {
    return 'Пароль должен содержать минимум 6 символов';
  }
  if (lower.contains('unable to validate email') ||
      lower.contains('invalid email')) {
    return 'Введите корректный email';
  }
  return message;
}
