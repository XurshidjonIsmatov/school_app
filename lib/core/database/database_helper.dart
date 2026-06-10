import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:school_app/features/students/data/models/student_model.dart';
import 'package:school_app/features/groups/data/models/group_model.dart';
import 'package:school_app/features/groups/data/models/attendance_model.dart';
import 'package:school_app/features/payments/data/models/payment_model.dart';
import 'package:school_app/features/payments/data/models/monthly_charge_model.dart';
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
      version: 6,
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
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
  }

  Future<void> _migrateToV6(Database db) async {
    await db.execute('ALTER TABLE students ADD COLUMN join_date TEXT');
    await db.execute('ALTER TABLE students ADD COLUMN group_id INTEGER');
    await db.execute(
      "ALTER TABLE students ADD COLUMN payment_type TEXT DEFAULT 'monthly'",
    );
    await db.execute(
      "ALTER TABLE students ADD COLUMN payment_method TEXT DEFAULT 'cash'",
    );
    await db.execute(
      'ALTER TABLE students ADD COLUMN deposit_balance REAL DEFAULT 0',
    );
    try {
      await db.execute('ALTER TABLE payments ADD COLUMN note TEXT');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS monthly_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        charge_date TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        status TEXT DEFAULT 'unpaid',
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        UNIQUE(student_id, month, year)
      )
    ''');

    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.execute(
      "UPDATE students SET join_date = '$today' WHERE join_date IS NULL",
    );
    await db.execute(
      "UPDATE students SET payment_type = 'monthly' WHERE payment_type IS NULL",
    );
    await db.execute(
      "UPDATE students SET payment_method = 'cash' WHERE payment_method IS NULL",
    );
    await db.execute(
      'UPDATE students SET deposit_balance = 0 WHERE deposit_balance IS NULL',
    );

    // group_id ni group_students dan birinchi guruh orqali to'ldirish
    final students = await db.query('students', columns: ['id']);
    for (final row in students) {
      final studentId = row['id'] as int;
      final groups = await db.query(
        'group_students',
        where: 'student_id = ?',
        whereArgs: [studentId],
        limit: 1,
      );
      if (groups.isNotEmpty) {
        await db.update(
          'students',
          {'group_id': groups.first['group_id']},
          where: 'id = ?',
          whereArgs: [studentId],
        );
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
        custom_price REAL,
        join_date TEXT,
        group_id INTEGER,
        payment_type TEXT DEFAULT 'monthly',
        payment_method TEXT DEFAULT 'cash',
        deposit_balance REAL DEFAULT 0
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
        note TEXT,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_charges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        charge_date TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        status TEXT DEFAULT 'unpaid',
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        UNIQUE(student_id, month, year)
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
    await db.delete(
      'monthly_charges',
      where: 'student_id = ?',
      whereArgs: [id],
    );

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

  /// Oylik o'quvchilar oqimi (join_date bo'yicha)
  Future<List<Map<String, dynamic>>> getMonthlyStudentFlow() async {
    final db = await instance.database;
    final year = DateTime.now().year.toString();
    final result = await db.rawQuery(
      '''
      SELECT CAST(strftime('%m', join_date) AS INTEGER) as month,
             COUNT(*) as count
      FROM students
      WHERE join_date IS NOT NULL
        AND strftime('%Y', join_date) = ?
      GROUP BY strftime('%m', join_date)
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

  Future<Payment?> getLastPayment(int studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Payment.fromMap(result.first);
  }

  Future<Student?> getStudentById(int id) async {
    final db = await instance.database;
    final result = await db.query('students', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Student.fromMap(result.first);
  }

  Future<List<Student>> getMonthlyPaymentStudents() async {
    final db = await instance.database;
    final result = await db.query(
      'students',
      where: "payment_type = 'monthly'",
    );
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<void> updateStudentDeposit(int studentId, double balance) async {
    final db = await instance.database;
    await db.update(
      'students',
      {'deposit_balance': balance},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  Future<double?> getGroupMonthlyFee(int groupId) async {
    final db = await instance.database;
    final result = await db.query(
      'groups',
      columns: ['price'],
      where: 'id = ?',
      whereArgs: [groupId],
    );
    if (result.isEmpty) return null;
    return (result.first['price'] as num?)?.toDouble();
  }

  // MonthlyCharge CRUD
  Future<int> createMonthlyCharge(MonthlyChargeModel charge) async {
    final db = await instance.database;
    return await db.insert('monthly_charges', charge.toMap());
  }

  Future<void> updateMonthlyCharge(MonthlyChargeModel charge) async {
    final db = await instance.database;
    await db.update(
      'monthly_charges',
      charge.toMap(),
      where: 'id = ?',
      whereArgs: [charge.id],
    );
  }

  Future<List<MonthlyChargeModel>> getChargesByStudent(int studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'monthly_charges',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'year DESC, month DESC',
    );
    return result.map((json) => MonthlyChargeModel.fromMap(json)).toList();
  }

  Future<MonthlyChargeModel?> getChargeForPeriod(
    int studentId,
    int month,
    int year,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'monthly_charges',
      where: 'student_id = ? AND month = ? AND year = ?',
      whereArgs: [studentId, month, year],
    );
    if (result.isEmpty) return null;
    return MonthlyChargeModel.fromMap(result.first);
  }

  Future<List<MonthlyChargeModel>> getUnpaidCharges(int studentId) async {
    final db = await instance.database;
    final result = await db.query(
      'monthly_charges',
      where: "student_id = ? AND status != 'paid'",
      whereArgs: [studentId],
      orderBy: 'year ASC, month ASC',
    );
    return result.map((json) => MonthlyChargeModel.fromMap(json)).toList();
  }

  Future<List<MonthlyChargeModel>> getAllChargesForMonth(
    int month,
    int year,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'monthly_charges',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return result.map((json) => MonthlyChargeModel.fromMap(json)).toList();
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

  /// Qarzdorlar — monthly_charges asosida
  Future<List<Map<String, dynamic>>> getDebtorsReport(
    String currentMonth,
  ) async {
    final db = await instance.database;
    final parts = currentMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    return await db.rawQuery(
      '''
      SELECT 
        s.id, 
        s.name, 
        s.phone,
        s.parent_phone,
        s.deposit_balance,
        mc.amount as total_required,
        mc.paid_amount as total_paid,
        (mc.amount - mc.paid_amount) as debt
      FROM students s
      INNER JOIN monthly_charges mc ON mc.student_id = s.id
      WHERE mc.month = ? AND mc.year = ?
        AND mc.status != 'paid'
        AND (mc.amount - mc.paid_amount) > 0
      ORDER BY debt DESC
    ''',
      [month, year],
    );
  }

  /// Barcha o'quvchilar moliyaviy holati (charges asosida)
  Future<List<Map<String, dynamic>>> getStudentsFinanceStatus(
    String currentMonth,
  ) async {
    final db = await instance.database;
    final parts = currentMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    return await db.rawQuery(
      '''
      SELECT 
        s.*,
        g.name as group_name,
        g.price as group_monthly_fee,
        mc.amount as total_required,
        mc.paid_amount as total_paid,
        (mc.amount - mc.paid_amount) as current_due,
        mc.status as charge_status,
        (SELECT SUM(mc2.amount - mc2.paid_amount) 
         FROM monthly_charges mc2 
         WHERE mc2.student_id = s.id AND mc2.status != 'paid') as total_debt,
        (SELECT MAX(p.date) FROM payments p WHERE p.student_id = s.id) as last_payment_date
      FROM students s
      LEFT JOIN groups g ON g.id = s.group_id
      LEFT JOIN monthly_charges mc 
        ON mc.student_id = s.id AND mc.month = ? AND mc.year = ?
      GROUP BY s.id
    ''',
      [month, year],
    );
  }

  Future<Map<String, dynamic>> getDashboardPaymentStats(
    int month,
    int year,
  ) async {
    final db = await instance.database;
    final monthYear = '$year-${month.toString().padLeft(2, '0')}';

    final totalStudents = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM students'),
        ) ??
        0;

    final paidStudents = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
        SELECT COUNT(DISTINCT student_id) FROM monthly_charges
        WHERE month = ? AND year = ? AND status = 'paid'
      ''',
            [month, year],
          ),
        ) ??
        0;

    final debtorStudents = Sqflite.firstIntValue(
          await db.rawQuery(
            '''
        SELECT COUNT(DISTINCT student_id) FROM monthly_charges
        WHERE month = ? AND year = ? AND status != 'paid'
          AND (amount - paid_amount) > 0
      ''',
            [month, year],
          ),
        ) ??
        0;

    final expectedResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount - paid_amount), 0) as total
      FROM monthly_charges
      WHERE month = ? AND year = ? AND status != 'paid'
    ''',
      [month, year],
    );
    final expectedRevenue =
        (expectedResult.first['total'] as num?)?.toDouble() ?? 0;

    final cashResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total FROM payments
      WHERE date LIKE ? AND type = 'naqd'
    ''',
      ['$monthYear%'],
    );
    final cashRevenue = (cashResult.first['total'] as num?)?.toDouble() ?? 0;

    final cardResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as total FROM payments
      WHERE date LIKE ? AND type = 'karta'
    ''',
      ['$monthYear%'],
    );
    final cardRevenue = (cardResult.first['total'] as num?)?.toDouble() ?? 0;

    final depositResult = await db.rawQuery(
      'SELECT COALESCE(SUM(deposit_balance), 0) as total FROM students',
    );
    final totalDeposits =
        (depositResult.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'total_students': totalStudents,
      'paid_students': paidStudents,
      'debtor_students': debtorStudents,
      'expected_revenue': expectedRevenue,
      'cash_revenue': cashRevenue,
      'card_revenue': cardRevenue,
      'total_deposits': totalDeposits,
    };
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
      'monthly_charges',
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
      'monthly_charges',
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
