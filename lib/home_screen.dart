import 'package:flutter/material.dart';
import 'package:untitled/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Импорт для работы с изображениями
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Загрузка...";
  String userPhoneNumber = "Загрузка...";
  List<dynamic> posts = [];
  Timer? _timer;
  File? _selectedImage; // Для хранения выбранного изображения
  String? userPhotoUrl;
  Set<String> viewedPostIds = Set<String>();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchPosts();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchUserData();
      fetchPosts();
    });
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('http://95.163.223.203:3000/home/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['user_name'] ?? "Неизвестный пользователь";
          userPhoneNumber = data['user_phone_number'] ?? "Не указан номер телефона";
          userPhotoUrl = data['avatar_url']; // Получаем только имя файла
        });
      } else {
        setState(() {
          userName = "Ошибка загрузки";
          userPhoneNumber = "Попробуйте позже";
        });
      }
    } catch (error) {
      setState(() {
        userName = "Ошибка сети";
        userPhoneNumber = "Нет соединения";
      });
    }
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('http://95.163.223.203:3000/posts'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            posts = data;
          });
        } else {
          throw FormatException("Неверная структура данных");
        }
      } else {
        throw Exception("Ошибка ответа от сервера: ${response.statusCode}");
      }
    } catch (error) {
      setState(() {
        posts = [];
      });
      print('Ошибка загрузки постов: $error');
    }
  }

  Future<void> incrementPostViews(String postId) async {
    if (viewedPostIds.contains(postId)) {
      print("Пост с ID $postId уже был просмотрен, пропускаем обновление просмотров.");
      return;  // Если пост уже был просмотрен, не увеличиваем просмотры
    }

    try {
      final response = await http.patch(
        Uri.parse('http://95.163.223.203:3000/posts/$postId/views'),
      );

      print("Request sent to increment views for post ID: $postId");
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          viewedPostIds.add(postId);  // Добавляем ID поста в список просмотренных
        });
        fetchPosts();  // После увеличения просмотров обновляем список постов
        print("Views incremented successfully for post ID: $postId");
      } else {
        print("Error: Server responded with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error incrementing post views: $error");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  String formatDateAndTime(String date, String time) {
    try {
      DateTime dateTime = DateFormat('yyyy-MM-dd').parse(date).toLocal();
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
      String formattedTime = time; // Предполагаем, что время уже в правильном формате
      return '$formattedDate $formattedTime';
    } catch (e) {
      return "Ошибка формата времени";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ЗГ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: posts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          var post = posts[index];
          return VisibilityDetector(
            key: Key('post-${post['post_id']}'),
            onVisibilityChanged: (visibilityInfo) {
              // Условие: пост виден более чем на 50%
              if (visibilityInfo.visibleFraction > 0.5) {
                // Когда пост виден, увеличиваем количество просмотров
                incrementPostViews(post['post_id'].toString());
              }
            },
            child: GestureDetector(
              onTap: () => incrementPostViews(post['post_id'].toString()),
              child: Card(
                color: Colors.grey[800],
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: post['avatar_url'] != null
                                ? NetworkImage('http://95.163.223.203:3000${post['avatar_url']}')
                                : null,
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['user_name'] ?? "Неизвестный пользователь",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${post['user_acctag'] ?? "unknown"}',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (post['post_picture'] != null && post['post_picture'].isNotEmpty)
                        Image.network(
                          '${post['post_picture']}',
                          fit: BoxFit.cover,
                        ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MarkdownBody(
                          data: post['post_text'] ?? "",
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDateAndTime(post['post_date'], post['post_time']),
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Row(
                            children: [
                              Icon(Icons.remove_red_eye),
                              SizedBox(width: 5),
                              Text(post['post_views'].toString()), // Преобразование числа в строку
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPostDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(userName),
            accountEmail: Text(userPhoneNumber),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green,
              backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                  ? NetworkImage('http://95.163.223.203:3000$userPhotoUrl')
                  : null,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ListTile(
            title: Text('Профиль'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)),
              );
            },
          ),
          ListTile(
            title: Text('Настройки'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen(userId: widget.userId)),
              );
            },
          ),
          ListTile(
            title: Text('Выход'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddPostDialog(BuildContext context) {
    TextEditingController postController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Новый пост',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: postController,
                  style: TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Введите текст поста...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo),
                      label: Text('Выбрать фото'),
                    ),
                    if (_selectedImage != null)
                      Text('Фото выбрано', style: TextStyle(color: Colors.green)),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                    ),
                    onPressed: () {
                      _createPost(postController.text);
                      Navigator.pop(context);
                      _selectedImage = null;
                    },
                    child: Text('Создать')
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> uploadPostImage(File imageFile) async {
    try {
      String mimeType = 'application/octet-stream';  // Значение по умолчанию
      if (imageFile.path.endsWith('.jpg') || imageFile.path.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (imageFile.path.endsWith('.png')) {
        mimeType = 'image/png';
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://95.163.223.203:3000/upload-post-picture'),
      );

      /// Добавление файла в запрос с правильным MIME-типом
      var multipartFile = await http.MultipartFile.fromPath(
        'post_picture',  // Параметр, который ожидает сервер
        imageFile.path,
        contentType: MediaType.parse(mimeType),  // Указываем MIME-тип
      );

      // Добавление multipartFile в запрос
      request.files.add(multipartFile);


      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        return data['picture_url'];  // Возвращаем URL изображения
      } else {
        print('Ошибка загрузки изображения');
        return null;
      }
    } catch (error) {
      print("Ошибка сети: $error");
      return null;
    }
  }

  Future<void> _createPost(String text) async {
    try {
      // Получаем текущее время и дату
      DateTime now = DateTime.now().toLocal();
      String currentDate = DateFormat('yyyy-MM-dd').format(now);
      String currentTime = DateFormat('HH:mm:ss').format(now);

      String? imageUrl;

      // Загружаем изображение, если оно выбрано
      if (_selectedImage != null) {
        imageUrl = await uploadPostImage(_selectedImage!); // Загружаем изображение для поста
        if (imageUrl == null) {
          print('Ошибка при загрузке изображения');
          return;
        }
      }

      // Проверяем, что хотя бы одно поле заполнено
      if (text.trim().isEmpty && imageUrl == null) {
        print('Ошибка: текст и изображение не могут быть пустыми одновременно');
        return;
      }

      // Отправляем пост с изображением
      final response = await http.post(
        Uri.parse('http://95.163.223.203:3000/add_posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'user_name': userName,
          'post_text': text.isEmpty ? null : text,
          'post_date': currentDate,
          'post_time': currentTime,
          'post_picture': imageUrl, // Добавляем URL изображения, если оно есть
        }),
      );

      if (response.statusCode == 201) {
        print('Пост успешно добавлен');
        fetchPosts(); // Обновляем список постов
        setState(() {
          _selectedImage = null; // Сбрасываем выбранное изображение
        });
      } else {
        print('Ошибка при создании поста. Статус: ${response.statusCode}');
      }
    } catch (error) {
      print('Ошибка при создании поста: $error');
    }
  }
}