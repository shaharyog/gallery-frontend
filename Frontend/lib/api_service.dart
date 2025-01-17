import 'dart:convert';
import 'package:gallery/album.dart';
import 'package:gallery/exceptions.dart';
import 'package:gallery/picture.dart';
import 'package:gallery/user.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  // data retrieval methods
  Future<List<Album>> getAlbums() async {
    final response = await http.get(Uri.parse('$baseUrl/get_albums'));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body) == null) {
        return [];
      }
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.map((json) => Album.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load albums');
    }
  }

  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/get_users'));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body) == null) {
        return [];
      }
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List<Album>> getAlbumsOfUser(int userId) async {
    final response = await http.post(Uri.parse('$baseUrl/get_albums_of_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body) == null) {
        return [];
      }
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.map((json) => Album.fromJson(json)).toList();
    } else if (response.statusCode == 404 && response.body.startsWith("User")) {
      throw UserNotFoundException();
    } else {
      throw Exception('Failed to load albums of user');
    }
  }

  Future<User> getUser(int userId) async {
    final response = await http.post(Uri.parse('$baseUrl/get_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId}));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return User.fromJson(json);
    } else if (response.statusCode == 404 && response.body.startsWith("User")) {
      throw UserNotFoundException();
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<int> getCountTagsOfUser(int userId) async {
    final response = await http.post(
        Uri.parse('$baseUrl/get_count_tags_of_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId}));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['count'];
    } else if (response.statusCode == 404 && response.body.startsWith("User")) {
      throw UserNotFoundException();
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<List<Picture>> getAlbumPictures(int ownerId, String albumName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get_album_pictures'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'owner_id': ownerId, 'album_name': albumName}),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body) == null) {
        return [];
      }
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.map((json) => Picture.fromJson(json)).toList();
    } else if (response.statusCode == 404 &&
        response.body.startsWith("Album")) {
      throw AlbumNotFoundException();
    } else {
      throw Exception('Failed to load album pictures');
    }
  }

  Future<List<User>> getPictureTags(int id, String pictureName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get_picture_tags'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'name': pictureName}),
    );
    if (response.statusCode == 200) {
      if (jsonDecode(response.body) == null) {
        return [];
      }
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else if (response.statusCode == 404 &&
        response.body.startsWith("Picture")) {
      throw PictureNotFoundException();
    } else {
      throw Exception('Failed to load picture tags');
    }
  }

  // data creation methods
  Future<bool> createAlbum(String name, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_album'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'user_id': userId}),
    );
    if (response.statusCode == 200) {
      return true;
    }
    if (response.statusCode == 404 && response.body.startsWith("User")) {
      throw UserNotFoundException();
    } else if (response.statusCode == 409 &&
        response.body.startsWith("Album")) {
      throw AlbumAlreadyExistsException();
    } else {
      throw Exception('Failed to create album');
    }
  }

  Future<bool> createUser(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 409 && response.body.startsWith("User")) {
      throw UserAlreadyExistsException();
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<bool> tagUserInPicture(
      String albumName, String pictureName, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tag_user_in_picture'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'album_name': albumName,
        'picture_name': pictureName,
        'user_id': userId
      }),
    );
    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 404 && response.body.startsWith("Picture")) {
      throw PictureNotFoundException();
    } else if (response.statusCode == 404 && response.body.startsWith("User")) {
      throw UserNotFoundException();
    } else if (response.statusCode == 409 && response.body.startsWith("Tag")) {
      throw TagAlreadyExistsException();
    } else {
      throw Exception('Failed to tag user in picture');
    }
  }

  Future<bool> addPictureToAlbum(
      String albumName, String pictureName, String path) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_picture_to_album'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'album_name': albumName, 'picture_name': pictureName, 'path': path}),
    );
    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 404 && response.body.startsWith("Album")) {
      throw AlbumNotFoundException();
    } else if (response.statusCode == 409 &&
        response.body.startsWith("Picture")) {
      throw PictureAlreadyExistsException();
    } else {
      throw Exception('Failed to add picture to album');
    }
  }

  // data deletion methods
  Future<bool> clearDB() async {
    final response = await http.delete(Uri.parse('$baseUrl/clear_db'));
    return response.statusCode == 200;
  }

  Future<bool> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': userId}),
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 404 && response.body.startsWith("User")) {
      throw UserNotFoundException();
    } else {
      throw Exception('Failed to delete user');
    }
  }

  Future<bool> deleteAlbum(String name, int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_album'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 404 && response.body.startsWith("Album")) {
      throw AlbumNotFoundException();
    } else {
      throw Exception('Failed to delete album');
    }
  }

  Future<bool> removePictureFromAlbum(
      String albumName, String pictureName) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/remove_picture_from_album'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'album_name': albumName, 'picture_name': pictureName}),
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 404 && response.body.startsWith("Album")) {
      throw AlbumNotFoundException();
    } else if (response.statusCode == 404 &&
        response.body.startsWith("Picture")) {
      throw PictureNotFoundException();
    } else {
      throw Exception('Failed to remove picture from album');
    }
  }

  Future<bool> untagUserInPicture(
      String albumName, String pictureName, int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/untag_user_in_picture'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'album_name': albumName,
        'picture_name': pictureName,
        'user_id': userId
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (response.statusCode == 404 && response.body.startsWith("Picture")) {
      throw PictureNotFoundException();
    } else if (response.statusCode == 404 && response.body.startsWith("User")) {
      throw UserNotFoundException();
    } else if (response.statusCode == 404 && response.body.startsWith("Tag")) {
      throw TagNotFoundException();
    } else if (response.statusCode == 404 &&
        response.body.startsWith("Album")) {
      throw AlbumNotFoundException();
    } else {
      throw Exception('Failed to untag user in picture');
    }
  }
}
