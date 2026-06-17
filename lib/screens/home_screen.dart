import 'package:flutter/material.dart';
import '../models/project_config.dart';
import 'config_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Icon(
                Icons.grid_on_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '酥豆',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '将人像照片转换为拼豆图案',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '给酥圆圆的第一颗豆子',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(flex: 2),
              _ModeCard(
                icon: Icons.auto_awesome,
                title: '像素风格',
                subtitle: '将人像转为像素艺术风格',
                color: theme.colorScheme.primaryContainer,
                onTap: () => _navigateToConfig(context, ConvertMode.pixel),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.portrait_rounded,
                title: '写实拼豆',
                subtitle: '直接将人像颜色映射为拼豆',
                color: theme.colorScheme.secondaryContainer,
                onTap: () => _navigateToConfig(context, ConvertMode.realistic),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToConfig(BuildContext context, ConvertMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfigScreen(mode: mode),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.onSurface),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
