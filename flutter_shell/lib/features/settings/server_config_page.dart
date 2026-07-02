import 'package:flutter/material.dart';

import '../../components/app_button.dart';
import '../../components/app_select_card.dart';
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
    this.onLogout,
    this.onServerChanged,
  });

  final ServerConfigStore? store;

  /// Called when a server has been configured and saved.
  /// Used by main.dart to detect when to transition from setup → login.
  final VoidCallback? onConfigured;

  /// Called when the user taps "退出登录".  Only relevant when the page is
  /// shown inside the shell (not during initial server setup).
  final VoidCallback? onLogout;

  /// Called when an existing server is selected as the new active server.
  /// Used by the app shell to clear the old session and return to login.
  final VoidCallback? onServerChanged;

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

  /// task-046: settings home (简洁入口页) vs server-config management view.
  bool _showManagement = false;

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
    widget.onServerChanged?.call();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // task-046: two-level structure.
    //  - When shown during initial server setup (no onLogout), go straight
    //    to the management view so the user can configure a server.
    //  - When shown inside the shell (onLogout wired), default to a简洁
    //    settings home; tap 服务器配置 to enter the management view.
    final initialSetup = widget.onLogout == null;
    if (initialSetup || _showManagement) {
      return _buildManagementView();
    }
    return _buildSettingsHome();
  }

  // ── Settings home (图四 style) ──

  Widget _buildSettingsHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xl),
          // Single entry card → server-config management view.
          AppSelectCard(
            title: '服务器配置',
            subtitle: '管理连接的服务器地址',
            leadingIcon: Icons.dns_outlined,
            trailing: const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppDesignColors.textSecondary,
            ),
            onTap: () => setState(() => _showManagement = true),
          ),
          // Logout.
          if (widget.onLogout != null) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '退出登录',
                variant: AppButtonVariant.secondary,
                onPressed: widget.onLogout,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Server-config management view (current/available/add) ──

  Widget _buildManagementView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back row.
          if (_showManagement || Navigator.of(context).canPop()) ...[
            GestureDetector(
              onTap: () {
                if (_showManagement) {
                  setState(() => _showManagement = false);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: AppDesignColors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '服务器配置',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ] else ...[
            Text('服务配置', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Current server section.
          if (_activeServer != null) ...[
            _buildSectionLabel('当前服务器'),
            _buildActiveServer(_activeServer!),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Available server list.
          _buildSectionLabel('可用服务器'),
          if (_servers.isEmpty)
            _buildEmptyState()
          else
            ..._servers.map(_buildServerTile),
          const SizedBox(height: AppSpacing.lg),

          // Add / form toggle.
          if (!_showForm)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: '添加服务器',
                icon: Icons.add,
                onPressed: () => setState(() => _showForm = true),
              ),
            ),

          // Add form.
          if (_showForm) _buildForm(),

          // Status message.
          if (_statusMessage != null) _buildStatusMessage(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppDesignColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActiveServer(ServerConfig config) {
    return AppSelectCard(
      title: config.name,
      subtitle: config.normalizedBaseUrl,
      selected: true,
      leadingIcon: Icons.check_circle,
      onTap: null,
      trailing: _buildCurrentBadge(),
    );
  }

  /// Small "当前" pill badge marking the active server.
  Widget _buildCurrentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppDesignColors.primarySoft,
        borderRadius: BorderRadius.all(AppRadii.pill),
      ),
      child: Text(
        '当前',
        style: AppTextStyles.label.copyWith(color: AppDesignColors.textPrimary),
      ),
    );
  }

  Widget _buildServerTile(ServerConfig config) {
    final isActive =
        _activeServer?.normalizedBaseUrl == config.normalizedBaseUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppSelectCard(
        title: config.name,
        subtitle: config.normalizedBaseUrl,
        selected: isActive,
        leadingIcon: isActive
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        trailing: const Icon(
          Icons.chevron_right,
          size: 20,
          color: AppDesignColors.textSecondary,
        ),
        onTap: () => _handleSelect(config),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          '暂无服务配置',
          style: AppTextStyles.body.copyWith(
            color: AppDesignColors.textSecondary,
          ),
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
          Text(
            '添加服务器',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '用户名称',
              hintText: '如：张三',
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
                child: AppButton(text: '保存', onPressed: _handleSave),
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
          color: _statusIsError
              ? AppDesignColors.textSecondary
              : AppDesignColors.primary,
        ),
      ),
    );
  }
}
