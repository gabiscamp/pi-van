import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

class RouteBuilderPage extends StatefulWidget {
  const RouteBuilderPage({super.key});
  @override
  State<RouteBuilderPage> createState() => _RouteBuilderPageState();
}

class _RouteBuilderPageState extends State<RouteBuilderPage> {
  // TODO: Carregar alunos confirmados para ida/volta do Firestore
  // Cada item será um card arrastável representando uma parada
  List<_RouteStop> _stops = [];
  bool _optimizing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Montar Rota'),
        backgroundColor: AppTheme.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _optimizeRoute,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: const Text('Otimizar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: AppTheme.primaryLight,
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      body: _stops.isEmpty ? _buildEmptyState() : _buildRouteList(),
      bottomNavigationBar: _stops.isNotEmpty ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.alt_route_rounded, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Nenhuma parada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'As paradas serão carregadas automaticamente com base nos alunos que confirmaram presença para hoje.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.infoLight, borderRadius: AppTheme.radiusLg),
              child: const Column(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Integração pendente: Na sprint de integração, os endereços dos alunos confirmados e as faculdades serão carregados aqui como cards arrastáveis. Use o botão "Otimizar" para calcular o melhor percurso via OSRM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.info, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteList() {
    return Column(
      children: [
        // Info bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.infoLight, borderRadius: AppTheme.radiusMd),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Arraste os cards para reordenar as paradas. Use "Otimizar" para o melhor percurso.',
                  style: TextStyle(color: AppTheme.info.withOpacity(0.8), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _stops.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _stops.removeAt(oldIndex);
                _stops.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final stop = _stops[index];
              return Container(
                key: ValueKey(stop.id),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: AppTheme.radiusLg,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: stop.isFaculdade ? AppTheme.successGradient : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: Text(stop.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusMd),
                      child: const Icon(Icons.drag_handle_rounded, color: AppTheme.grey400, size: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_stops.length} paradas', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Text('Rota pronta para iniciar', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Salvar rota e navegar para active_route
            },
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _optimizeRoute() async {
    setState(() => _optimizing = true);
    // TODO: Chamar OSRM /trip endpoint com coords dos stops
    // router.project-osrm.org/trip/v1/driving/{coords}?source=first&roundtrip=false
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _optimizing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rota otimizada!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _RouteStop {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final bool isFaculdade;

  _RouteStop({required this.id, required this.name, required this.address, this.lat = 0, this.lng = 0, this.isFaculdade = false});
}
