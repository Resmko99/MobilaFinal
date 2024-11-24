import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Загрузка...";
  String userPhoneNumber = "Загрузка...";
  String userAcctag = "Загрузка...";
  String? userPhotoUrl;
  List<dynamic> userPosts = [];
  bool isLoadingPosts = true; // Флаг для индикатора загрузки

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUserPosts();
  }

  // Загружаем данные пользователя
  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('http://95.163.223.203:3000/profile/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          userName = data['user_name'] ?? "Неизвестный пользователь";
          userPhoneNumber = data['user_phone_number'] ?? "Не указан номер телефона";
          userAcctag = data['user_acctag'] ?? "@Неизвестный";
          userPhotoUrl = data['avatar_url'];
        });
      } else {
        setState(() {
          userName = "Ошибка загрузки";
          userPhoneNumber = "Попробуйте позже";
          userAcctag = "@Ошибка";
          userPhotoUrl = null;
        });
      }
    } catch (error) {
      setState(() {
        userName = "Ошибка сети";
        userPhoneNumber = "Нет соединения";
        userAcctag = "@Нет соединения";
        userPhotoUrl = null;
      });
    }
  }

  // Загружаем публикации пользователя
  Future<void> fetchUserPosts() async {
    try {
      final response = await http.get(Uri.parse('http://95.163.223.203:3000/posts/user/${widget.userId}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          userPosts = data;  // Присваиваем весь массив публикаций
          isLoadingPosts = false; // Завершаем индикатор загрузки
        });
      } else {
        setState(() {
          userPosts = [];
          isLoadingPosts = false;
        });
      }
    } catch (error) {
      setState(() {
        userPosts = [];
        isLoadingPosts = false;
      });
      print('Ошибка загрузки публикаций: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Делает весь контент прокручиваемым
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фотография профиля
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                      ? NetworkImage(
                      userPhotoUrl!.startsWith('http')
                          ? userPhotoUrl!
                          : 'http://95.163.223.203:3000$userPhotoUrl'
                  )
                      : null,
                  child: userPhotoUrl == null || userPhotoUrl!.isEmpty
                      ? Text(
                    widget.userId.isNotEmpty ? widget.userId[0] : '?',
                    style: TextStyle(fontSize: 40, color: Colors.white),
                  )
                      : null,
                ),
              ),
              SizedBox(height: 16),
              Text('Имя', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(userName),
              SizedBox(height: 8),
              Text('id пользователя', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(userAcctag),
              SizedBox(height: 8),
              Text('Номер телефона', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(userPhoneNumber),
              SizedBox(height: 16),

              // Публикации
              Text('Публикации', style: TextStyle(fontWeight: FontWeight.bold)),
              // Если публикации загружаются, показываем индикатор
              isLoadingPosts
                  ? Center(child: CircularProgressIndicator())
                  : userPosts.isEmpty
                  ? Center(child: Text("Нет публикаций"))
                  : GridView.builder(
                shrinkWrap: true, // Запрещаем GridView занимать всю высоту
                physics: NeverScrollableScrollPhysics(), // Отключаем прокрутку
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: userPosts.length,
                itemBuilder: (context, index) {
                  final post = userPosts[index];

                  // Проверка наличия изображения
                  String postImageUrl = post['post_picture'] ?? '';
                  String postTitle = post['post_text'] ?? 'Без названия';

                  return Container(
                    color: Colors.blueGrey[800],
                    child: Column(
                      children: [
                        // Показываем изображение только если оно есть
                        if (postImageUrl.isNotEmpty)
                          Image.network(
                            postImageUrl!.startsWith('http')
                                ? postImageUrl
                                : 'http://95.163.223.203:3000$postImageUrl',
                            fit: BoxFit.cover,
                            height: 100,
                            width: double.infinity,
                          ),
                        // Показываем текст с использованием Markdown
                        SizedBox(height: postImageUrl.isNotEmpty ? 8 : 0),
                        Expanded(
                          child: MarkdownBody(
                            data: postTitle, // Здесь будет текст с Markdown
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
