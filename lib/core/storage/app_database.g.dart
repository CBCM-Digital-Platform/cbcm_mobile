// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LogbookEntriesTable extends LogbookEntries
    with TableInfo<$LogbookEntriesTable, LogbookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogbookEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _menteeIdMeta = const VerificationMeta(
    'menteeId',
  );
  @override
  late final GeneratedColumn<String> menteeId = GeneratedColumn<String>(
    'mentee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _procedureTypeMeta = const VerificationMeta(
    'procedureType',
  );
  @override
  late final GeneratedColumn<String> procedureType = GeneratedColumn<String>(
    'procedure_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursMeta = const VerificationMeta('hours');
  @override
  late final GeneratedColumn<double> hours = GeneratedColumn<double>(
    'hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clinicalNotesMeta = const VerificationMeta(
    'clinicalNotes',
  );
  @override
  late final GeneratedColumn<String> clinicalNotes = GeneratedColumn<String>(
    'clinical_notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _revisionReasonMeta = const VerificationMeta(
    'revisionReason',
  );
  @override
  late final GeneratedColumn<String> revisionReason = GeneratedColumn<String>(
    'revision_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    menteeId,
    procedureType,
    hours,
    clinicalNotes,
    status,
    revisionReason,
    outcome,
    loggedAt,
    updatedAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'logbook_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogbookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('mentee_id')) {
      context.handle(
        _menteeIdMeta,
        menteeId.isAcceptableOrUnknown(data['mentee_id']!, _menteeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_menteeIdMeta);
    }
    if (data.containsKey('procedure_type')) {
      context.handle(
        _procedureTypeMeta,
        procedureType.isAcceptableOrUnknown(
          data['procedure_type']!,
          _procedureTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_procedureTypeMeta);
    }
    if (data.containsKey('hours')) {
      context.handle(
        _hoursMeta,
        hours.isAcceptableOrUnknown(data['hours']!, _hoursMeta),
      );
    } else if (isInserting) {
      context.missing(_hoursMeta);
    }
    if (data.containsKey('clinical_notes')) {
      context.handle(
        _clinicalNotesMeta,
        clinicalNotes.isAcceptableOrUnknown(
          data['clinical_notes']!,
          _clinicalNotesMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('revision_reason')) {
      context.handle(
        _revisionReasonMeta,
        revisionReason.isAcceptableOrUnknown(
          data['revision_reason']!,
          _revisionReasonMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LogbookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogbookRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      menteeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mentee_id'],
      )!,
      procedureType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}procedure_type'],
      )!,
      hours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hours'],
      )!,
      clinicalNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinical_notes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      revisionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_reason'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
    );
  }

  @override
  $LogbookEntriesTable createAlias(String alias) {
    return $LogbookEntriesTable(attachedDatabase, alias);
  }
}

class LogbookRow extends DataClass implements Insertable<LogbookRow> {
  final String localId;
  final int? serverId;
  final String menteeId;
  final String procedureType;
  final double hours;
  final String clinicalNotes;
  final String status;
  final String? revisionReason;
  final String? outcome;
  final DateTime loggedAt;
  final DateTime updatedAt;
  final String syncState;
  const LogbookRow({
    required this.localId,
    this.serverId,
    required this.menteeId,
    required this.procedureType,
    required this.hours,
    required this.clinicalNotes,
    required this.status,
    this.revisionReason,
    this.outcome,
    required this.loggedAt,
    required this.updatedAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['mentee_id'] = Variable<String>(menteeId);
    map['procedure_type'] = Variable<String>(procedureType);
    map['hours'] = Variable<double>(hours);
    map['clinical_notes'] = Variable<String>(clinicalNotes);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || revisionReason != null) {
      map['revision_reason'] = Variable<String>(revisionReason);
    }
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  LogbookEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogbookEntriesCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      menteeId: Value(menteeId),
      procedureType: Value(procedureType),
      hours: Value(hours),
      clinicalNotes: Value(clinicalNotes),
      status: Value(status),
      revisionReason: revisionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(revisionReason),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      loggedAt: Value(loggedAt),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
    );
  }

  factory LogbookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogbookRow(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      menteeId: serializer.fromJson<String>(json['menteeId']),
      procedureType: serializer.fromJson<String>(json['procedureType']),
      hours: serializer.fromJson<double>(json['hours']),
      clinicalNotes: serializer.fromJson<String>(json['clinicalNotes']),
      status: serializer.fromJson<String>(json['status']),
      revisionReason: serializer.fromJson<String?>(json['revisionReason']),
      outcome: serializer.fromJson<String?>(json['outcome']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<int?>(serverId),
      'menteeId': serializer.toJson<String>(menteeId),
      'procedureType': serializer.toJson<String>(procedureType),
      'hours': serializer.toJson<double>(hours),
      'clinicalNotes': serializer.toJson<String>(clinicalNotes),
      'status': serializer.toJson<String>(status),
      'revisionReason': serializer.toJson<String?>(revisionReason),
      'outcome': serializer.toJson<String?>(outcome),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  LogbookRow copyWith({
    String? localId,
    Value<int?> serverId = const Value.absent(),
    String? menteeId,
    String? procedureType,
    double? hours,
    String? clinicalNotes,
    String? status,
    Value<String?> revisionReason = const Value.absent(),
    Value<String?> outcome = const Value.absent(),
    DateTime? loggedAt,
    DateTime? updatedAt,
    String? syncState,
  }) => LogbookRow(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    menteeId: menteeId ?? this.menteeId,
    procedureType: procedureType ?? this.procedureType,
    hours: hours ?? this.hours,
    clinicalNotes: clinicalNotes ?? this.clinicalNotes,
    status: status ?? this.status,
    revisionReason: revisionReason.present
        ? revisionReason.value
        : this.revisionReason,
    outcome: outcome.present ? outcome.value : this.outcome,
    loggedAt: loggedAt ?? this.loggedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncState: syncState ?? this.syncState,
  );
  LogbookRow copyWithCompanion(LogbookEntriesCompanion data) {
    return LogbookRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      menteeId: data.menteeId.present ? data.menteeId.value : this.menteeId,
      procedureType: data.procedureType.present
          ? data.procedureType.value
          : this.procedureType,
      hours: data.hours.present ? data.hours.value : this.hours,
      clinicalNotes: data.clinicalNotes.present
          ? data.clinicalNotes.value
          : this.clinicalNotes,
      status: data.status.present ? data.status.value : this.status,
      revisionReason: data.revisionReason.present
          ? data.revisionReason.value
          : this.revisionReason,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogbookRow(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('menteeId: $menteeId, ')
          ..write('procedureType: $procedureType, ')
          ..write('hours: $hours, ')
          ..write('clinicalNotes: $clinicalNotes, ')
          ..write('status: $status, ')
          ..write('revisionReason: $revisionReason, ')
          ..write('outcome: $outcome, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    serverId,
    menteeId,
    procedureType,
    hours,
    clinicalNotes,
    status,
    revisionReason,
    outcome,
    loggedAt,
    updatedAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogbookRow &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.menteeId == this.menteeId &&
          other.procedureType == this.procedureType &&
          other.hours == this.hours &&
          other.clinicalNotes == this.clinicalNotes &&
          other.status == this.status &&
          other.revisionReason == this.revisionReason &&
          other.outcome == this.outcome &&
          other.loggedAt == this.loggedAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState);
}

class LogbookEntriesCompanion extends UpdateCompanion<LogbookRow> {
  final Value<String> localId;
  final Value<int?> serverId;
  final Value<String> menteeId;
  final Value<String> procedureType;
  final Value<double> hours;
  final Value<String> clinicalNotes;
  final Value<String> status;
  final Value<String?> revisionReason;
  final Value<String?> outcome;
  final Value<DateTime> loggedAt;
  final Value<DateTime> updatedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const LogbookEntriesCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.menteeId = const Value.absent(),
    this.procedureType = const Value.absent(),
    this.hours = const Value.absent(),
    this.clinicalNotes = const Value.absent(),
    this.status = const Value.absent(),
    this.revisionReason = const Value.absent(),
    this.outcome = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LogbookEntriesCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String menteeId,
    required String procedureType,
    required double hours,
    this.clinicalNotes = const Value.absent(),
    this.status = const Value.absent(),
    this.revisionReason = const Value.absent(),
    this.outcome = const Value.absent(),
    required DateTime loggedAt,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       menteeId = Value(menteeId),
       procedureType = Value(procedureType),
       hours = Value(hours),
       loggedAt = Value(loggedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LogbookRow> custom({
    Expression<String>? localId,
    Expression<int>? serverId,
    Expression<String>? menteeId,
    Expression<String>? procedureType,
    Expression<double>? hours,
    Expression<String>? clinicalNotes,
    Expression<String>? status,
    Expression<String>? revisionReason,
    Expression<String>? outcome,
    Expression<DateTime>? loggedAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (menteeId != null) 'mentee_id': menteeId,
      if (procedureType != null) 'procedure_type': procedureType,
      if (hours != null) 'hours': hours,
      if (clinicalNotes != null) 'clinical_notes': clinicalNotes,
      if (status != null) 'status': status,
      if (revisionReason != null) 'revision_reason': revisionReason,
      if (outcome != null) 'outcome': outcome,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LogbookEntriesCompanion copyWith({
    Value<String>? localId,
    Value<int?>? serverId,
    Value<String>? menteeId,
    Value<String>? procedureType,
    Value<double>? hours,
    Value<String>? clinicalNotes,
    Value<String>? status,
    Value<String?>? revisionReason,
    Value<String?>? outcome,
    Value<DateTime>? loggedAt,
    Value<DateTime>? updatedAt,
    Value<String>? syncState,
    Value<int>? rowid,
  }) {
    return LogbookEntriesCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      menteeId: menteeId ?? this.menteeId,
      procedureType: procedureType ?? this.procedureType,
      hours: hours ?? this.hours,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      status: status ?? this.status,
      revisionReason: revisionReason ?? this.revisionReason,
      outcome: outcome ?? this.outcome,
      loggedAt: loggedAt ?? this.loggedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (menteeId.present) {
      map['mentee_id'] = Variable<String>(menteeId.value);
    }
    if (procedureType.present) {
      map['procedure_type'] = Variable<String>(procedureType.value);
    }
    if (hours.present) {
      map['hours'] = Variable<double>(hours.value);
    }
    if (clinicalNotes.present) {
      map['clinical_notes'] = Variable<String>(clinicalNotes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (revisionReason.present) {
      map['revision_reason'] = Variable<String>(revisionReason.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogbookEntriesCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('menteeId: $menteeId, ')
          ..write('procedureType: $procedureType, ')
          ..write('hours: $hours, ')
          ..write('clinicalNotes: $clinicalNotes, ')
          ..write('status: $status, ')
          ..write('revisionReason: $revisionReason, ')
          ..write('outcome: $outcome, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payload,
    attempts,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final int id;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  const SyncQueueRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.attempts,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueRow copyWith({
    int? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => SyncQueueRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueRow copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payload,
    attempts,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payload,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueItemsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressRowsTable extends LessonProgressRows
    with TableInfo<$LessonProgressRowsTable, LessonProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _menteeIdMeta = const VerificationMeta(
    'menteeId',
  );
  @override
  late final GeneratedColumn<String> menteeId = GeneratedColumn<String>(
    'mentee_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<double> progressPercent = GeneratedColumn<double>(
    'progress_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    menteeId,
    lessonId,
    status,
    progressPercent,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mentee_id')) {
      context.handle(
        _menteeIdMeta,
        menteeId.isAcceptableOrUnknown(data['mentee_id']!, _menteeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_menteeIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {menteeId, lessonId};
  @override
  LessonProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressRow(
      menteeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mentee_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_percent'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LessonProgressRowsTable createAlias(String alias) {
    return $LessonProgressRowsTable(attachedDatabase, alias);
  }
}

class LessonProgressRow extends DataClass
    implements Insertable<LessonProgressRow> {
  final String menteeId;
  final String lessonId;
  final String status;
  final double progressPercent;
  final DateTime updatedAt;
  const LessonProgressRow({
    required this.menteeId,
    required this.lessonId,
    required this.status,
    required this.progressPercent,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mentee_id'] = Variable<String>(menteeId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['status'] = Variable<String>(status);
    map['progress_percent'] = Variable<double>(progressPercent);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LessonProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressRowsCompanion(
      menteeId: Value(menteeId),
      lessonId: Value(lessonId),
      status: Value(status),
      progressPercent: Value(progressPercent),
      updatedAt: Value(updatedAt),
    );
  }

  factory LessonProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressRow(
      menteeId: serializer.fromJson<String>(json['menteeId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      status: serializer.fromJson<String>(json['status']),
      progressPercent: serializer.fromJson<double>(json['progressPercent']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'menteeId': serializer.toJson<String>(menteeId),
      'lessonId': serializer.toJson<String>(lessonId),
      'status': serializer.toJson<String>(status),
      'progressPercent': serializer.toJson<double>(progressPercent),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LessonProgressRow copyWith({
    String? menteeId,
    String? lessonId,
    String? status,
    double? progressPercent,
    DateTime? updatedAt,
  }) => LessonProgressRow(
    menteeId: menteeId ?? this.menteeId,
    lessonId: lessonId ?? this.lessonId,
    status: status ?? this.status,
    progressPercent: progressPercent ?? this.progressPercent,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LessonProgressRow copyWithCompanion(LessonProgressRowsCompanion data) {
    return LessonProgressRow(
      menteeId: data.menteeId.present ? data.menteeId.value : this.menteeId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      status: data.status.present ? data.status.value : this.status,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressRow(')
          ..write('menteeId: $menteeId, ')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(menteeId, lessonId, status, progressPercent, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressRow &&
          other.menteeId == this.menteeId &&
          other.lessonId == this.lessonId &&
          other.status == this.status &&
          other.progressPercent == this.progressPercent &&
          other.updatedAt == this.updatedAt);
}

class LessonProgressRowsCompanion extends UpdateCompanion<LessonProgressRow> {
  final Value<String> menteeId;
  final Value<String> lessonId;
  final Value<String> status;
  final Value<double> progressPercent;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LessonProgressRowsCompanion({
    this.menteeId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.status = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressRowsCompanion.insert({
    required String menteeId,
    required String lessonId,
    required String status,
    this.progressPercent = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : menteeId = Value(menteeId),
       lessonId = Value(lessonId),
       status = Value(status),
       updatedAt = Value(updatedAt);
  static Insertable<LessonProgressRow> custom({
    Expression<String>? menteeId,
    Expression<String>? lessonId,
    Expression<String>? status,
    Expression<double>? progressPercent,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (menteeId != null) 'mentee_id': menteeId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (status != null) 'status': status,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressRowsCompanion copyWith({
    Value<String>? menteeId,
    Value<String>? lessonId,
    Value<String>? status,
    Value<double>? progressPercent,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LessonProgressRowsCompanion(
      menteeId: menteeId ?? this.menteeId,
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (menteeId.present) {
      map['mentee_id'] = Variable<String>(menteeId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<double>(progressPercent.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressRowsCompanion(')
          ..write('menteeId: $menteeId, ')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LogbookEntriesTable logbookEntries = $LogbookEntriesTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  late final $LessonProgressRowsTable lessonProgressRows =
      $LessonProgressRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    logbookEntries,
    syncQueueItems,
    lessonProgressRows,
  ];
}

typedef $$LogbookEntriesTableCreateCompanionBuilder =
    LogbookEntriesCompanion Function({
      required String localId,
      Value<int?> serverId,
      required String menteeId,
      required String procedureType,
      required double hours,
      Value<String> clinicalNotes,
      Value<String> status,
      Value<String?> revisionReason,
      Value<String?> outcome,
      required DateTime loggedAt,
      required DateTime updatedAt,
      Value<String> syncState,
      Value<int> rowid,
    });
typedef $$LogbookEntriesTableUpdateCompanionBuilder =
    LogbookEntriesCompanion Function({
      Value<String> localId,
      Value<int?> serverId,
      Value<String> menteeId,
      Value<String> procedureType,
      Value<double> hours,
      Value<String> clinicalNotes,
      Value<String> status,
      Value<String?> revisionReason,
      Value<String?> outcome,
      Value<DateTime> loggedAt,
      Value<DateTime> updatedAt,
      Value<String> syncState,
      Value<int> rowid,
    });

class $$LogbookEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogbookEntriesTable> {
  $$LogbookEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get menteeId => $composableBuilder(
    column: $table.menteeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get procedureType => $composableBuilder(
    column: $table.procedureType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicalNotes => $composableBuilder(
    column: $table.clinicalNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionReason => $composableBuilder(
    column: $table.revisionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LogbookEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogbookEntriesTable> {
  $$LogbookEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get menteeId => $composableBuilder(
    column: $table.menteeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get procedureType => $composableBuilder(
    column: $table.procedureType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hours => $composableBuilder(
    column: $table.hours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicalNotes => $composableBuilder(
    column: $table.clinicalNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionReason => $composableBuilder(
    column: $table.revisionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogbookEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogbookEntriesTable> {
  $$LogbookEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get menteeId =>
      $composableBuilder(column: $table.menteeId, builder: (column) => column);

  GeneratedColumn<String> get procedureType => $composableBuilder(
    column: $table.procedureType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hours =>
      $composableBuilder(column: $table.hours, builder: (column) => column);

  GeneratedColumn<String> get clinicalNotes => $composableBuilder(
    column: $table.clinicalNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get revisionReason => $composableBuilder(
    column: $table.revisionReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$LogbookEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogbookEntriesTable,
          LogbookRow,
          $$LogbookEntriesTableFilterComposer,
          $$LogbookEntriesTableOrderingComposer,
          $$LogbookEntriesTableAnnotationComposer,
          $$LogbookEntriesTableCreateCompanionBuilder,
          $$LogbookEntriesTableUpdateCompanionBuilder,
          (
            LogbookRow,
            BaseReferences<_$AppDatabase, $LogbookEntriesTable, LogbookRow>,
          ),
          LogbookRow,
          PrefetchHooks Function()
        > {
  $$LogbookEntriesTableTableManager(
    _$AppDatabase db,
    $LogbookEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogbookEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogbookEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogbookEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> menteeId = const Value.absent(),
                Value<String> procedureType = const Value.absent(),
                Value<double> hours = const Value.absent(),
                Value<String> clinicalNotes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> revisionReason = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogbookEntriesCompanion(
                localId: localId,
                serverId: serverId,
                menteeId: menteeId,
                procedureType: procedureType,
                hours: hours,
                clinicalNotes: clinicalNotes,
                status: status,
                revisionReason: revisionReason,
                outcome: outcome,
                loggedAt: loggedAt,
                updatedAt: updatedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<int?> serverId = const Value.absent(),
                required String menteeId,
                required String procedureType,
                required double hours,
                Value<String> clinicalNotes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> revisionReason = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                required DateTime loggedAt,
                required DateTime updatedAt,
                Value<String> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogbookEntriesCompanion.insert(
                localId: localId,
                serverId: serverId,
                menteeId: menteeId,
                procedureType: procedureType,
                hours: hours,
                clinicalNotes: clinicalNotes,
                status: status,
                revisionReason: revisionReason,
                outcome: outcome,
                loggedAt: loggedAt,
                updatedAt: updatedAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LogbookEntriesTable, LogbookRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LogbookEntriesTable,
                    LogbookRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogbookEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogbookEntriesTable,
      LogbookRow,
      $$LogbookEntriesTableFilterComposer,
      $$LogbookEntriesTableOrderingComposer,
      $$LogbookEntriesTableAnnotationComposer,
      $$LogbookEntriesTableCreateCompanionBuilder,
      $$LogbookEntriesTableUpdateCompanionBuilder,
      (
        LogbookRow,
        BaseReferences<_$AppDatabase, $LogbookEntriesTable, LogbookRow>,
      ),
      LogbookRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueItemsTableCreateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      required String entityType,
      required String entityId,
      required String operation,
      required String payload,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
    });
typedef $$SyncQueueItemsTableUpdateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payload,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueItemsTable,
          SyncQueueRow,
          $$SyncQueueItemsTableFilterComposer,
          $$SyncQueueItemsTableOrderingComposer,
          $$SyncQueueItemsTableAnnotationComposer,
          $$SyncQueueItemsTableCreateCompanionBuilder,
          $$SyncQueueItemsTableUpdateCompanionBuilder,
          (
            SyncQueueRow,
            BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueRow>,
          ),
          SyncQueueRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableManager(
    _$AppDatabase db,
    $SyncQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueItemsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required String operation,
                required String payload,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => SyncQueueItemsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payload: payload,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueItemsTable, SyncQueueRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncQueueItemsTable,
                    SyncQueueRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueItemsTable,
      SyncQueueRow,
      $$SyncQueueItemsTableFilterComposer,
      $$SyncQueueItemsTableOrderingComposer,
      $$SyncQueueItemsTableAnnotationComposer,
      $$SyncQueueItemsTableCreateCompanionBuilder,
      $$SyncQueueItemsTableUpdateCompanionBuilder,
      (
        SyncQueueRow,
        BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueRow>,
      ),
      SyncQueueRow,
      PrefetchHooks Function()
    >;
typedef $$LessonProgressRowsTableCreateCompanionBuilder =
    LessonProgressRowsCompanion Function({
      required String menteeId,
      required String lessonId,
      required String status,
      Value<double> progressPercent,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LessonProgressRowsTableUpdateCompanionBuilder =
    LessonProgressRowsCompanion Function({
      Value<String> menteeId,
      Value<String> lessonId,
      Value<String> status,
      Value<double> progressPercent,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LessonProgressRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonProgressRowsTable> {
  $$LessonProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get menteeId => $composableBuilder(
    column: $table.menteeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LessonProgressRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonProgressRowsTable> {
  $$LessonProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get menteeId => $composableBuilder(
    column: $table.menteeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonProgressRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonProgressRowsTable> {
  $$LessonProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get menteeId =>
      $composableBuilder(column: $table.menteeId, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LessonProgressRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonProgressRowsTable,
          LessonProgressRow,
          $$LessonProgressRowsTableFilterComposer,
          $$LessonProgressRowsTableOrderingComposer,
          $$LessonProgressRowsTableAnnotationComposer,
          $$LessonProgressRowsTableCreateCompanionBuilder,
          $$LessonProgressRowsTableUpdateCompanionBuilder,
          (
            LessonProgressRow,
            BaseReferences<
              _$AppDatabase,
              $LessonProgressRowsTable,
              LessonProgressRow
            >,
          ),
          LessonProgressRow,
          PrefetchHooks Function()
        > {
  $$LessonProgressRowsTableTableManager(
    _$AppDatabase db,
    $LessonProgressRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonProgressRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> menteeId = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressRowsCompanion(
                menteeId: menteeId,
                lessonId: lessonId,
                status: status,
                progressPercent: progressPercent,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String menteeId,
                required String lessonId,
                required String status,
                Value<double> progressPercent = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressRowsCompanion.insert(
                menteeId: menteeId,
                lessonId: lessonId,
                status: status,
                progressPercent: progressPercent,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LessonProgressRowsTable, LessonProgressRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LessonProgressRowsTable,
                    LessonProgressRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonProgressRowsTable,
      LessonProgressRow,
      $$LessonProgressRowsTableFilterComposer,
      $$LessonProgressRowsTableOrderingComposer,
      $$LessonProgressRowsTableAnnotationComposer,
      $$LessonProgressRowsTableCreateCompanionBuilder,
      $$LessonProgressRowsTableUpdateCompanionBuilder,
      (
        LessonProgressRow,
        BaseReferences<
          _$AppDatabase,
          $LessonProgressRowsTable,
          LessonProgressRow
        >,
      ),
      LessonProgressRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LogbookEntriesTableTableManager get logbookEntries =>
      $$LogbookEntriesTableTableManager(_db, _db.logbookEntries);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
  $$LessonProgressRowsTableTableManager get lessonProgressRows =>
      $$LessonProgressRowsTableTableManager(_db, _db.lessonProgressRows);
}
