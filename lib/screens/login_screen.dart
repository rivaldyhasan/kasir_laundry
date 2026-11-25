import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../utils/tema.dart';

/// B.1 Login Kasir / KF-01.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _lihat = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _masuk() {
    final ok = AppStore.instance.login(_user.text, _pass.text);
    if (!ok) {
      setState(() => _error =
          'Username atau kata sandi salah. Silakan periksa kembali kredensial kasir Anda.');
    }
  }

  InputDecoration _dekor(String hint, IconData ikon, {Widget? akhir}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(ikon, size: 20),
        suffixIcon: akhir,
        filled: true,
        fillColor: kAbu,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: kGaris),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        errorBuilder: (_, _, _) => const Icon(
                            Icons.cleaning_services,
                            size: 40,
                            color: kHitam),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Send Shoes Care Kasir',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Trusted Care, Every Pair',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kGaris),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kAbu,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _error = null),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                        const Text('Username',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _user,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration:
                              _dekor('Masukkan username', Icons.person_outline),
                        ),
                        const SizedBox(height: 16),
                        const Text('Kata Sandi',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pass,
                          obscureText: !_lihat,
                          onSubmitted: (_) => _masuk(),
                          decoration: _dekor(
                            'Masukkan kata sandi',
                            Icons.lock_outline,
                            akhir: IconButton(
                              icon: Icon(
                                  _lihat
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20),
                              onPressed: () =>
                                  setState(() => _lihat = !_lihat),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _masuk,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Masuk ke Kasir'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sistem Operasional Kasir 5 Cabang v1.0.0\n'
                    'Hubungi Owner jika lupa akses',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
