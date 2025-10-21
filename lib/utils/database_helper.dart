import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:teste/models/contact_model.dart'; 

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      sobrenome TEXT,
      telefone TEXT,
      email TEXT,
      dataNascimento TEXT,
      isFavorite INTEGER NOT NULL DEFAULT 0 
    )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE contacts ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print("Coluna isFavorite já existe: $e");
      }
    }
  }

  Future<int> create(Contact contact) async {
    final db = await instance.database;
    final id = await db.insert('contacts', contact.toMap());
    return id;
  }

  Future<Contact?> getContact(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'contacts',
      columns: ['id', 'nome', 'sobrenome', 'telefone', 'email', 'dataNascimento', 'isFavorite'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Contact.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Contact>> getAllContacts({String? query}) async {
    final db = await instance.database;
    
    String? whereString;
    List<dynamic>? whereArgs;

    if (query != null && query.isNotEmpty) {
      whereString = '''
        nome LIKE ? OR 
        sobrenome LIKE ? OR 
        telefone LIKE ? OR 
        (nome || ' ' || sobrenome) LIKE ? 
      ''';

      whereArgs = ['%$query%', '%$query%', '%$query%', '%$query%'];
    }

    final result = await db.query(
      'contacts',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'isFavorite DESC, nome ASC',
    );
    return result.map((json) => Contact.fromMap(json)).toList();
  }

  Future<int> update(Contact contact) async {
    final db = await instance.database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}