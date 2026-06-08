import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:school_app/features/students/data/models/student_model.dart';
import 'package:school_app/features/groups/data/models/group_model.dart';
import 'package:school_app/features/groups/data/models/attendance_model.dart';
import 'package:school_app/features/payments/data/models/payment_model.dart';
import 'package:school_app/features/settings/data/models/template_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('school.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE students ADD COLUMN telegram_handle TEXT');
      await db.execute('ALTER TABLE students ADD COLUMN parent_telegram TEXT');
      await db.execute('ALTER TABLE students ADD COLUMN free_time TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE groups ADD COLUMN max_students INTEGER DEFAULT 20',
      );
    }
    if (oldVersion < 5) {
      // We use a try-catch or a PRAGMA check to be safe in case
      // some users successfully migrated to v4 while others didn't.
      try {
        await db.execute('ALTER TABLE students ADD COLUMN custom_price REAL');
      } catch (e) {
        // Column might already exist if version 4 migration was successful
      }
    }
  }

  Future _createDB(Database db, int version) async {
    // O'quvchilar jadvali
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        parent_phone TEXT NOT NULL,
        telegram_handle TEXT,
        parent_telegram TEXT,
        free_time TEXT,
        custom_price REAL
      )
    ''');

    // Guruhlar jadvali
    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        schedule TEXT NOT NULL,
        time TEXT NOT NULL,
        price REAL DEFAULT 0,
        max_students INTEGER DEFAULT 20
      )
    ''');

    // Guruh-O'quvchi bog'liqligi (Many-to-Many)
    await db.execute('''
      CREATE TABLE group_students (
        group_id INTEGER,
        student_id INTEGER,
        PRIMARY KEY (group_id, student_id)
      )
    ''');

    // To'lovlar jadvali
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        amount REAL,
        date TEXT,
        type TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    // Davomat jadvali
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        group_id INTEGER,
        date TEXT,
        is_present INTEGER,
        UNIQUE(student_id, group_id, date) ON CONFLICT REPLACE
      )
    ''');

    // Shablonlar jadvali
    await db.execute('''
      CREATE TABLE templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Navbat tizimi (Queue) uchun jadval
    await db.execute('''
      CREATE TABLE pending_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT DEFAULT 'telegram'
      )
    ''');

    // Kelgan xabarlar jadvali (Telegram botdan)
    await db.execute('''
      CREATE TABLE incoming_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id TEXT NOT NULL,
        message TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Yuborilgan xabarlar logi (History)
    await db.execute('''
      CREATE TABLE message_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // Student CRUD
  Future<int> createStudent(Student student) async {
    final db = await instance.database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> readAllStudents() async {
    final db = await instance.database;
    final result = await db.query('students');
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<int> updateStudent(Student student) async {
    final db = await instance.database;
    return db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await instance.database;
    // O'quvchiga bog'liq barcha ma'lumotlarni tozalash
    await db.delete('group_students', where: 'student_id = ?', whereArgs: [id]);
    await db.delete('attendance', where: 'student_id = ?', whereArgs: [id]);
    await db.delete('payments', where: 'student_id = ?', whereArgs: [id]);

    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // Group CRUD
  Future<int> createGroup(Group group) async {
    final db = await instance.database;
    return await db.insert('groups', group.toMap());
  }

  Future<List<Group>> readAllGroups() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT g.*, 
      (SELECT COUNT(*) FROM group_students gs WHERE gs.group_id = g.id) as student_count
      FROM groups g
    ''');
    return result.map((json) => Group.fromMap(json)).toList();
  }

  Future<int> updateGroup(Group group) async {
    final db = await instance.database;
    return db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(int id) async {
    final db = await instance.database;
    await db.delete('group_students', where: 'group_id = ?', whereArgs: [id]);
    await db.delete('attendance', where: 'group_id = ?', whereArgs: [id]);
    return db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }

  /// Oylik o'quvchilar oqimi (har oyda birinchi to'lov qilgan o'quvchilar soni)
  Future<List<Map<String, dynamic>>> getMonthlyStudentFlow() async {
    final db = await instance.database;
    final year = DateTime.now().year.toString();
    final result = await db.rawQuery(
      '''
      SELECT CAST(strftime('%m', min_date) AS INTEGER) as month,
             COUNT(*) as count
      FROM (
        SELECT student_id, MIN(date) as min_date
        FROM payments
        GROUP BY student_id
      ) first_payments
      WHERE strftime('%Y', min_date) = ?
      GROUP BY strftime('%m', min_date)
      ORDER BY month
    ''',
      [year],
    );
    return result;
  }

  // Guruhga o'quvchi qo'shish
  Future<void> addStudentToGroup(int groupId, int studentId) async {
    final db = await instance.database;
    await db.insert('group_students', {
      'group_id': groupId,
      'student_id': studentId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // O'quvchini guruhdan o'chirish
  Future<void> removeStudentFromGroup(int groupId, int studentId) async {
    final db = await instance.database;
    await db.delete(
      'group_students',
      where: 'group_id = ? AND student_id = ?',
      whereArgs: [groupId, studentId],
    );
  }

  // Guruhdagi barcha o'quvchilarni olish (Many-to-Many join)
  Future<List<Student>> getStudentsByGroup(int groupId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT students.* FROM students
      INNER JOIN group_students ON students.id = group_students.student_id
      WHERE group_students.group_id = ?
    ''',
      [groupId],
    );
    return result.map((json) => Student.fromMap(json)).toList();
  }

  // Attendance CRUD
  Future<void> saveAttendance(Attendance attendance) async {
    final db = await instance.database;
    await db.insert(
      'attendance',
      attendance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Attendance>> getAttendance(int groupId, String date) async {
    final db = await instance.database;
    final result = await db.query(
      'attendance',
      where: 'group_id = ? AND date = ?',
      whereArgs: [groupId, date],
    );
    return result.map((json) => Attendance.fromMap(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getAttendanceByStudent(
    int studentId,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT a.*, g.name as group_name
      FROM attendance a
      INNER JOIN groups g ON a.group_id = g.id
      WHERE a.student_id = ?
      ORDER BY a.date DESC
    ''',
      [studentId],
    );
  }

  // Payment CRUD
  Future<int> createPayment(Payment payment) async {
    final db = await instance.database;
    return await db.insert('payments', payment.toMap());
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await instance.database;
    return await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await instance.database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Payment>> getPaymentsByStudent(int studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
    return result.map((json) => Payment.fromMap(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyPaymentsReport(
    String monthYear,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT type, SUM(amount) as total
      FROM payments
      WHERE date LIKE ?
      GROUP BY type
    ''',
      ['$monthYear%'],
    );
  }

  /// Qarzdorlarni hisoblash uchun SQL mantiqi
  Future<List<Map<String, dynamic>>> getDebtorsReport(
    String currentMonth,
  ) async {
    final db = await instance.database;
    // Bu so'rov har bir o'quvchi uchun:
    // 1. U a'zo bo'lgan guruhlar narxi yig'indisini (total_required)
    // 2. Shu oyda amalga oshirgan to'lovlari yig'indisini (total_paid) hisoblaydi
    return await db.rawQuery(
      '''
      SELECT 
        s.id, 
        s.name, 
        s.phone,
        s.parent_phone,
        CASE 
          WHEN s.custom_price IS NOT NULL AND s.custom_price > 0 THEN s.custom_price
          ELSE (SELECT SUM(g.price) FROM groups g 
                INNER JOIN group_students gs ON g.id = gs.group_id 
                WHERE gs.student_id = s.id)
        END as total_required,
        (SELECT SUM(p.amount) FROM payments p 
         WHERE p.student_id = s.id AND p.date LIKE ?) as total_paid
      FROM students s
      GROUP BY s.id
      HAVING (total_required > 0) AND (total_paid < total_required OR total_paid IS NULL)
    ''',
      ['$currentMonth%'],
    );
  }

  /// Barcha o'quvchilar va ularning joriy oydagi to'lov statusini olish
  Future<List<Map<String, dynamic>>> getStudentsFinanceStatus(
    String currentMonth,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT 
        s.*,
        CASE 
          WHEN s.custom_price IS NOT NULL AND s.custom_price > 0 THEN s.custom_price
          ELSE (SELECT SUM(g.price) FROM groups g 
                INNER JOIN group_students gs ON g.id = gs.group_id 
                WHERE gs.student_id = s.id)
        END as total_required,
        (SELECT SUM(p.amount) FROM payments p 
         WHERE p.student_id = s.id AND p.date LIKE ?) as total_paid
      FROM students s
      GROUP BY s.id
    ''',
      ['$currentMonth%'],
    );
  }

  // Template CRUD
  Future<int> createTemplate(MessageTemplate template) async {
    final db = await instance.database;
    return await db.insert('templates', template.toMap());
  }

  Future<List<MessageTemplate>> readAllTemplates() async {
    final db = await instance.database;
    final result = await db.query('templates');
    return result.map((json) => MessageTemplate.fromMap(json)).toList();
  }

  Future<int> updateTemplate(MessageTemplate template) async {
    final db = await instance.database;
    return db.update(
      'templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteTemplate(int id) async {
    final db = await instance.database;
    return await db.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getMonthlyAttendanceReport(
    int groupId,
    String monthYear,
  ) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT s.name, a.date, a.is_present
      FROM attendance a
      INNER JOIN students s ON a.student_id = s.id
      WHERE a.group_id = ? AND a.date LIKE ?
      ORDER BY s.name ASC, a.date ASC
    ''',
      [groupId, '$monthYear%'],
    );
  }

  // Pending messages (Queue) metodlari
  Future<void> addPendingMessage(
    String chatId,
    String message, {
    String type = 'telegram',
  }) async {
    final db = await instance.database;
    await db.insert('pending_messages', {
      'chat_id': chatId,
      'message': message,
      'type': type,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingMessages() async {
    final db = await instance.database;
    return await db.query('pending_messages');
  }

  Future<void> deletePendingMessage(int id) async {
    final db = await instance.database;
    await db.delete('pending_messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingMessagesCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM pending_messages');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Message Log metodlari
  Future<void> insertMessageLog(Map<String, dynamic> log) async {
    final db = await instance.database;
    await db.insert('message_logs', log);
  }

  Future<void> insertIncomingMessage(Map<String, dynamic> msg) async {
    final db = await instance.database;
    await db.insert('incoming_messages', msg);
  }

  Future<List<Map<String, dynamic>>> getIncomingMessages() async {
    final db = await instance.database;
    return await db.query('incoming_messages', orderBy: 'date DESC');
  }

  Future<void> deleteIncomingMessage(int id) async {
    final db = await instance.database;
    await db.delete('incoming_messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getMessageLogs() async {
    final db = await instance.database;
    return await db.query('message_logs', orderBy: 'date DESC');
  }

  Future<void> cleanOldMessageLogs() async {
    final db = await instance.database;
    await db.delete(
      'message_logs',
      where: "date < datetime('now', '-30 days')",
    );
  }

  Future<Map<String, dynamic>> getAllData() async {
    final db = await instance.database;
    final tables = [
      'students',
      'groups',
      'group_students',
      'payments',
      'attendance',
      'templates',
      'pending_messages',
      'message_logs',
    ];
    Map<String, dynamic> backupData = {};
    for (String table in tables) {
      backupData[table] = await db.query(table);
    }
    return backupData;
  }

  Future<void> restoreData(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final tables = [
        'students',
        'groups',
        'group_students',
        'payments',
        'attendance',
        'templates',
        'pending_messages',
        'message_logs',
      ];

      for (String table in tables) {
        // Avval mavjud ma'lumotlarni o'chiramiz
        await txn.delete(table);

        if (data.containsKey(table)) {
          List<dynamic> rows = data[table];
          for (var row in rows) {
            await txn.insert(table, row as Map<String, dynamic>);
          }
        }
      }
    });
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    final tables = [
      'students',
      'groups',
      'group_students',
      'payments',
      'attendance',
      'templates',
      'pending_messages',
      'message_logs',
    ];
    for (String table in tables) {
      await db.delete(table);
    }
  }
}
