import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? minLines;
  
  // 1. ADICIONADO AQUI: A variável que vai receber a função
  final void Function(String)? onChanged; 

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    
    // 2. ADICIONADO AQUI: O parâmetro no construtor
    this.onChanged, 
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      maxLines: _obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      validator: widget.validator,
      
      // 3. ADICIONADO AQUI: Repassando a função para o TextFormField nativo
      onChanged: widget.onChanged, 
      
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText ?? widget.label,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: const Color(0xFF9CA3AF))
            : null,
        suffixIcon: widget.suffixIcon != null || widget.obscureText
            ? widget.obscureText
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    child: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF9CA3AF),
                    ),
                  )
                : GestureDetector(
                    onTap: widget.onSuffixTap,
                    child: Icon(widget.suffixIcon,
                        color: const Color(0xFF9CA3AF)),
                  )
            : null,
      ),
    );
  }
}