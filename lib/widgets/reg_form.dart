import 'package:flutter/material.dart';

class RegForm extends StatefulWidget {
  const RegForm({
    Key? key,
    required this.onAuth,
    required this.authButtonText,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
  }) : super(key: key);

  final VoidCallback onAuth;
  final String authButtonText;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;

  @override
  State<RegForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<RegForm> {
  bool _isPasswordVisible = false; // Переменная для состояния видимости пароля

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          // Если необходимо, добавьте обработчик onChanged, но избегайте тяжелых операций здесь
        ),
        TextFormField(
          controller: widget.passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible =
                      !_isPasswordVisible; // Меняем видимость пароля
                });
              },
            ),
          ),
          obscureText: !_isPasswordVisible, // Устанавливаем видимость пароля
        ),
        TextFormField(
          controller: widget.passwordConfirmController,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible =
                      !_isPasswordVisible; // Меняем видимость пароля
                });
              },
            ),
          ),
          obscureText: !_isPasswordVisible, // Устанавливаем видимость пароля
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: widget.onAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 102, 0),
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
          child: Text(widget.authButtonText),
        ),
        const SizedBox(height: 16.0),
        // Здесь вы можете добавить другие кнопки, если нужно.
      ],
    );
  }
}
