import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_app/core/database/database_helper.dart';
import 'package:school_app/features/students/data/models/student_model.dart';
import 'package:school_app/features/groups/data/models/group_model.dart';
import 'package:school_app/features/groups/data/models/attendance_model.dart';
import 'package:school_app/features/payments/data/models/payment_model.dart';
import 'package:school_app/features/settings/data/models/template_model.dart';
import 'package:school_app/core/services/report_service.dart';
import 'package:school_app/core/services/secure_storage_service.dart';
import 'package:school_app/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:school_app/features/payments/domain/entities/dashboard_stats_entity.dart';
import 'package:school_app/features/payments/domain/entities/student_finance_entity.dart';
import 'package:school_app/features/payments/domain/enums/payment_method.dart';
import 'package:school_app/features/payments/services/payment_service.dart';

class StudentProvider extends ChangeNotifier {
  List<Student> _students = [];
  List<Group> _groups = [];
  List<Map<String, dynamic>> _debtors = []; // Qarzdorlar ro'yxati
  List<MessageTemplate> _templates = []; // Xabar shablonlari
  List<Map<String, dynamic>> _paymentStudents =
      []; // To'lov statusi bilan o'quvchilar
  List<Map<String, dynamic>> _incomingMessages = []; // Botdan kelgan javoblar
  int _pendingMessagesCount = 0;
  List<Map<String, dynamic>> _studentFlow = []; // O'quvchilar oqimi
  final List<Map<String, dynamic>> _sentMessagesLog =
      []; // Yuborilgan xabarlar logi

  String _searchQuery = '';
  int? _selectedGroupId;
  String _sortOption = 'name_asc';
  String _paymentFilter = 'all';
  String _botStatusFilter = 'all';

  String _logSearchQuery = '';
  DateTime? _logFilterDate;

  bool _isLoading = false;

  double _monthlyCashTotal = 0;
  double _monthlyCardTotal = 0;
  DashboardStatsEntity? _dashboardStats;
  List<StudentFinanceEntity> _studentFinanceList = [];

  late final PaymentService _paymentService = PaymentService(
    PaymentRepositoryImpl(DatabaseHelper.instance),
  );

  DashboardStatsEntity? get dashboardStats => _dashboardStats;
  List<StudentFinanceEntity> get studentFinanceList => _studentFinanceList;
  PaymentService get paymentService => _paymentService;

  double get monthlyCashTotal => _monthlyCashTotal;
  double get monthlyCardTotal => _monthlyCardTotal;
  double get monthlyTotal => _monthlyCashTotal + _monthlyCardTotal;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  StudentProvider() {
    _initLogs();
    _initTheme();

    // Background service'dan keladigan 'update_count' event'ini eshitish
    // Har safar xabar kelganda fetchPendingMessagesCount() chaqiriladi
    FlutterBackgroundService().on('update_count').listen((event) {
      fetchPendingMessagesCount();
    });

    // Har bir yuborilgan xabar tafsilotlarini eshitish
    FlutterBackgroundService().on('message_sent_details').listen((event) {
      if (event != null) {
        _sentMessagesLog.insert(0, event);
        notifyListeners();
      }
    });
  }

  Future<void> _initLogs() async {
    final logs = await DatabaseHelper.instance.getMessageLogs();
    _sentMessagesLog.clear();
    _sentMessagesLog.addAll(
      logs.map(
        (e) => {
          ...e,
          'time': e['date'] != null
              ? e['date'].toString().substring(11, 16)
              : '00:00',
        },
      ),
    );
    notifyListeners();
  }

