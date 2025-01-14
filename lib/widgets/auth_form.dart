import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    Key? key,
    required this.onAuth,
    required this.authButtonText,
    required this.emailController,
    required this.passwordController,
  }) : super(key: key);

  final VoidCallback onAuth;
  final String authButtonText;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
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

        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: widget.onAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(widget.authButtonText),
        ),
        const SizedBox(height: 16.0),
        // Здесь вы можете добавить другие кнопки, если нужно.
      ],
    );
  }
}
