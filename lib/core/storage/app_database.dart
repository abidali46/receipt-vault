// lib/core/storage/app_database.dart
//
// Drift + SQLite database configuration for Receipt Vault.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Table definition for storing receipts.
///
/// Follows the schema requirements:
/// - Auto-increment integer ID
/// - Product name (required)
/// - Store name (optional)
/// - Category (optional, e.g. Electronics, Food, Others)
/// - Purchase date (required)
/// - Total amount (required, double)
/// - Warranty duration in days (optional, null = no warranty)
/// - Notes (optional)
/// - Local image path (optional)
/// - Created-at timestamp (required, defaults to current time)
class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productName => text()();
  TextColumn get storeName => text().nullable()();
  TextColumn get category => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get totalAmount => real()();
  IntColumn get warrantyDurationDays => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// The local Drift database for Receipt Vault.
@DriftDatabase(tables: [Receipts])
class AppDatabase extends _$AppDatabase {
  /// Creates the database instance.
  ///
  /// In production, [executor] defaults to [_openConnection], which writes
  /// to a persistent SQLite file on disk. In tests, pass `NativeDatabase.memory()`
  /// for fast, isolated in-memory testing.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

/// Opens a persistent connection to the SQLite database on disk.
///
/// The file is stored in the application documents directory as
/// `receipt_vault.sqlite`. Operations run in a background isolate
/// via [NativeDatabase.createInBackground] to avoid blocking UI frames.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'receipt_vault.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
