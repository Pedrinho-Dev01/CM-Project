import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {

  @HiveField(0)
  String username;

  @HiveField(1)
  String password;

  @HiveField(2)
  double width;

  @HiveField(3)
  double height;

  @HiveField(4)
  double latitude;

  @HiveField(5)
  double longitude;

  @HiveField(6)
  String lastValue;

  @HiveField(7)
  double temperature;

  @HiveField(8)
  double humidity;

  @HiveField(9)
  double pressure;

  @HiveField(10)
  double lux;

  User({required this.username, 
        required this.password, 
        required this.width, 
        required this.height, 
        required this.latitude, 
        required this.longitude, 
        required this.lastValue,
        this.temperature = 0.0,
        this.humidity = 0.0,
        this.pressure = 0.0,
        this.lux = 0.0});
}

Future<void> addDefaultUser() async {

  var box = await Hive.openBox<User>('userBox');

  if (box.isEmpty) {
    box.add(User(username: 'user1', password: 'password1', width: 80.0, height: 80.0, latitude: 40.6405, longitude: -8.6538, lastValue: '1'));
    box.add(User(username: 'user1', password: 'password1', width: 80.0, height: 80.0, latitude: 40.6415, longitude: -8.6548, lastValue: '2'));
  }
}