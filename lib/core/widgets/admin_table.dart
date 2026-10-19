import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/simmas_colors.dart';
import 'admin_ui.dart';

class Col<T> {
  const Col(this.label, this.cell, {this.flex = 1, this.align = Alignment.centerLeft});

  final String label;
  final Widget Function(T item) cell;
  final double flex;
  final Alignment align;
}

/// Tabel responsif:
///  - Desktop       : tabel dengan header, checkbox, menu aksi, paginasi.
///  - Tablet        : tabel yang bisa di-scroll ke samping (min. [minWidth]).
///  - HP (< [mobileBreakpoint]) : otomatis menjadi DAFTAR KARTU. Kolom
///    [mobilePrimary] menjadi judul kartu, kolom lain tampil sebagai baris
///    "LABEL: nilai". Tidak perlu scroll horizontal.
class AdminTable<T> extends StatefulWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.menuBuilder,
    this.onMenuSelected,
    this.selectable = true,
    this.minWidth = 960,
    this.emptyText = 'Tidak ada data.',
    this.showPager = true,
    this.mobilePrimary = 0,
    this.mobileBreakpoint = 600,
  });

  final List<Col<T>> columns;
  final List<T> rows;
  final List<PopupMenuEntry<String>> Function(T item)? menuBuilder;
  final void Function(String action, T item)? onMenuSelected;
  final bool selectable;
  final double minWidth;
  final String emptyText;
  final bool showPager;

  /// Indeks kolom yang dipakai sebagai judul kartu di layar HP.
  final int mobilePrimary;
  final double mobileBreakpoint;

  @override
  State<AdminTable<T>> createState() => _AdminTableState<T>();
}

class _AdminTableState<T> extends State<AdminTable<T>> {
  final Set<int> _selected = {};
  int _page = 0;
  int _pageSize = 10;

  @override
  void didUpdateWidget(covariant AdminTable<T> old) {
    super.didUpdateWidget(old);
    if (old.rows.length != widget.rows.length) {
      _selected.clear();
      _page = 0;
    }
  }

  int get _pages => math.max(1, (widget.rows.length / _pageSize).ceil());

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    final total = widget.rows.length;
    final start = math.min(_page * _pageSize, total);
    final end = math.min(total, start + _pageSize);
    final visible = widget.rows.sublist(start, end);

