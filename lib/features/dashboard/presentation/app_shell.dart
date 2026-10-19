import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/simmas_logo.dart';
import '../../auth/presentation/auth_controller.dart';
import 'nav_items.dart';

/// Kerangka dashboard (sidebar bergrup + topbar) untuk semua role.
///  - >= 1000px : sidebar tetap, bisa di-collapse ke mode ikon lewat tombol toggle
///  - <  1000px : Drawer
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.auth, required this.notifications, required this.location, required this.child});

  final AuthController auth;
  final NotificationService notifications;
  final String location;
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _collapsed = false;
  List<AppNotification> _notifs = const [];

  @override
  void initState() {
    super.initState();
    _loadNotifs();
  }

  Future<void> _loadNotifs() async {
    try {
      final list = await widget.notifications.latest();
      if (mounted) setState(() => _notifs = list);
    } catch (_) {
      // Notifikasi bersifat opsional: abaikan bila gagal.
    }
  }

  Future<void> _logout() async {
    await widget.auth.signOut();
    if (mounted) context.go('/login');
  }

  void _openPalette() {
    final user = widget.auth.user;
    if (user == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => _CommandPalette(items: navItemsFor(user.role), onSelect: (p) => context.go(p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user;
    if (user == null) return const SizedBox.shrink(); // transisi logout

    final c = context.sc;
    final width = MediaQuery.sizeOf(context).width;
    final isDrawer = width < 1000;
    final groups = navGroupsFor(user.role);
    final all = navItemsFor(user.role);
    // HP: guru & siswa (<= 5 menu) memakai bottom navigation; admin (banyak menu) memakai Drawer.
    final useBottomNav = width < 700 && all.length <= 5;
    final current = all.where((i) => widget.location == i.path || widget.location.startsWith('${i.path}/')).firstOrNull;

    Widget sidebar({required bool compact, bool closeDrawer = false}) => _Sidebar(
          groups: groups,
          badge: roleBadge(user.role),
          location: widget.location,
          compact: compact,
          onSelected: (path) {
            if (closeDrawer) _scaffoldKey.currentState?.closeDrawer();
            context.go(path);
          },
        );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: c.background,
          drawer: isDrawer ? Drawer(backgroundColor: c.card, width: 288, child: SafeArea(child: sidebar(compact: false, closeDrawer: true))) : null,
          bottomNavigationBar: useBottomNav
              ? _BottomNav(items: all, location: widget.location, onSelected: (p) => context.go(p))
              : null,
          body: Row(
            children: [
              if (!isDrawer)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _collapsed ? 84 : 288,
                  decoration: BoxDecoration(color: c.card, border: Border(right: BorderSide(color: c.border))),
                  child: SafeArea(right: false, child: sidebar(compact: _collapsed)),
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      title: current?.pageTitle ?? 'SIMMAS',
                      onToggle: () => isDrawer ? _scaffoldKey.currentState?.openDrawer() : setState(() => _collapsed = !_collapsed),
                      onSearch: _openPalette,
                      showSearchLabel: width >= 640,
                      notifs: _notifs,
                      onNotifOpen: () async {
                        await widget.notifications.markAllRead();
                      },
                      onNotifClosed: _loadNotifs,
                      nama: user.nama,
                      onLogout: _logout,
                      onHome: () => context.go('/'),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.groups, required this.badge, required this.location, required this.compact, required this.onSelected});

  final List<NavGroup> groups;
  final String badge;
  final String location;
  final bool compact;
  final ValueChanged<String> onSelected;

  bool _selected(NavItem i) => location == i.path || location.startsWith('${i.path}/');

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Column(
      children: [
        Container(
          height: 82,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 20),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
          alignment: compact ? Alignment.center : Alignment.centerLeft,
          child: compact
              ? const SimmasLogo(size: 44)
              : Row(
                  children: [
                    const SimmasLogo(size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SIMMAS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5, height: 1.1)),
                          const SizedBox(height: 2),
                          Text(badge, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2.2, color: c.mutedForeground)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(compact ? 14 : 20, 8, compact ? 14 : 20, 20),
            children: [
              for (final g in groups) ...[
                if (compact)
                  const SizedBox(height: 12)
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
                    child: Text(g.title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2, color: c.mutedForeground)),
                  ),
                for (final item in g.items) _NavTile(item: item, selected: _selected(item), compact: compact, onTap: () => onSelected(item.path)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected, required this.compact, required this.onTap});

  final NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final fg = selected ? Colors.white : c.foreground.withValues(alpha: .8);
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? c.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        elevation: selected ? 3 : 0,
        shadowColor: c.primary.withValues(alpha: .35),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: selected ? null : c.muted,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (!compact) const SizedBox(width: 14),
                Icon(item.icon, size: 20, color: fg),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: fg))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return compact ? Tooltip(message: item.label, child: tile) : tile;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onToggle,
    required this.onSearch,
    required this.showSearchLabel,
    required this.notifs,
    required this.onNotifOpen,
    required this.onNotifClosed,
    required this.nama,
    required this.onLogout,
    required this.onHome,
  });

  final String title;
  final VoidCallback onToggle;
  final VoidCallback onSearch;
  final bool showSearchLabel;
  final List<AppNotification> notifs;
  final Future<void> Function() onNotifOpen;
  final VoidCallback onNotifClosed;
  final String nama;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final unread = notifs.any((n) => !n.dibaca);
    final w = MediaQuery.sizeOf(context).width;
    final narrow = w < 560;
    final mobile = w < 640;

    return Container(
      height: mobile ? 64 : 82,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : (narrow ? 16 : 24)),
      decoration: BoxDecoration(color: c.card, border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          IconButton(tooltip: 'Menu', onPressed: onToggle, icon: Icon(Icons.view_sidebar_outlined, size: mobile ? 20 : 22, color: c.mutedForeground)),
          Container(width: 1, height: mobile ? 20 : 24, color: c.border, margin: EdgeInsets.symmetric(horizontal: mobile ? 6 : 10)),
          Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: mobile ? 15 : 17, fontWeight: FontWeight.w600, letterSpacing: -.2))),
          if (!mobile)
            InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 19, color: c.mutedForeground),
                    if (showSearchLabel) ...[
                      const SizedBox(width: 10),
                      Text('Cari…', style: TextStyle(fontSize: 14, color: c.mutedForeground)),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(6)),
                        child: Text('⌘K', style: TextStyle(fontSize: 11, color: c.mutedForeground)),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            IconButton(tooltip: 'Cari', onPressed: onSearch, icon: Icon(Icons.search, size: 20, color: c.mutedForeground)),
          SizedBox(width: mobile ? 4 : 6),
          PopupMenuButton<String>(
            tooltip: 'Notifikasi',
            offset: const Offset(0, 52),
            onOpened: onNotifOpen,
            onCanceled: onNotifClosed,
            onSelected: (_) => onNotifClosed(),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none, size: mobile ? 20 : 22, color: c.mutedForeground),
                if (unread) Positioned(right: 0, top: 0, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))),
              ],
            ),
            itemBuilder: (_) => notifs.isEmpty
                ? [const PopupMenuItem(enabled: false, child: Text('Tidak ada notifikasi'))]
                : [
                    for (final n in notifs)
                      PopupMenuItem(
                        value: n.id,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.judul, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (n.isi.isNotEmpty) Text(n.isi, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.mutedForeground)),
                              Text(waktuRelatif(n.waktu), style: TextStyle(fontSize: 11, color: c.mutedForeground)),
                            ],
                          ),
                        ),
                      ),
                  ],
          ),
          if (!mobile) Container(width: 1, height: 28, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
          PopupMenuButton<String>(
            tooltip: 'Profil',
            offset: const Offset(0, 52),
            onSelected: (v) => v == 'logout' ? onLogout() : onHome(),
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(nama, style: const TextStyle(fontWeight: FontWeight.w700))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'home', child: Text('Beranda situs')),
              PopupMenuItem(value: 'logout', child: Text('Keluar', style: TextStyle(color: c.destructive))),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: mobile ? 15 : 17, backgroundColor: c.primary, child: Text(inisial(nama), style: TextStyle(fontSize: mobile ? 11 : 12, fontWeight: FontWeight.w700, color: Colors.white))),
                if (!narrow) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(nama.split(' ').first, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: mobile ? 14 : 15, fontWeight: FontWeight.w600)),
                  ),
                ],
                Icon(Icons.keyboard_arrow_down, size: mobile ? 16 : 18, color: c.mutedForeground),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Palet perintah (Ctrl/⌘ + K): lompat cepat ke halaman mana pun.
