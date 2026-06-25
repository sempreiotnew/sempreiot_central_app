import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../../../presentation/screens/main/main_screen.dart';
import '../../../../shared/widgets/app_search_bar.dart';

class CentralItem {
  const CentralItem({
    required this.id,
    required this.name,
    required this.location,
    required this.deviceCount,
    required this.isOnline,
  });

  final String id;
  final String name;
  final String location;
  final int deviceCount;
  final bool isOnline;
}

// TODO: Replace with API call (Lambda function)
List<CentralItem> _fetchMockCentrals() => const [
      CentralItem(
        id: 'central-001',
        name: 'Central Bloco A',
        location: 'Edifício Principal — Piso 1',
        deviceCount: 12,
        isOnline: true,
      ),
      CentralItem(
        id: 'central-002',
        name: 'Central Bloco B',
        location: 'Edifício Principal — Piso 2',
        deviceCount: 8,
        isOnline: true,
      ),
      CentralItem(
        id: 'central-003',
        name: 'Central Garagem',
        location: 'Subsolo — Nível B1',
        deviceCount: 5,
        isOnline: false,
      ),
    ];

class CentralsListScreen extends StatefulWidget {
  const CentralsListScreen({super.key});

  @override
  State<CentralsListScreen> createState() => _CentralsListScreenState();
}

class _CentralsListScreenState extends State<CentralsListScreen> {
  final _allCentrals = _fetchMockCentrals();
  List<CentralItem> _filtered = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = _allCentrals;
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? _allCentrals
          : _allCentrals
              .where(
                (c) =>
                    c.name.toLowerCase().contains(q) ||
                    c.location.toLowerCase().contains(q),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Centrais',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: context.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppSearchBar(
              hintText: 'Buscar por nome ou localização...',
              onChanged: _onSearch,
            ),
          ),

          // ── Count badge ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  _filtered.isEmpty
                      ? 'Nenhuma central encontrada'
                      : '${_filtered.length} central${_filtered.length == 1 ? '' : 'is'}',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_query.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    'para "$_query"',
                    style: TextStyle(
                      color: AppColors.secondary.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(query: _query)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _CentralCard(
                      item: _filtered[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MainScreen(centralId: _filtered[i].id),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 28,
                color: context.textSecondary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Não encontramos nada para "$query".',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Central card ──────────────────────────────────────────────────────────────

class _CentralCard extends StatelessWidget {
  const _CentralCard({required this.item, required this.onTap});

  final CentralItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isOnline ? AppColors.success : AppColors.error;
    final statusLabel = item.isOnline ? 'Online' : 'Offline';

    return Material(
      color: context.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.borderColor.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.sensors_rounded, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.location,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.devices_rounded,
                          size: 12,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.deviceCount} dispositivos',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
