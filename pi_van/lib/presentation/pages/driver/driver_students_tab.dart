import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

class DriverStudentsTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const DriverStudentsTab({super.key, required this.viewModel});
  @override
  State<DriverStudentsTab> createState() => _DriverStudentsTabState();
}

class _DriverStudentsTabState extends State<DriverStudentsTab> {
  String _filter = 'todos';

  // TODO: Substituir por stream do Firestore
  // salas/{salaId}/students + salas/{salaId}/attendance/{hoje}/votes
  final List<_MockStudent> _students = [];

  @override
  Widget build(BuildContext context) {
    final filtered = _filterStudents();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(
              child: filtered.isEmpty ? _buildEmptyState() : _buildStudentList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      color: AppTheme.background,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: AppTheme.radiusMd),
            child: const Icon(Icons.people_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meus Alunos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
                Text(
                  '${_students.length} alunos na sala',
                  style: const TextStyle(color: AppTheme.grey500, fontSize: 13),
                ),
              ],
            ),
          ),
          // Search button placeholder
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, border: Border.all(color: AppTheme.grey200)),
            child: const Icon(Icons.search_rounded, color: AppTheme.grey500, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'todos', 'label': 'Todos'},
      {'key': 'confirmados', 'label': 'Confirmados'},
      {'key': 'pendentes', 'label': 'Pendentes'},
      {'key': 'liberados', 'label': 'Liberados'},
      {'key': 'naoVai', 'label': 'Não vai'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: filters.map((f) {
            final selected = _filter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.white,
                    borderRadius: AppTheme.radiusFull,
                    border: Border.all(color: selected ? AppTheme.primary : AppTheme.grey200),
                  ),
                  child: Text(
                    f['label']!,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.grey600,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
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
              child: const Icon(Icons.people_outline_rounded, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Nenhum aluno ainda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Compartilhe o código da sala com seus alunos para que eles possam se cadastrar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildShareCodeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCodeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.share_rounded, color: AppTheme.primary, size: 18),
          SizedBox(width: 8),
          Text('Compartilhar código', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<_MockStudent> students) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: students.length,
      itemBuilder: (context, index) => _buildStudentCard(students[index]),
    );
  }

  Widget _buildStudentCard(_MockStudent student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
        border: student.liberado ? Border.all(color: AppTheme.success.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: student.liberado ? AppTheme.successGradient : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                student.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  student.faculdade ?? 'Sem faculdade',
                  style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
                ),
              ],
            ),
          ),
          // Status badge
          if (student.liberado)
            StatusBadge.released()
          else if (student.status == 'confirmado')
            StatusBadge.confirmed()
          else if (student.status == 'naoVai')
            StatusBadge.absent()
          else
            StatusBadge.pending(),
        ],
      ),
    );
  }

  List<_MockStudent> _filterStudents() {
    // TODO: Implementar filtragem real baseada no stream do Firestore
    return _students;
  }
}

class _MockStudent {
  final String name;
  final String? faculdade;
  final String status; // confirmado, pendente, naoVai
  final bool liberado;

  _MockStudent({required this.name, this.faculdade, this.status = 'pendente', this.liberado = false});
}
