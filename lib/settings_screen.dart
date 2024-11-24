import 'dart:io'; // Для работы с файлами
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для работы с FilteringTextInputFormatter
import 'package:image_picker/image_picker.dart'; // Для выбора изображения
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; // Импорт экрана для логина
import 'package:http_parser/http_parser.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  SettingsScreen({required this.userId});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = "Загрузка...";
  String userIdDisplay = "@Загрузка...";
  String userPhoneNumber = "Загрузка...";
  String? userPhotoUrl;

  TextEditingController nameController = TextEditingController();
  TextEditingController idController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Загружаем данные при старте экрана
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('http://95.163.223.203:3000/settings/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['user_name'] ?? "Неизвестный пользователь";
          userIdDisplay = data['user_acctag'] ?? "@Неизвестный";
          userPhoneNumber = data['user_phone_number'] ?? "Неизвестно";
          userPhotoUrl = data['avatar_url']; // Получаем только имя файла
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки данных")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети")),
      );
    }
  }

  Future<void> updateUserData(String field, String value) async {
    try {
      final Map<String, String> updateData = {};
      if (field == "name" && value.isNotEmpty) updateData['user_name'] = value;
      if (field == "phone" && value.isNotEmpty) updateData['user_phone_number'] = value;
      if (field == "acctag" && value.isNotEmpty) updateData['user_acctag'] = value;

      if (updateData.isEmpty) {
        return;
      }

      final response = await http.patch(
        Uri.parse('http://95.163.223.203:3000/settings/${widget.userId}'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (field == "name") userName = value;
          if (field == "phone") userPhoneNumber = value;
          if (field == "acctag") userIdDisplay = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Данные успешно обновлены")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка обновления данных")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети: данные не обновлены")),
      );
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    try {
      // Чтение файла как bytes
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Создание multipart-запроса
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://95.163.223.203:3000/upload-avatar/${widget.userId}'),
      );

      // Добавление файла к запросу
      request.files.add(http.MultipartFile.fromBytes(
        'avatar', // Имя параметра на сервере
        imageBytes,
        filename: imageFile.path.split('/').last, // Имя файла
        contentType: MediaType('image', 'jpeg'), // Задайте тип MIME
      ));

      // Отправка запроса
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        setState(() {
          userPhotoUrl = data['user_avatar'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Фото успешно обновлено")),
        );
      } else {
        final responseData = await response.stream.bytesToString();
        print("Ошибка загрузки фото: $responseData");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки фото")),
        );
      }
    } catch (error) {
      print("Ошибка сети: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети: фото не загружено")),
      );
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await uploadAvatar(imageFile);
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('http://95.163.223.203:3000/settings/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()), // Переход на экран логина
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка удаления аккаунта")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети: аккаунт не удален")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                        ? NetworkImage('http://95.163.223.203:3000$userPhotoUrl')
                        : null,
                    child: userPhotoUrl == null
                        ? Text(
                      userName.isNotEmpty
                          ? userName[0].toUpperCase()
                          : "?",
                      style:
                      TextStyle(fontSize: 40, color: Colors.white),
                    )
                        : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: pickImage,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Изменить имя',
                style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => _editField("Имя пользователя", userName, "name"),
              child: Text(userName, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 8),
            Text('Изменить id пользователя',
                style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () =>
                  _editField("ID пользователя", userIdDisplay, "acctag"),
              child: Text(userIdDisplay, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 8),
            Text('Изменить номер телефона',
                style: TextStyle(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () =>
                  _editField("Номер телефона", userPhoneNumber, "phone"),
              child: Text(userPhoneNumber, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _confirmDeleteAccount();
              },
              child: Text(
                'Удалить аккаунт',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editField(String title, String currentValue, String field) {
    TextEditingController controller = TextEditingController(
        text: field == "acctag"
            ? currentValue.replaceAll("@", "")
            : currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Изменить $title"),
          content: TextField(
            controller: controller,
            keyboardType:
            field == "phone" ? TextInputType.number : TextInputType.text,
            inputFormatters: field == "phone"
                ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11), // Ограничение на 11 цифр
            ]
                : [],
            decoration: InputDecoration(
              hintText: field == "phone"
                  ? "Введите новый номер (11 цифр)"
                  : "Введите новое значение",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена"),
            ),
            TextButton(
              onPressed: () {
                String newValue = controller.text.trim();
                if (field == "phone" && newValue.length != 11) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                        Text("Номер телефона должен содержать 11 цифр")),
                  );
                  return; // Прерываем сохранение, если номер некорректен
                } else if (field == "acctag" && newValue.contains(" ")) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("ID не должен содержать пробелы")),
                  );
                  return;
                }
                if (field == "acctag" && !newValue.startsWith("@")) {
                  newValue = "@$newValue"; // Добавляем @, если его нет
                }
                updateUserData(field, newValue);
                Navigator.pop(context);
              },
              child: Text("Сохранить"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Удалить аккаунт?"),
          content: Text("Это действие удалит ваш аккаунт без возможности восстановления."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Отмена"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              child: Text("Удалить", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