  Future<void> _initTheme() async {
    final storage = SecureStorageService();
    final mode = await storage.getThemeMode();
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (mode == 'light') {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> fetchIncomingMessages() async {
    _incomingMessages = await DatabaseHelper.instance.getIncomingMessages();
    notifyListeners();
  }

  List<Map<String, dynamic>> get incomingMessages => _incomingMessages;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await SecureStorageService().setThemeMode(mode.name);
    notifyListeners();
  }

  // Davomat uchun holatlar
  Map<int, bool> _attendanceMap = {}; // studentId -> isPresent
  DateTime _selectedDate = DateTime.now();

  bool get isLoading => _isLoading;
  List<Group> get groups => _groups;
  List<Map<String, dynamic>> get debtors => _debtors;
  List<MessageTemplate> get templates => _templates;
  List<Map<String, dynamic>> get paymentStudents => _paymentStudents;
  List<Map<String, dynamic>> get studentFlow => _studentFlow;
  int get pendingMessagesCount => _pendingMessagesCount;
  List<Map<String, dynamic>> get sentMessagesLog => _sentMessagesLog;

  List<Map<String, dynamic>> get filteredSentMessagesLog {
    return _sentMessagesLog.where((log) {
      final matchesSearch =
          (log['message'] ?? '').toString().toLowerCase().contains(
            _logSearchQuery.toLowerCase(),
          ) ||
          (log['chat_id'] ?? '').toString().contains(_logSearchQuery);

      bool matchesDate = true;
      if (_logFilterDate != null && log['date'] != null) {
        final logDate = DateTime.parse(log['date']);
        matchesDate =
            logDate.year == _logFilterDate!.year &&
            logDate.month == _logFilterDate!.month &&
            logDate.day == _logFilterDate!.day;
      }

      return matchesSearch && matchesDate;
    }).toList();
  }

  void setLogSearchQuery(String query) {
    _logSearchQuery = query;
    notifyListeners();
  }

  void setLogFilterDate(DateTime? date) {
    _logFilterDate = date;
    notifyListeners();
  }

  int? get selectedGroupId => _selectedGroupId;
  String get sortOption => _sortOption;
  String get currentSort => _sortOption;
  String get paymentFilter => _paymentFilter;
  String get botStatusFilter => _botStatusFilter;

  bool get isFilterActive =>
      _selectedGroupId != null ||
      _paymentFilter != 'all' ||
      _botStatusFilter != 'all';

  List<Student> get students {
    List<Student> filtered =
        _students.where((s) {
          return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.phone.contains(_searchQuery);
        }).toList();

    if (_paymentFilter != 'all') {
      filtered =
          filtered.where((student) {
            final finance = _paymentStudents.firstWhere(
              (p) => p['id'] == student.id,
              orElse: () => {'charge_status': 'unpaid', 'current_due': 1},
            );
            final status = finance['charge_status']?.toString() ?? 'unpaid';
            final due = (finance['current_due'] as num?)?.toDouble() ?? 0;
            final isPaid = status == 'paid' || due <= 0;
            return _paymentFilter == 'paid' ? isPaid : !isPaid;
          }).toList();
    }

    if (_botStatusFilter != 'all') {
      filtered =
          filtered.where((student) {
            final hasBot =
                student.telegramHandle != null &&
                student.telegramHandle!.isNotEmpty;
            return _botStatusFilter == 'registered' ? hasBot : !hasBot;
          }).toList();
    }

    if (_sortOption == 'name_asc' || _sortOption == 'name') {
      filtered.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else if (_sortOption == 'name_desc') {
      filtered.sort(
        (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
      );
    } else if (_sortOption == 'date_desc' || _sortOption == 'time') {
      filtered.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    } else if (_sortOption == 'date_asc') {
      filtered.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    }

    return filtered;
  }

  List<Map<String, dynamic>> get filteredPaymentStudents {
    return _paymentStudents.where((s) {
      final matchesSearch =
          s['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          s['phone'].toString().contains(_searchQuery);

      // Bu yerda guruh filtri uchun mantiq qo'shish mumkin,
      // lekin hozircha asosan qidiruv va moliyaviy status muhim

      return matchesSearch;
    }).toList();
  }

  int get totalStudentCount => _students.length;
  int get presentCount => _attendanceMap.values.where((v) => v).length;
  int get absentCount => totalStudentCount - presentCount;
  double get attendancePercentage =>
      totalStudentCount == 0 ? 0.0 : (presentCount / totalStudentCount);

  Map<int, bool> get attendanceMap => _attendanceMap;
  DateTime get selectedDate => _selectedDate;
  String get formattedDate => _selectedDate.toString().substring(0, 10);

  /// O'quvchilarni bazadan yuklash
  Future<void> fetchStudents() async {
    _isLoading = true;
    notifyListeners();

    await _paymentService.generateMonthlyCharges();

    if (_selectedGroupId == null) {
      _students = await DatabaseHelper.instance.readAllStudents();
    } else {
      _students = await DatabaseHelper.instance.getStudentsByGroup(
        _selectedGroupId!,
      );
    }

    _groups = await DatabaseHelper.instance.readAllGroups();

    _templates = await DatabaseHelper.instance.readAllTemplates();

    await fetchPaymentStudents();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPaymentStudents() async {
    final currentMonth = DateTime.now().toString().substring(0, 7);
    _paymentStudents = await DatabaseHelper.instance.getStudentsFinanceStatus(
      currentMonth,
    );
    _studentFinanceList = await _paymentService.getAllStudentFinance();
    await fetchPendingMessagesCount();
    _isLoading = false;
    notifyListeners();
  }

  /// Joriy oy uchun moliyaviy ma'lumotlarni yuklash
  Future<void> fetchMonthlyFinance() async {
    final now = DateTime.now();
    _dashboardStats = await _paymentService.getDashboardStats();
    _monthlyCashTotal = _dashboardStats!.cashRevenue;
    _monthlyCardTotal = _dashboardStats!.cardRevenue;
    notifyListeners();
  }

  Future<void> fetchStudentFlow() async {
    _studentFlow = await DatabaseHelper.instance.getMonthlyStudentFlow();
    notifyListeners();
  }

  Future<void> fetchPendingMessagesCount() async {
    _pendingMessagesCount = await DatabaseHelper.instance
        .getPendingMessagesCount();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(String option) {
    _sortOption = option;
    notifyListeners();
  }

  void setFilterGroup(int? groupId) {
    _selectedGroupId = groupId;
    fetchStudents();
  }

  void setPaymentFilter(String value) {
    _paymentFilter = value;
    notifyListeners();
  }

  void setBotStatusFilter(String value) {
    _botStatusFilter = value;
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedGroupId = null;
    _paymentFilter = 'all';
    _botStatusFilter = 'all';
    _searchQuery = '';
    fetchStudents();
  }

  void applyAllFilters() {
    notifyListeners();
  }

  /// Yangi o'quvchi qo'shish va Telegram xabarnoma yuborish
  Future<void> addStudent(
    Student student, {
    String? botToken,
    String? adminChatId,
  }) async {
    // 1. O'quvchini bazaga saqlash
    final id = await DatabaseHelper.instance.createStudent(student);

    if (id > 0) {
      var studentWithId = student.copyWith(
        id: id,
        joinDate:
            student.joinDate ??
            DateTime.now().toIso8601String().substring(0, 10),
      );

      if (student.groupId != null) {
        await DatabaseHelper.instance.addStudentToGroup(
          student.groupId!,
          id,
        );
      } else if (student.freeTime != null && student.freeTime!.isNotEmpty) {
        final matchingGroup = _groups.firstWhere(
          (g) => g.time.contains(student.freeTime!),
          orElse:
              () =>
                  Group(id: -1, name: '', schedule: '', time: '', price: 0.0),
        );

        if (matchingGroup.id != -1) {
          studentWithId = studentWithId.copyWith(groupId: matchingGroup.id);
          await assignStudentToGroup(id, matchingGroup.id!);
        }
      }

      await _paymentService.createInitialChargeForStudent(studentWithId);

      await fetchStudents();

      // Telegram xabarnoma yuborish (agar sozlamalar mavjud bo'lsa)
      if (botToken != null && adminChatId != null) {
        _addMessageToQueue(studentWithId, adminChatId);
      }
      _addAutoSms(studentWithId); // Avto SMS navbatga qo'shish
    }
  }

  void _addMessageToQueue(Student student, String chatId) async {
    final message =
        "🆕 <b>Yangi o'quvchi qo'shildi</b>\n\n"
        "👤 <b>Ism:</b> ${student.name}\n"
        "📞 <b>Tel:</b> ${student.phone}\n"
        "🏠 <b>Ota-ona:</b> ${student.parentPhone}\n"
        "${student.telegramHandle != null && student.telegramHandle!.isNotEmpty ? "✈️ <b>Telegram:</b> ${student.telegramHandle}\n" : ""}"
        "${student.parentTelegram != null && student.parentTelegram!.isNotEmpty ? "👨‍👩‍👧 <b>Ota-ona TG:</b> ${student.parentTelegram}\n" : ""}"
        "${student.freeTime != null && student.freeTime!.isNotEmpty ? "🕒 <b>Bo'sh vaqti:</b> ${student.freeTime}\n" : ""}"
        "⏰ <b>Vaqt:</b> ${DateTime.now().toString().substring(0, 16)}";
    await DatabaseHelper.instance.addPendingMessage(chatId, message);
    await fetchPendingMessagesCount();
  }

  void _addAutoSms(Student student) async {
    // Avto SMS shabloni mavjudligini tekshirish
    final smsTemplates = _templates.where((t) => t.type == 'sms').toList();
    if (smsTemplates.isNotEmpty) {
      String msg = smsTemplates.first.content.replaceAll('[ism]', student.name);
      await DatabaseHelper.instance.addPendingMessage(
        student.phone,
        msg,
        type: 'sms',
      );
      await fetchPendingMessagesCount();
    }
  }

  /// O'quvchi ma'lumotlarini tahrirlash
  Future<void> updateStudent(Student student) async {
    final result = await DatabaseHelper.instance.updateStudent(student);
    if (result > 0) {
      await fetchStudents();
    }
  }

  /// O'quvchini guruhga biriktirish
  Future<bool> assignStudentToGroup(int studentId, int groupId) async {
    final group = _groups.firstWhere((g) => g.id == groupId);
    if (group.studentCount >= group.maxStudents) {
      return false;
    }

    await DatabaseHelper.instance.addStudentToGroup(groupId, studentId);
    final student = await DatabaseHelper.instance.getStudentById(studentId);
    if (student != null) {
      await DatabaseHelper.instance.updateStudent(
        student.copyWith(groupId: groupId),
      );
    }
    await fetchStudents();
    return true;
  }

  /// O'quvchini guruhdan o'chirish
  Future<void> removeStudentFromGroup(int studentId, int groupId) async {
    await DatabaseHelper.instance.removeStudentFromGroup(groupId, studentId);
    await fetchStudents();
  }

  /// O'quvchini o'chirish
  Future<void> deleteStudent(int id) async {
    final result = await DatabaseHelper.instance.deleteStudent(id);
    if (result > 0) {
      await fetchStudents();
    }
  }

  /// Yangi guruh qo'shish
  Future<void> addGroup(Group group, {List<int>? studentIds}) async {
    final id = await DatabaseHelper.instance.createGroup(group);
    if (id > 0) {
      if (studentIds != null) {
        for (var studentId in studentIds) {
          await DatabaseHelper.instance.addStudentToGroup(id, studentId);
        }
      }
      await fetchStudents();
    }
  }

  /// Guruhni tahrirlash
  Future<void> updateGroup(Group group) async {
    final result = await DatabaseHelper.instance.updateGroup(group);
    if (result > 0) {
      await fetchStudents();
    }
  }

  /// Guruhni o'chirish
  Future<void> deleteGroup(int id) async {
    final result = await DatabaseHelper.instance.deleteGroup(id);
    if (result > 0) {
      if (_selectedGroupId == id) _selectedGroupId = null;
      await fetchStudents();
    }
  }

  // Davomat metodlari
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    if (_selectedGroupId != null) loadAttendance();
    notifyListeners();
  }

  Future<void> loadAttendance() async {
    if (_selectedGroupId == null) return;

    _isLoading = true;
    notifyListeners();

    final dateStr = formattedDate;
    final attendanceList = await DatabaseHelper.instance.getAttendance(
      _selectedGroupId!,
      dateStr,
    );

    _attendanceMap = {for (var a in attendanceList) a.studentId: a.isPresent};

    _isLoading = false;
    notifyListeners();
  }

  /// O'quvchining davomat tarixini olish
  Future<List<Map<String, dynamic>>> getStudentAttendance(int studentId) async {
    return await DatabaseHelper.instance.getAttendanceByStudent(studentId);
  }

  void toggleAttendance(int studentId) {
    _attendanceMap[studentId] = !(_attendanceMap[studentId] ?? false);
    notifyListeners();
  }

  /// Kelmagan o'quvchilar ro'yxatini olish
  List<Student> getAbsentStudents() {
    return _students.where((s) => !(_attendanceMap[s.id] ?? false)).toList();
  }

  Future<void> saveAttendance({
    String? adminChatId,
    String? customMessage,
  }) async {
    if (_selectedGroupId == null) return;

    final dateStr = formattedDate;
    for (var entry in _attendanceMap.entries) {
      await DatabaseHelper.instance.saveAttendance(
        Attendance(
          studentId: entry.key,
          groupId: _selectedGroupId!,
          date: dateStr,
          isPresent: entry.value,
        ),
      );
    }

    // Telegram xabarnomani navbatga qo'shish (background service yuboradi)
    if (adminChatId != null && customMessage != null) {
      await DatabaseHelper.instance.addPendingMessage(
        adminChatId,
        customMessage,
      );
      await fetchPendingMessagesCount();
    }
  }

  /// To'lov qo'shish (qarz + depozit mantiq bilan)
  Future<void> addPayment(Payment payment) async {
    await _paymentService.processPayment(
      studentId: payment.studentId,
      amount: payment.amount,
      method: PaymentMethod.fromString(payment.type),
      note: payment.note,
    );
    await fetchPaymentStudents();
    await fetchMonthlyFinance();
    notifyListeners();
  }

  /// To'lovni tahrirlash
  Future<void> updatePayment(Payment payment) async {
    await DatabaseHelper.instance.updatePayment(payment);
    await fetchMonthlyFinance(); // Dashboard dagi summalarni yangilash
    notifyListeners();
  }

  /// To'lovni o'chirish
  Future<void> deletePayment(int id) async {
    await DatabaseHelper.instance.deletePayment(id);
    await fetchMonthlyFinance(); // Dashboard dagi summalarni yangilash
    notifyListeners();
  }

  Future<StudentFinanceEntity?> getStudentFinance(int studentId) =>
      _paymentService.getStudentFinance(studentId);

  /// O'quvchining to'lovlar tarixini olish
  Future<List<Payment>> getStudentPayments(int studentId) async {
    return await DatabaseHelper.instance.getPaymentsByStudent(studentId);
  }

  /// Oylik hisobotni Telegramga yuborish
  Future<void> sendMonthlyPaymentReport(
    String monthYear, {
    String? adminChatId,
  }) async {
    if (adminChatId == null) return;

    final reportData = await DatabaseHelper.instance.getMonthlyPaymentsReport(
      monthYear,
    );

    double cashTotal = 0;
    double cardTotal = 0;

    for (var item in reportData) {
      if (item['type'] == 'naqd') {
        cashTotal = (item['total'] as num).toDouble();
      }
      if (item['type'] == 'karta') {
        cardTotal = (item['total'] as num).toDouble();
      }
    }

    final report =
        "💰 <b>Oylik To'lov Hisoboti ($monthYear)</b>\n\n"
        "💵 <b>Naqd:</b> ${cashTotal.toStringAsFixed(0)} so'm\n"
        "💳 <b>Karta:</b> ${cardTotal.toStringAsFixed(0)} so'm\n"
        "-------------------\n"
        "✅ <b>Jami:</b> ${(cashTotal + cardTotal).toStringAsFixed(0)} so'm";

    await DatabaseHelper.instance.addPendingMessage(adminChatId, report);
    await fetchPendingMessagesCount();
  }

  /// Qarzdorlar ro'yxatini yuklash
  Future<void> fetchDebtors() async {
    _isLoading = true;
    notifyListeners();
    final currentMonth = DateTime.now().toString().substring(0, 7);
    _debtors = await DatabaseHelper.instance.getDebtorsReport(currentMonth);
    _isLoading = false;
    notifyListeners();
  }

  /// Telegram orqali qarz haqida eslatma yuborish
  Future<void> sendDebtReminderTelegram({
    required String message,
    String? adminChatId,
  }) async {
    if (adminChatId == null) return;
    await DatabaseHelper.instance.addPendingMessage(adminChatId, message);
    await fetchPendingMessagesCount();
  }

  /// Shablonlarni yuklash
  Future<void> fetchTemplates() async {
    _templates = await DatabaseHelper.instance.readAllTemplates();
    notifyListeners();
  }

  /// Yangi shablon qo'shish
  Future<void> addTemplate(MessageTemplate template) async {
    await DatabaseHelper.instance.createTemplate(template);
    await fetchTemplates();
  }

  /// Shablonni tahrirlash
  Future<void> updateTemplate(MessageTemplate template) async {
    await DatabaseHelper.instance.updateTemplate(template);
    await fetchTemplates();
  }

  /// Shablonni o'chirish
  Future<void> deleteTemplate(int id) async {
    await DatabaseHelper.instance.deleteTemplate(id);
    await fetchTemplates();
  }

  /// Oylik PDF hisobot yaratish
  Future<void> generateMonthlyPdfReport(Group group, String monthYear) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseHelper.instance.getMonthlyAttendanceReport(
      group.id!,
      monthYear,
    );
    await ReportService.generateMonthlyReport(group, monthYear, data);

    _isLoading = false;
    notifyListeners();
  }

  /// Oylik Excel hisobot yaratish
  Future<String> generateMonthlyExcelReport(
    Group group,
    String monthYear,
  ) async {
    _isLoading = true;
    notifyListeners();

    final data = await DatabaseHelper.instance.getMonthlyAttendanceReport(
      group.id!,
      monthYear,
    );
    final path = await ReportService.generateMonthlyExcelReport(
      group,
      monthYear,
      data,
    );

    _isLoading = false;
    notifyListeners();
    return path;
  }

  /// Barcha ma'lumotlarni JSON formatida zaxira qilish (Backup)
  Future<String?> exportBackup() async {
    try {
      _isLoading = true;
      notifyListeners();

      final data = await DatabaseHelper.instance.getAllData();
      final jsonString = jsonEncode(data);

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'school_app_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Zaxira nusxasidan (JSON fayldan) ma'lumotlarni qayta tiklash (Restore)
  Future<bool> restoreBackup() async {
    try {
      _isLoading = true;
      notifyListeners();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        await DatabaseHelper.instance.restoreData(data);

        // Ma'lumotlarni qayta yuklaymiz
        await fetchStudents();
        await _initLogs();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Barcha ma'lumotlarni bazadan tozalash
  Future<void> clearAllAppData() async {
    await DatabaseHelper.instance.clearDatabase();
    await fetchStudents();
    await _initLogs();
  }
}
