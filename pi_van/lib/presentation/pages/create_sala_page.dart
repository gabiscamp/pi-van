import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class CreateSalaPage extends StatefulWidget {
  const CreateSalaPage({super.key});

  @override
  State<CreateSalaPage> createState() => _CreateSalaPageState();
}

class _CreateSalaPageState extends State<CreateSalaPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar sala')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Defina o nome da sua sala',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'A sala sera usada para vincular alunos e faculdades.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: 'Nome da sala',
              hintText: 'Ex: Van Manha',
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Criar sala',
              onPressed: () {
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.homeDriver);
              },
            ),
          ],
        ),
      ),
    );
  }
}
