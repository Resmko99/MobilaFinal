import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Импортируем для работы с HTTP запросами
import 'home_screen.dart'; // Импортируем ваш главный экран
import 'dart:convert'; // Для кодирования и декодирования JSON

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Предопределенные учетные данные для тестового аккаунта
  final String testUsername = '@testuser';
  final String testPassword = 'password123';

  Future<void> _login(BuildContext context) async {
    final String username = usernameController.text;
    final String password = passwordController.text;

    // Отправляем запрос на сервер
    try {
      final response = await http.post(
        Uri.parse('http://95.163.223.203:3000/login'), // Адрес вашего сервера
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'identifier': username, // Отправляем либо номер телефона, либо user_acctag
          'user_password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Если запрос успешен, получаем user_id
        final Map<String, dynamic> data = json.decode(response.body);
        String userId = data['user_id']?.toString() ?? ''; // Преобразуем в строку

        // Переход на главный экран после успешного входа
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId), // Передаем user_id
          ),
        );
      } else {
        // Если ошибка на сервере
        final Map<String, dynamic> data = json.decode(response.body);
        _showErrorDialog(context, data['message']?.toString() ?? 'Неизвестная ошибка');
      }
    } catch (error) {
      // Если произошла ошибка при отправке запроса
      _showErrorDialog(context, 'Ошибка при подключении к серверу');
    }
  }

  // Функция для отображения ошибки
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ошибка входа'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
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
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Номер телефона или id',
                hintText: 'Например: @prilozh',
                border: OutlineInputBorder(),
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
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: Text('Я не помню свой пароль'),
            ),
            ElevatedButton(
              onPressed: () {
                _login(context); // Вызов функции для входа
              },
              child: Text('Войти'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('Нет аккаунта? Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
