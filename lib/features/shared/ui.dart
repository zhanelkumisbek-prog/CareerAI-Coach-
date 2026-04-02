import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CareerScaffold extends StatelessWidget {
  const CareerScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.currentRoute,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    final resolvedRoute = currentRoute ?? ModalRoute.of(context)?.settings.name;

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              size: 220,
              colors: const <Color>[Color(0x559B30FF), Color(0x009B30FF)],
            ),
          ),
          Positioned(
            top: 110,
            left: -70,
            child: _GlowOrb(
              size: 190,
              colors: const <Color>[Color(0x44D946EF), Color(0x00D946EF)],
            ),
          ),
          Positioned(
            bottom: -110,
            right: -60,
            child: _GlowOrb(
              size: 250,
              colors: const <Color>[Color(0x335B5FE8), Color(0x005B5FE8)],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF090913), Color(0xFF121226)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth < 600 ? 16 : 24,
                        vertical: 18,
                      ),
                      child: body,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CareerBottomNavigation(currentRoute: resolvedRoute),
    );
  }
}

class _CareerBottomNavigation extends StatelessWidget {
  const _CareerBottomNavigation({required this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    final destinations = <({String route, String label, IconData icon})>[
      (
        route: CareerAiCoachApp.profileRoute,
        label: 'Профиль',
        icon: Icons.person_rounded,
      ),
      (
        route: CareerAiCoachApp.dashboardRoute,
        label: 'Главная',
        icon: Icons.home_rounded,
      ),
      (
        route: CareerAiCoachApp.settingsRoute,
        label: 'Настройки',
        icon: Icons.settings_rounded,
      ),
    ];

    final currentIndex = destinations.indexWhere(
      (destination) => destination.route == currentRoute,
    );

    return NavigationBar(
      selectedIndex: currentIndex >= 0 ? currentIndex : 1,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 74,
      destinations: destinations
          .map(
            (destination) => NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
          )
          .toList(),
      onDestinationSelected: (index) {
        final route = destinations[index].route;
        if (route == currentRoute) return;
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        return Container(
          padding: EdgeInsets.all(isCompact ? 22 : 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFF16162B),
                Color(0xFF21153A),
                Color(0xFF120F26),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Color(0xFF34345C)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x449B30FF),
                blurRadius: 34,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -24,
                right: -10,
                child: Container(
                  width: isCompact ? 96 : 130,
                  height: isCompact ? 96 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x339B30FF),
                  ),
                ),
              ),
              Positioned(
                bottom: -34,
                right: isCompact ? 8 : 28,
                child: Container(
                  width: isCompact ? 76 : 96,
                  height: isCompact ? 76 : 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x44D946EF),
                      width: isCompact ? 14 : 18,
                    ),
                  ),
                ),
              ),
              isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _heroText(context),
                        if (trailing != null) ...<Widget>[
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: trailing!,
                          ),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: _heroText(context)),
                        if (trailing != null) ...<Widget>[
                          const SizedBox(width: 16),
                          Flexible(child: trailing!),
                        ],
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x229B30FF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x339B30FF)),
          ),
          child: const Text(
            'CAREER AI COACH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white, height: 1),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFF17172B),
          border: Border.all(color: const Color(0xFF303050)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x229B30FF),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1D1D36), Color(0xFF151528)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF303050)),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0x229B30FF),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x229B30FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x339B30FF)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 36,
              color: Color(0xFFD946EF),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

Color priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return const Color(0xFFE45757);
    case TaskPriority.medium:
      return const Color(0xFFFD8B51);
    case TaskPriority.low:
      return const Color(0xFF2A9D8F);
  }
}

String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
