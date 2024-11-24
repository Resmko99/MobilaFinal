import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart'; // Импортируйте ваш главный экран
import 'package:flutter/services.dart'; // Этот импорт необходим для работы с FilteringTextInputFormatter и LengthLimitingTextInputFormatter

class RegisterScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> registerUser(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    try {
      // Отправка данных на сервер
      final response = await http.post(
        Uri.parse('http://95.163.223.203:3000/register'), // Замените на ваш адрес сервера
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_phone_number': email, 'user_password': password}),
      );

      if (response.statusCode == 201) {
        // Декодируем ответ и получаем userId
        final responseData = jsonDecode(response.body);
        final userId = responseData['user_id'].toString(); // Преобразуем в строку

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Регистрация успешна')),
        );

        // После успешной регистрации переходим на главный экран с userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId), // Передаем userId как строку
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка соединения с сервером')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(45 * 3.1416 / 180), // Поворот на 45 градусов
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'ЗГ',
                  style: TextStyle(
                    fontSize: 30, // Размер шрифта
                    color: Colors.white, // Цвет текста
                    fontWeight: FontWeight.bold, // Жирный шрифт
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.number, // Ограничивает ввод на уровне клавиатуры
              inputFormatters: [
                // Ограничение на ввод только 11 цифр
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                labelText: 'Номер телефона (11 цифр)',
                border: OutlineInputBorder(),
                hintText: 'Например: 89001234567',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Повторите пароль',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                registerUser(context);
              },
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
