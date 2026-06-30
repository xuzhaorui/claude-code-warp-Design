import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../design/app_design_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import 'server_config_store.dart';

/// Server configuration page.
///
/// Allows users to manage multiple server configurations (name + base URL),
/// select an active server, and test connectivity (placeholder).
///
/// Defaults to [PersistentServerConfigStore] for production.
/// Inject an [InMemoryServerConfigStore] for tests.
class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({
    super.key,
    this.store,
    this.onConfigured,
  });

  final ServerConfigStore? store;

  /// Called when a server has been configured and saved.
  /// Used by main.dart to detect when to transition from setup → login.
  final VoidCallback? onConfigured;

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  late final ServerConfigStore _store;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  List<ServerConfig> _servers = [];
  ServerConfig? _activeServer;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? PersistentServerConfigStore();
    _load();
  }

  Future<void> _load() async {
    final servers = await _store.loadServers();
    final active = await _store.loadActiveServer();
    if (!mounted) return;
    setState(() {
      _servers = servers;
      _activeServer = active;
    });
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) {
      setState(() {
        _statusMessage = '请输入名称和地址';
        _statusIsError = true;
      });
      return;
    }

    final config = ServerConfig(name: name, baseUrl: url);
    final updated = [..._servers, config];
    await _store.saveServers(updated);
    await _store.setActiveServer(config.normalizedBaseUrl);

    if (!mounted) return;
    setState(() {
      _servers = updated;
      _activeServer = config;
      _statusMessage = '服务配置已保存';
      _statusIsError = false;
      _showForm = false;
      _nameController.clear();
      _urlController.clear();
    });
    widget.onConfigured?.call();
  }

  void _handleTestConnection() {
    setState(() {
      _statusMessage = '待接入真实连接测试';
      _statusIsError = false;
    });
  }

  void _handleSelect(ServerConfig config) async {
    await _store.setActiveServer(config.normalizedBaseUrl);
    if (!mounted) return;
    setState(() => _activeServer = config);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('服务配置', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xl),

          // Active server display
          if (_activeServer != null) _buildActiveServer(_activeServer!),

          // Server list
          if (_servers.isEmpty)
            _buildEmptyState()
          else
            ..._servers.map(_buildServerTile),

          const SizedBox(height: AppSpacing.lg),

          // Add / form toggle
          if (!_showForm)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '添加服务器',
                icon: Icons.add,
                onPressed: () => setState(() => _showForm = true),
              ),
            ),

          // Add form
          if (_showForm) _buildForm(),

          // Status message
          if (_statusMessage != null) _buildStatusMessage(),
        ],
      ),
    );
  }

  Widget _buildActiveServer(ServerConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppDesignColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesignColors.primary),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppDesignColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前服务器：${config.name}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                Text(config.normalizedBaseUrl, style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerTile(ServerConfig config) {
    final isActive = _activeServer?.normalizedBaseUrl == config.normalizedBaseUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isActive ? AppDesignColors.primarySoft : AppDesignColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleSelect(config),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20,
                  color: isActive ? AppDesignColors.primary : AppDesignColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(config.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      Text(config.normalizedBaseUrl,
                          style: AppTextStyles.caption.copyWith(color: AppDesignColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          '暂无服务配置',
          style: AppTextStyles.body.copyWith(color: AppDesignColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceMuted,
        borderRadius: BorderRadius.all(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('添加服务器', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '服务器名称',
              hintText: '如：主服务器',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: '服务地址',
              hintText: 'http://192.168.1.100:8080',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: '保存',
                  onPressed: _handleSave,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: '测试连接',
                  variant: AppButtonVariant.secondary,
                  onPressed: _handleTestConnection,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        _statusMessage!,
        style: AppTextStyles.body.copyWith(
          color: _statusIsError ? AppDesignColors.textSecondary : AppDesignColors.primary,
        ),
      ),
    );
  }
}
