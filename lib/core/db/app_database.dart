// lib/core/db/app_database.dart

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String path = join(dir.path, 'my_kopilka_v2.db'); // Новое имя файла БД
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Таблица для целей накоплений
        await db.execute('''
          CREATE TABLE goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            target_amount INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          );
        ''');
        
        // Таблица для транзакций (пополнения и снятия)
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            goal_id INTEGER NOT NULL,
            amount INTEGER NOT NULL,
            notes TEXT,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
          );
        ''');
      },
    );
  }
}