    return LayoutBuilder(
      builder: (context, cons) {
        if (cons.maxWidth < widget.mobileBreakpoint) {
          return _mobileList(c, visible, total, start, end);
        }
        return _desktopTable(c, cons, visible, total, start, end);
      },
    );
  }

  // ─────────────────────────── HP: daftar kartu ───────────────────────────

  Widget _mobileList(SimmasColors c, List<T> visible, int total, int start, int end) {
    final primaryIndex = widget.mobilePrimary.clamp(0, widget.columns.length - 1).toInt();
    final primary = widget.columns[primaryIndex];
    final others = [for (var i = 0; i < widget.columns.length; i++) if (i != primaryIndex) widget.columns[i]];
    final hasMenu = widget.menuBuilder != null;

    Widget card(T item) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border), boxShadow: kPanelShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 4, right: 8), child: Align(alignment: Alignment.centerLeft, child: primary.cell(item)))),
                  if (hasMenu)
                    PopupMenuButton<String>(
                      tooltip: 'Aksi',
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_horiz, color: c.mutedForeground),
                      itemBuilder: (_) => widget.menuBuilder!(item),
                      onSelected: (a) => widget.onMenuSelected?.call(a, item),
                    ),
                ],
              ),
              for (final col in others)
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(col.label.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: .6, color: c.mutedForeground)),
                        ),
                      ),
                      Expanded(child: Align(alignment: Alignment.centerLeft, child: col.cell(item))),
                    ],
                  ),
                ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (visible.isEmpty)
          Container(
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: EmptyState(widget.emptyText),
          )
        else
          for (final item in visible) card(item),
        if (widget.showPager && total > 0)
          Container(
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: _pager(c, total, start, end),
          ),
      ],
    );
  }

  // ─────────────────────── Desktop / tablet: tabel ───────────────────────

  Widget _desktopTable(SimmasColors c, BoxConstraints cons, List<T> visible, int total, int start, int end) {
    final hasMenu = widget.menuBuilder != null;

    Widget headerCell(String label, double flex, Alignment align) => Expanded(
          flex: (flex * 100).round(),
          child: Align(
            alignment: align,
            child: Text(label.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: c.mutedForeground)),
          ),
        );

    Widget buildRow(T? item, int index, {bool header = false}) {
      final globalIndex = start + index;
      return Container(
        constraints: BoxConstraints(minHeight: header ? 56 : 68),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: header ? c.background : null,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            if (widget.selectable)
              SizedBox(
                width: 44,
                child: Checkbox(
                  value: header ? (_selected.length == visible.length && visible.isNotEmpty) : _selected.contains(globalIndex),
                  onChanged: (v) => setState(() {
                    if (header) {
                      if (v == true) {
                        _selected.addAll([for (var i = 0; i < visible.length; i++) start + i]);
                      } else {
                        _selected.clear();
                      }
                    } else {
                      v == true ? _selected.add(globalIndex) : _selected.remove(globalIndex);
                    }
                  }),
                  side: BorderSide(color: c.border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            for (final col in widget.columns)
              header
                  ? headerCell(col.label, col.flex, col.align)
                  : Expanded(
                      flex: (col.flex * 100).round(),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Align(alignment: col.align, child: col.cell(item as T)),
                      ),
                    ),
            if (hasMenu)
              SizedBox(
                width: 56,
                child: header
                    ? Align(alignment: Alignment.centerRight, child: Text('AKSI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: c.mutedForeground)))
                    : Align(
                        alignment: Alignment.centerRight,
                        child: PopupMenuButton<String>(
                          tooltip: 'Aksi',
                          icon: Icon(Icons.more_horiz, color: c.mutedForeground),
                          itemBuilder: (_) => widget.menuBuilder!(item as T),
                          onSelected: (a) => widget.onMenuSelected?.call(a, item as T),
                        ),
                      ),
              ),
          ],
        ),
      );
    }

    final table = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildRow(null, 0, header: true),
        if (visible.isEmpty) EmptyState(widget.emptyText),
        for (var i = 0; i < visible.length; i++) buildRow(visible[i], i),
      ],
    );

    final w = math.max(cons.maxWidth, widget.minWidth);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.border), boxShadow: kPanelShadow),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (w <= cons.maxWidth) table else SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: w, child: table)),
          if (widget.showPager) _pager(c, total, start, end),
        ],
      ),
    );
  }

  Widget _pager(SimmasColors c, int total, int start, int end) {
    Widget nav(IconData icon, VoidCallback? onTap) => Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
          child: IconButton(padding: EdgeInsets.zero, iconSize: 18, onPressed: onTap, icon: Icon(icon)),
        );
    final label = total == 0 ? 'Tidak ada data' : 'Menampilkan ${start + 1}–$end dari $total data';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 16,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.mutedForeground)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Baris:', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _pageSize,
                  isDense: true,
                  style: TextStyle(fontSize: 13, color: c.foreground),
                  items: const [10, 25, 50].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                  onChanged: (v) => setState(() {
                    _pageSize = v ?? 10;
                    _page = 0;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_page + 1}/$_pages', style: TextStyle(fontSize: 13, color: c.mutedForeground)),
              nav(Icons.chevron_left, _page > 0 ? () => setState(() => _page--) : null),
              nav(Icons.chevron_right, _page < _pages - 1 ? () => setState(() => _page++) : null),
            ],
          ),
        ],
      ),
    );
  }
}
