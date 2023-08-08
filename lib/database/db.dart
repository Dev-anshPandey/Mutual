import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MyDb {
  late Database db;

  Future open() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'chat.db');
    Database db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE  chat ( postId TEXT ,chatId TEXT,message TEXT, right  BOOLEAN ,  profilePic TEXT,name TEXT, postId2 TEXT , time TEXT,  profession STRING, mutual STRING, cursor INTEGER, graphId INTEGER,post TEXT, authorName TEXT)');
    });
    print(path);
    return db;
    
  }
  /*
    postId INTEGER,
                        text TEXT,
                        right  BOOLEAN ,
                        profilePic TEXT,
                        name TEXT,
                        postId2 TEXT,
                        time TEXT,
                        profession STRING,
                        mutual STRING,
   */

  Future<Map<dynamic, dynamic>?> getChat(String chatId) async {
    List<Map> maps =
        await db.query('chat', where: 'chatId = ?', whereArgs: [chatId]);
    //getting student data with roll no.
    if (maps.length > 0) {
      return maps.first;
    }
    return null;
  }
}