class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.items, required this.onSelect});

  final List<NavItem> items;
  final ValueChanged<String> onSelect;

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final results = widget.items.where((i) => i.label.toLowerCase().contains(_q.toLowerCase())).toList();
    return Dialog(
      alignment: const Alignment(0, -.6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                onSubmitted: (_) {
                  if (results.isNotEmpty) {
                    Navigator.pop(context);
                    widget.onSelect(results.first.path);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Cari halaman…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                ),
              ),
            ),
            Flexible(
              child: results.isEmpty
                  ? Padding(padding: const EdgeInsets.all(24), child: Text('Tidak ada hasil', style: TextStyle(color: c.mutedForeground)))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final i in results)
                          ListTile(
                            leading: Icon(i.icon, size: 20),
                            title: Text(i.label),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSelect(i.path);
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Navigasi bawah untuk HP: mudah dijangkau jempol.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.items, required this.location, required this.onSelected});

  final List<NavItem> items;
  final String location;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final index = items.indexWhere((i) => location == i.path || location.startsWith('${i.path}/'));
    return Container(
      decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.border))),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: c.card,
          surfaceTintColor: Colors.transparent,
          indicatorColor: c.primary.withValues(alpha: .12),
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 11,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? c.primary : c.mutedForeground,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? c.primary : c.mutedForeground),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index < 0 ? 0 : index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => onSelected(items[i].path),
          destinations: [for (final i in items) NavigationDestination(icon: Icon(i.icon), label: i.short)],
        ),
      ),
    );
  }
}
