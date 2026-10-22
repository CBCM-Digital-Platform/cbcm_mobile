import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Logbook entries written on the phone. They work offline and are sent
/// to the server later through the sync queue.
@DataClassName('LogbookRow')
class LogbookEntries extends Table {
  TextColumn get localId => text()(); // generated on the phone
  IntColumn get serverId => integer().nullable()(); // set after first sync
  TextColumn get menteeId => text()();
  TextColumn get procedureType => text()();
  RealColumn get hours => real()();
  TextColumn get clinicalNotes => text().withDefault(const Constant(''))();
  // draft / submitted / approved / revision_requested
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get revisionReason => text().nullable()();
  TextColumn get outcome => text().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // pending / synced / failed
  TextColumn get syncState => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Changes waiting to be sent to the server, oldest first.
@DataClassName('SyncQueueRow')
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // e.g. 'logbook_entry'
  TextColumn get entityId => text()(); // the local id
  TextColumn get operation => text()(); // create / update / delete
  TextColumn get payload => text()(); // JSON snapshot of the change
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Lesson progress saved on the phone, so it survives an app restart.
@DataClassName('LessonProgressRow')
class LessonProgressRows extends Table {
  TextColumn get menteeId => text()();
  TextColumn get lessonId => text()();
  TextColumn get status => text()(); // notStarted / inProgress / completed
  RealColumn get progressPercent => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {menteeId, lessonId};
}

@DriftDatabase(tables: [LogbookEntries, SyncQueueItems, LessonProgressRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'cbcm_app'));

  @override
  int get schemaVersion => 1;
}