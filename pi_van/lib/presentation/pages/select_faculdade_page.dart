import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';

class SelectFaculdadePage extends StatefulWidget {
  const SelectFaculdadePage({super.key});

  @override
  State<SelectFaculdadePage> createState() => _SelectFaculdadePageState();
}

class _SelectFaculdadePageState extends State<SelectFaculdadePage> {
  final List<String> _faculdades = [
    'Faculdade Central',
    'Faculdade Norte',
    'Faculdade Sul',
    'Faculdade Leste',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildFaculdadesList(),
                const SizedBox(height: 40),
                AppButton(
                  label: 'Confirmar',
                  onPressed: _selected == null
                      ? null
                      : () {
                          Navigator.of(context).pushReplacementNamed(
                              AppRoutes.homeStudent);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 24),
        const Text(
          'Escolha sua faculdade',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Selecione a instituição que você estuda entre '
          'as faculdades atendidas por este motorista.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildFaculdadesList() {
    return Column(
      children: _faculdades
          .map(
            (faculdade) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFaculdadeCard(faculdade),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFaculdadeCard(String faculdade) {
    final isSelected = _selected == faculdade;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selected = faculdade;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE5E7EB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      color: Color(0xFF2563EB), size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faculdade,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Clique para selecionar',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
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
