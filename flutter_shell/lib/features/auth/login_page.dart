import 'package:flutter/material.dart';

import '../api/warehouse_api_client.dart';
import '../api/warehouse_api_models.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';

/// Full-screen login page.
///
/// Calls [WarehouseApiClient.login] with the provided credentials.
/// On success, [onLoggedIn] is called with the [AuthSession].
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.apiClient,
    required this.onLoggedIn,
  });

  final WarehouseApiClient apiClient;
  final ValueChanged<AuthSession> onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入用户名和密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await widget.apiClient.login(username, password);
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      widget.onLoggedIn(result.data!);
    } else {
      setState(() {
        _isLoading = false;
        _error = result.message ?? '登录失败';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / Title
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppDesignColors.primary,
                    borderRadius: BorderRadius.all(AppRadii.lg),
                  ),
                  child: const Icon(Icons.inventory_2, size: 48, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('仓库管理', style: AppTextStyles.display),
                const SizedBox(height: AppSpacing.xxl),

                // Username
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    hintText: '请输入用户名',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),

                // Password
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Error
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(_error!, style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )),
                  ),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignColors.primary,
                      foregroundColor: AppDesignColors.textPrimary,
                      shape: const StadiumBorder(),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('登录', style: AppTextStyles.label),
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
