// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarIndexMeta = const VerificationMeta(
    'avatarIndex',
  );
  @override
  late final GeneratedColumn<int> avatarIndex = GeneratedColumn<int>(
    'avatar_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('member'),
  );
  static const VerificationMeta _fontSizeMeta = const VerificationMeta(
    'fontSize',
  );
  @override
  late final GeneratedColumn<int> fontSize = GeneratedColumn<int>(
    'font_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _accessTypeMeta = const VerificationMeta(
    'accessType',
  );
  @override
  late final GeneratedColumn<String> accessType = GeneratedColumn<String>(
    'access_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessCodeMeta = const VerificationMeta(
    'accessCode',
  );
  @override
  late final GeneratedColumn<String> accessCode = GeneratedColumn<String>(
    'access_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telegramChatIdMeta = const VerificationMeta(
    'telegramChatId',
  );
  @override
  late final GeneratedColumn<String> telegramChatId = GeneratedColumn<String>(
    'telegram_chat_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationChannelsMeta =
      const VerificationMeta('notificationChannels');
  @override
  late final GeneratedColumn<String> notificationChannels =
      GeneratedColumn<String>(
        'notification_channels',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('["push"]'),
      );
  static const VerificationMeta _contactMeta = const VerificationMeta(
    'contact',
  );
  @override
  late final GeneratedColumn<String> contact = GeneratedColumn<String>(
    'contact',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    avatarIndex,
    role,
    fontSize,
    accessType,
    accessCode,
    telegramChatId,
    notificationChannels,
    contact,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<Member> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_index')) {
      context.handle(
        _avatarIndexMeta,
        avatarIndex.isAcceptableOrUnknown(
          data['avatar_index']!,
          _avatarIndexMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('font_size')) {
      context.handle(
        _fontSizeMeta,
        fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta),
      );
    }
    if (data.containsKey('access_type')) {
      context.handle(
        _accessTypeMeta,
        accessType.isAcceptableOrUnknown(data['access_type']!, _accessTypeMeta),
      );
    }
    if (data.containsKey('access_code')) {
      context.handle(
        _accessCodeMeta,
        accessCode.isAcceptableOrUnknown(data['access_code']!, _accessCodeMeta),
      );
    }
    if (data.containsKey('telegram_chat_id')) {
      context.handle(
        _telegramChatIdMeta,
        telegramChatId.isAcceptableOrUnknown(
          data['telegram_chat_id']!,
          _telegramChatIdMeta,
        ),
      );
    }
    if (data.containsKey('notification_channels')) {
      context.handle(
        _notificationChannelsMeta,
        notificationChannels.isAcceptableOrUnknown(
          data['notification_channels']!,
          _notificationChannelsMeta,
        ),
      );
    }
    if (data.containsKey('contact')) {
      context.handle(
        _contactMeta,
        contact.isAcceptableOrUnknown(data['contact']!, _contactMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_index'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      fontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}font_size'],
      )!,
      accessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_type'],
      ),
      accessCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_code'],
      ),
      telegramChatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telegram_chat_id'],
      ),
      notificationChannels: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_channels'],
      )!,
      contact: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final int id;
  final String name;
  final int avatarIndex;
  final String role;
  final int fontSize;
  final String? accessType;
  final String? accessCode;
  final String? telegramChatId;
  final String notificationChannels;
  final String? contact;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Member({
    required this.id,
    required this.name,
    required this.avatarIndex,
    required this.role,
    required this.fontSize,
    this.accessType,
    this.accessCode,
    this.telegramChatId,
    required this.notificationChannels,
    this.contact,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['avatar_index'] = Variable<int>(avatarIndex);
    map['role'] = Variable<String>(role);
    map['font_size'] = Variable<int>(fontSize);
    if (!nullToAbsent || accessType != null) {
      map['access_type'] = Variable<String>(accessType);
    }
    if (!nullToAbsent || accessCode != null) {
      map['access_code'] = Variable<String>(accessCode);
    }
    if (!nullToAbsent || telegramChatId != null) {
      map['telegram_chat_id'] = Variable<String>(telegramChatId);
    }
    map['notification_channels'] = Variable<String>(notificationChannels);
    if (!nullToAbsent || contact != null) {
      map['contact'] = Variable<String>(contact);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      name: Value(name),
      avatarIndex: Value(avatarIndex),
      role: Value(role),
      fontSize: Value(fontSize),
      accessType: accessType == null && nullToAbsent
          ? const Value.absent()
          : Value(accessType),
      accessCode: accessCode == null && nullToAbsent
          ? const Value.absent()
          : Value(accessCode),
      telegramChatId: telegramChatId == null && nullToAbsent
          ? const Value.absent()
          : Value(telegramChatId),
      notificationChannels: Value(notificationChannels),
      contact: contact == null && nullToAbsent
          ? const Value.absent()
          : Value(contact),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Member.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarIndex: serializer.fromJson<int>(json['avatarIndex']),
      role: serializer.fromJson<String>(json['role']),
      fontSize: serializer.fromJson<int>(json['fontSize']),
      accessType: serializer.fromJson<String?>(json['accessType']),
      accessCode: serializer.fromJson<String?>(json['accessCode']),
      telegramChatId: serializer.fromJson<String?>(json['telegramChatId']),
      notificationChannels: serializer.fromJson<String>(
        json['notificationChannels'],
      ),
      contact: serializer.fromJson<String?>(json['contact']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'avatarIndex': serializer.toJson<int>(avatarIndex),
      'role': serializer.toJson<String>(role),
      'fontSize': serializer.toJson<int>(fontSize),
      'accessType': serializer.toJson<String?>(accessType),
      'accessCode': serializer.toJson<String?>(accessCode),
      'telegramChatId': serializer.toJson<String?>(telegramChatId),
      'notificationChannels': serializer.toJson<String>(notificationChannels),
      'contact': serializer.toJson<String?>(contact),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Member copyWith({
    int? id,
    String? name,
    int? avatarIndex,
    String? role,
    int? fontSize,
    Value<String?> accessType = const Value.absent(),
    Value<String?> accessCode = const Value.absent(),
    Value<String?> telegramChatId = const Value.absent(),
    String? notificationChannels,
    Value<String?> contact = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Member(
    id: id ?? this.id,
    name: name ?? this.name,
    avatarIndex: avatarIndex ?? this.avatarIndex,
    role: role ?? this.role,
    fontSize: fontSize ?? this.fontSize,
    accessType: accessType.present ? accessType.value : this.accessType,
    accessCode: accessCode.present ? accessCode.value : this.accessCode,
    telegramChatId: telegramChatId.present
        ? telegramChatId.value
        : this.telegramChatId,
    notificationChannels: notificationChannels ?? this.notificationChannels,
    contact: contact.present ? contact.value : this.contact,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarIndex: data.avatarIndex.present
          ? data.avatarIndex.value
          : this.avatarIndex,
      role: data.role.present ? data.role.value : this.role,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      accessType: data.accessType.present
          ? data.accessType.value
          : this.accessType,
      accessCode: data.accessCode.present
          ? data.accessCode.value
          : this.accessCode,
      telegramChatId: data.telegramChatId.present
          ? data.telegramChatId.value
          : this.telegramChatId,
      notificationChannels: data.notificationChannels.present
          ? data.notificationChannels.value
          : this.notificationChannels,
      contact: data.contact.present ? data.contact.value : this.contact,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarIndex: $avatarIndex, ')
          ..write('role: $role, ')
          ..write('fontSize: $fontSize, ')
          ..write('accessType: $accessType, ')
          ..write('accessCode: $accessCode, ')
          ..write('telegramChatId: $telegramChatId, ')
          ..write('notificationChannels: $notificationChannels, ')
          ..write('contact: $contact, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    avatarIndex,
    role,
    fontSize,
    accessType,
    accessCode,
    telegramChatId,
    notificationChannels,
    contact,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarIndex == this.avatarIndex &&
          other.role == this.role &&
          other.fontSize == this.fontSize &&
          other.accessType == this.accessType &&
          other.accessCode == this.accessCode &&
          other.telegramChatId == this.telegramChatId &&
          other.notificationChannels == this.notificationChannels &&
          other.contact == this.contact &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> avatarIndex;
  final Value<String> role;
  final Value<int> fontSize;
  final Value<String?> accessType;
  final Value<String?> accessCode;
  final Value<String?> telegramChatId;
  final Value<String> notificationChannels;
  final Value<String?> contact;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarIndex = const Value.absent(),
    this.role = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.accessType = const Value.absent(),
    this.accessCode = const Value.absent(),
    this.telegramChatId = const Value.absent(),
    this.notificationChannels = const Value.absent(),
    this.contact = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MembersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.avatarIndex = const Value.absent(),
    this.role = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.accessType = const Value.absent(),
    this.accessCode = const Value.absent(),
    this.telegramChatId = const Value.absent(),
    this.notificationChannels = const Value.absent(),
    this.contact = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Member> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? avatarIndex,
    Expression<String>? role,
    Expression<int>? fontSize,
    Expression<String>? accessType,
    Expression<String>? accessCode,
    Expression<String>? telegramChatId,
    Expression<String>? notificationChannels,
    Expression<String>? contact,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarIndex != null) 'avatar_index': avatarIndex,
      if (role != null) 'role': role,
      if (fontSize != null) 'font_size': fontSize,
      if (accessType != null) 'access_type': accessType,
      if (accessCode != null) 'access_code': accessCode,
      if (telegramChatId != null) 'telegram_chat_id': telegramChatId,
      if (notificationChannels != null)
        'notification_channels': notificationChannels,
      if (contact != null) 'contact': contact,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MembersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? avatarIndex,
    Value<String>? role,
    Value<int>? fontSize,
    Value<String?>? accessType,
    Value<String?>? accessCode,
    Value<String?>? telegramChatId,
    Value<String>? notificationChannels,
    Value<String?>? contact,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      role: role ?? this.role,
      fontSize: fontSize ?? this.fontSize,
      accessType: accessType ?? this.accessType,
      accessCode: accessCode ?? this.accessCode,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      notificationChannels: notificationChannels ?? this.notificationChannels,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarIndex.present) {
      map['avatar_index'] = Variable<int>(avatarIndex.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<int>(fontSize.value);
    }
    if (accessType.present) {
      map['access_type'] = Variable<String>(accessType.value);
    }
    if (accessCode.present) {
      map['access_code'] = Variable<String>(accessCode.value);
    }
    if (telegramChatId.present) {
      map['telegram_chat_id'] = Variable<String>(telegramChatId.value);
    }
    if (notificationChannels.present) {
      map['notification_channels'] = Variable<String>(
        notificationChannels.value,
      );
    }
    if (contact.present) {
      map['contact'] = Variable<String>(contact.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarIndex: $avatarIndex, ')
          ..write('role: $role, ')
          ..write('fontSize: $fontSize, ')
          ..write('accessType: $accessType, ')
          ..write('accessCode: $accessCode, ')
          ..write('telegramChatId: $telegramChatId, ')
          ..write('notificationChannels: $notificationChannels, ')
          ..write('contact: $contact, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
    'form',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('tablet'),
  );
  static const VerificationMeta _doseAmountMeta = const VerificationMeta(
    'doseAmount',
  );
  @override
  late final GeneratedColumn<double> doseAmount = GeneratedColumn<double>(
    'dose_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doseUnitMeta = const VerificationMeta(
    'doseUnit',
  );
  @override
  late final GeneratedColumn<String> doseUnit = GeneratedColumn<String>(
    'dose_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('мг'),
  );
  static const VerificationMeta _foodRelationMeta = const VerificationMeta(
    'foodRelation',
  );
  @override
  late final GeneratedColumn<String> foodRelation = GeneratedColumn<String>(
    'food_relation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('any'),
  );
  static const VerificationMeta _repeatTypeMeta = const VerificationMeta(
    'repeatType',
  );
  @override
  late final GeneratedColumn<String> repeatType = GeneratedColumn<String>(
    'repeat_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
  );
  static const VerificationMeta _repeatConfigMeta = const VerificationMeta(
    'repeatConfig',
  );
  @override
  late final GeneratedColumn<String> repeatConfig = GeneratedColumn<String>(
    'repeat_config',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCountMeta = const VerificationMeta(
    'totalCount',
  );
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
    'total_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remainingCountMeta = const VerificationMeta(
    'remainingCount',
  );
  @override
  late final GeneratedColumn<int> remainingCount = GeneratedColumn<int>(
    'remaining_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _photoPathsMeta = const VerificationMeta(
    'photoPaths',
  );
  @override
  late final GeneratedColumn<String> photoPaths = GeneratedColumn<String>(
    'photo_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phasesMeta = const VerificationMeta('phases');
  @override
  late final GeneratedColumn<String> phases = GeneratedColumn<String>(
    'phases',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockPercentMeta = const VerificationMeta(
    'stockPercent',
  );
  @override
  late final GeneratedColumn<int> stockPercent = GeneratedColumn<int>(
    'stock_percent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    form,
    doseAmount,
    doseUnit,
    foodRelation,
    repeatType,
    repeatConfig,
    startDate,
    endDate,
    totalCount,
    remainingCount,
    photoPaths,
    instructions,
    phases,
    stockPercent,
    openedAt,
    isActive,
    createdAt,
    updatedAt,
    syncUuid,
    color,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    }
    if (data.containsKey('dose_amount')) {
      context.handle(
        _doseAmountMeta,
        doseAmount.isAcceptableOrUnknown(data['dose_amount']!, _doseAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_doseAmountMeta);
    }
    if (data.containsKey('dose_unit')) {
      context.handle(
        _doseUnitMeta,
        doseUnit.isAcceptableOrUnknown(data['dose_unit']!, _doseUnitMeta),
      );
    }
    if (data.containsKey('food_relation')) {
      context.handle(
        _foodRelationMeta,
        foodRelation.isAcceptableOrUnknown(
          data['food_relation']!,
          _foodRelationMeta,
        ),
      );
    }
    if (data.containsKey('repeat_type')) {
      context.handle(
        _repeatTypeMeta,
        repeatType.isAcceptableOrUnknown(data['repeat_type']!, _repeatTypeMeta),
      );
    }
    if (data.containsKey('repeat_config')) {
      context.handle(
        _repeatConfigMeta,
        repeatConfig.isAcceptableOrUnknown(
          data['repeat_config']!,
          _repeatConfigMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('total_count')) {
      context.handle(
        _totalCountMeta,
        totalCount.isAcceptableOrUnknown(data['total_count']!, _totalCountMeta),
      );
    }
    if (data.containsKey('remaining_count')) {
      context.handle(
        _remainingCountMeta,
        remainingCount.isAcceptableOrUnknown(
          data['remaining_count']!,
          _remainingCountMeta,
        ),
      );
    }
    if (data.containsKey('photo_paths')) {
      context.handle(
        _photoPathsMeta,
        photoPaths.isAcceptableOrUnknown(data['photo_paths']!, _photoPathsMeta),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('phases')) {
      context.handle(
        _phasesMeta,
        phases.isAcceptableOrUnknown(data['phases']!, _phasesMeta),
      );
    }
    if (data.containsKey('stock_percent')) {
      context.handle(
        _stockPercentMeta,
        stockPercent.isAcceptableOrUnknown(
          data['stock_percent']!,
          _stockPercentMeta,
        ),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      )!,
      doseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dose_amount'],
      )!,
      doseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_unit'],
      )!,
      foodRelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_relation'],
      )!,
      repeatType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_type'],
      )!,
      repeatConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_config'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      totalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_count'],
      )!,
      remainingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remaining_count'],
      )!,
      photoPaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_paths'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      phases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phases'],
      ),
      stockPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_percent'],
      ),
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  final int id;
  final int memberId;
  final String name;
  final String form;
  final double doseAmount;
  final String doseUnit;
  final String foodRelation;
  final String repeatType;
  final String repeatConfig;
  final DateTime startDate;
  final DateTime? endDate;
  final int totalCount;
  final int remainingCount;
  final String photoPaths;
  final String? instructions;
  final String? phases;
  final int? stockPercent;
  final DateTime? openedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? syncUuid;
  final String? color;
  const Medication({
    required this.id,
    required this.memberId,
    required this.name,
    required this.form,
    required this.doseAmount,
    required this.doseUnit,
    required this.foodRelation,
    required this.repeatType,
    required this.repeatConfig,
    required this.startDate,
    this.endDate,
    required this.totalCount,
    required this.remainingCount,
    required this.photoPaths,
    this.instructions,
    this.phases,
    this.stockPercent,
    this.openedAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.syncUuid,
    this.color,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['name'] = Variable<String>(name);
    map['form'] = Variable<String>(form);
    map['dose_amount'] = Variable<double>(doseAmount);
    map['dose_unit'] = Variable<String>(doseUnit);
    map['food_relation'] = Variable<String>(foodRelation);
    map['repeat_type'] = Variable<String>(repeatType);
    map['repeat_config'] = Variable<String>(repeatConfig);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['total_count'] = Variable<int>(totalCount);
    map['remaining_count'] = Variable<int>(remainingCount);
    map['photo_paths'] = Variable<String>(photoPaths);
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    if (!nullToAbsent || phases != null) {
      map['phases'] = Variable<String>(phases);
    }
    if (!nullToAbsent || stockPercent != null) {
      map['stock_percent'] = Variable<int>(stockPercent);
    }
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      form: Value(form),
      doseAmount: Value(doseAmount),
      doseUnit: Value(doseUnit),
      foodRelation: Value(foodRelation),
      repeatType: Value(repeatType),
      repeatConfig: Value(repeatConfig),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      totalCount: Value(totalCount),
      remainingCount: Value(remainingCount),
      photoPaths: Value(photoPaths),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      phases: phases == null && nullToAbsent
          ? const Value.absent()
          : Value(phases),
      stockPercent: stockPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(stockPercent),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      name: serializer.fromJson<String>(json['name']),
      form: serializer.fromJson<String>(json['form']),
      doseAmount: serializer.fromJson<double>(json['doseAmount']),
      doseUnit: serializer.fromJson<String>(json['doseUnit']),
      foodRelation: serializer.fromJson<String>(json['foodRelation']),
      repeatType: serializer.fromJson<String>(json['repeatType']),
      repeatConfig: serializer.fromJson<String>(json['repeatConfig']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      totalCount: serializer.fromJson<int>(json['totalCount']),
      remainingCount: serializer.fromJson<int>(json['remainingCount']),
      photoPaths: serializer.fromJson<String>(json['photoPaths']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      phases: serializer.fromJson<String?>(json['phases']),
      stockPercent: serializer.fromJson<int?>(json['stockPercent']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'name': serializer.toJson<String>(name),
      'form': serializer.toJson<String>(form),
      'doseAmount': serializer.toJson<double>(doseAmount),
      'doseUnit': serializer.toJson<String>(doseUnit),
      'foodRelation': serializer.toJson<String>(foodRelation),
      'repeatType': serializer.toJson<String>(repeatType),
      'repeatConfig': serializer.toJson<String>(repeatConfig),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'totalCount': serializer.toJson<int>(totalCount),
      'remainingCount': serializer.toJson<int>(remainingCount),
      'photoPaths': serializer.toJson<String>(photoPaths),
      'instructions': serializer.toJson<String?>(instructions),
      'phases': serializer.toJson<String?>(phases),
      'stockPercent': serializer.toJson<int?>(stockPercent),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
      'color': serializer.toJson<String?>(color),
    };
  }

  Medication copyWith({
    int? id,
    int? memberId,
    String? name,
    String? form,
    double? doseAmount,
    String? doseUnit,
    String? foodRelation,
    String? repeatType,
    String? repeatConfig,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    int? totalCount,
    int? remainingCount,
    String? photoPaths,
    Value<String?> instructions = const Value.absent(),
    Value<String?> phases = const Value.absent(),
    Value<int?> stockPercent = const Value.absent(),
    Value<DateTime?> openedAt = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
    Value<String?> color = const Value.absent(),
  }) => Medication(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    form: form ?? this.form,
    doseAmount: doseAmount ?? this.doseAmount,
    doseUnit: doseUnit ?? this.doseUnit,
    foodRelation: foodRelation ?? this.foodRelation,
    repeatType: repeatType ?? this.repeatType,
    repeatConfig: repeatConfig ?? this.repeatConfig,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    totalCount: totalCount ?? this.totalCount,
    remainingCount: remainingCount ?? this.remainingCount,
    photoPaths: photoPaths ?? this.photoPaths,
    instructions: instructions.present ? instructions.value : this.instructions,
    phases: phases.present ? phases.value : this.phases,
    stockPercent: stockPercent.present ? stockPercent.value : this.stockPercent,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
    color: color.present ? color.value : this.color,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      form: data.form.present ? data.form.value : this.form,
      doseAmount: data.doseAmount.present
          ? data.doseAmount.value
          : this.doseAmount,
      doseUnit: data.doseUnit.present ? data.doseUnit.value : this.doseUnit,
      foodRelation: data.foodRelation.present
          ? data.foodRelation.value
          : this.foodRelation,
      repeatType: data.repeatType.present
          ? data.repeatType.value
          : this.repeatType,
      repeatConfig: data.repeatConfig.present
          ? data.repeatConfig.value
          : this.repeatConfig,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      totalCount: data.totalCount.present
          ? data.totalCount.value
          : this.totalCount,
      remainingCount: data.remainingCount.present
          ? data.remainingCount.value
          : this.remainingCount,
      photoPaths: data.photoPaths.present
          ? data.photoPaths.value
          : this.photoPaths,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      phases: data.phases.present ? data.phases.value : this.phases,
      stockPercent: data.stockPercent.present
          ? data.stockPercent.value
          : this.stockPercent,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('form: $form, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('foodRelation: $foodRelation, ')
          ..write('repeatType: $repeatType, ')
          ..write('repeatConfig: $repeatConfig, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('totalCount: $totalCount, ')
          ..write('remainingCount: $remainingCount, ')
          ..write('photoPaths: $photoPaths, ')
          ..write('instructions: $instructions, ')
          ..write('phases: $phases, ')
          ..write('stockPercent: $stockPercent, ')
          ..write('openedAt: $openedAt, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    memberId,
    name,
    form,
    doseAmount,
    doseUnit,
    foodRelation,
    repeatType,
    repeatConfig,
    startDate,
    endDate,
    totalCount,
    remainingCount,
    photoPaths,
    instructions,
    phases,
    stockPercent,
    openedAt,
    isActive,
    createdAt,
    updatedAt,
    syncUuid,
    color,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.form == this.form &&
          other.doseAmount == this.doseAmount &&
          other.doseUnit == this.doseUnit &&
          other.foodRelation == this.foodRelation &&
          other.repeatType == this.repeatType &&
          other.repeatConfig == this.repeatConfig &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.totalCount == this.totalCount &&
          other.remainingCount == this.remainingCount &&
          other.photoPaths == this.photoPaths &&
          other.instructions == this.instructions &&
          other.phases == this.phases &&
          other.stockPercent == this.stockPercent &&
          other.openedAt == this.openedAt &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid &&
          other.color == this.color);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> name;
  final Value<String> form;
  final Value<double> doseAmount;
  final Value<String> doseUnit;
  final Value<String> foodRelation;
  final Value<String> repeatType;
  final Value<String> repeatConfig;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int> totalCount;
  final Value<int> remainingCount;
  final Value<String> photoPaths;
  final Value<String?> instructions;
  final Value<String?> phases;
  final Value<int?> stockPercent;
  final Value<DateTime?> openedAt;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  final Value<String?> color;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.form = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.foodRelation = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.repeatConfig = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.remainingCount = const Value.absent(),
    this.photoPaths = const Value.absent(),
    this.instructions = const Value.absent(),
    this.phases = const Value.absent(),
    this.stockPercent = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
    this.color = const Value.absent(),
  });
  MedicationsCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required String name,
    this.form = const Value.absent(),
    required double doseAmount,
    this.doseUnit = const Value.absent(),
    this.foodRelation = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.repeatConfig = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.remainingCount = const Value.absent(),
    this.photoPaths = const Value.absent(),
    this.instructions = const Value.absent(),
    this.phases = const Value.absent(),
    this.stockPercent = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
    this.color = const Value.absent(),
  }) : memberId = Value(memberId),
       name = Value(name),
       doseAmount = Value(doseAmount),
       startDate = Value(startDate);
  static Insertable<Medication> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? name,
    Expression<String>? form,
    Expression<double>? doseAmount,
    Expression<String>? doseUnit,
    Expression<String>? foodRelation,
    Expression<String>? repeatType,
    Expression<String>? repeatConfig,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? totalCount,
    Expression<int>? remainingCount,
    Expression<String>? photoPaths,
    Expression<String>? instructions,
    Expression<String>? phases,
    Expression<int>? stockPercent,
    Expression<DateTime>? openedAt,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
    Expression<String>? color,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (form != null) 'form': form,
      if (doseAmount != null) 'dose_amount': doseAmount,
      if (doseUnit != null) 'dose_unit': doseUnit,
      if (foodRelation != null) 'food_relation': foodRelation,
      if (repeatType != null) 'repeat_type': repeatType,
      if (repeatConfig != null) 'repeat_config': repeatConfig,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (totalCount != null) 'total_count': totalCount,
      if (remainingCount != null) 'remaining_count': remainingCount,
      if (photoPaths != null) 'photo_paths': photoPaths,
      if (instructions != null) 'instructions': instructions,
      if (phases != null) 'phases': phases,
      if (stockPercent != null) 'stock_percent': stockPercent,
      if (openedAt != null) 'opened_at': openedAt,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
      if (color != null) 'color': color,
    });
  }

  MedicationsCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? name,
    Value<String>? form,
    Value<double>? doseAmount,
    Value<String>? doseUnit,
    Value<String>? foodRelation,
    Value<String>? repeatType,
    Value<String>? repeatConfig,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<int>? totalCount,
    Value<int>? remainingCount,
    Value<String>? photoPaths,
    Value<String?>? instructions,
    Value<String?>? phases,
    Value<int?>? stockPercent,
    Value<DateTime?>? openedAt,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
    Value<String?>? color,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      form: form ?? this.form,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      foodRelation: foodRelation ?? this.foodRelation,
      repeatType: repeatType ?? this.repeatType,
      repeatConfig: repeatConfig ?? this.repeatConfig,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalCount: totalCount ?? this.totalCount,
      remainingCount: remainingCount ?? this.remainingCount,
      photoPaths: photoPaths ?? this.photoPaths,
      instructions: instructions ?? this.instructions,
      phases: phases ?? this.phases,
      stockPercent: stockPercent ?? this.stockPercent,
      openedAt: openedAt ?? this.openedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (doseAmount.present) {
      map['dose_amount'] = Variable<double>(doseAmount.value);
    }
    if (doseUnit.present) {
      map['dose_unit'] = Variable<String>(doseUnit.value);
    }
    if (foodRelation.present) {
      map['food_relation'] = Variable<String>(foodRelation.value);
    }
    if (repeatType.present) {
      map['repeat_type'] = Variable<String>(repeatType.value);
    }
    if (repeatConfig.present) {
      map['repeat_config'] = Variable<String>(repeatConfig.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    if (remainingCount.present) {
      map['remaining_count'] = Variable<int>(remainingCount.value);
    }
    if (photoPaths.present) {
      map['photo_paths'] = Variable<String>(photoPaths.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (phases.present) {
      map['phases'] = Variable<String>(phases.value);
    }
    if (stockPercent.present) {
      map['stock_percent'] = Variable<int>(stockPercent.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('form: $form, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('foodRelation: $foodRelation, ')
          ..write('repeatType: $repeatType, ')
          ..write('repeatConfig: $repeatConfig, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('totalCount: $totalCount, ')
          ..write('remainingCount: $remainingCount, ')
          ..write('photoPaths: $photoPaths, ')
          ..write('instructions: $instructions, ')
          ..write('phases: $phases, ')
          ..write('stockPercent: $stockPercent, ')
          ..write('openedAt: $openedAt, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, Schedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    timeOfDay,
    sortOrder,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<Schedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Schedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Schedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }
}

class Schedule extends DataClass implements Insertable<Schedule> {
  final int id;
  final int medicationId;
  final String timeOfDay;
  final int sortOrder;
  final DateTime updatedAt;
  final String? syncUuid;
  const Schedule({
    required this.id,
    required this.medicationId,
    required this.timeOfDay,
    required this.sortOrder,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<int>(medicationId);
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      timeOfDay: Value(timeOfDay),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory Schedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Schedule(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<int>(medicationId),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  Schedule copyWith({
    int? id,
    int? medicationId,
    String? timeOfDay,
    int? sortOrder,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => Schedule(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  Schedule copyWithCompanion(SchedulesCompanion data) {
    return Schedule(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Schedule(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, medicationId, timeOfDay, sortOrder, updatedAt, syncUuid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Schedule &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.timeOfDay == this.timeOfDay &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class SchedulesCompanion extends UpdateCompanion<Schedule> {
  final Value<int> id;
  final Value<int> medicationId;
  final Value<String> timeOfDay;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const SchedulesCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  SchedulesCompanion.insert({
    this.id = const Value.absent(),
    required int medicationId,
    required String timeOfDay,
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : medicationId = Value(medicationId),
       timeOfDay = Value(timeOfDay);
  static Insertable<Schedule> custom({
    Expression<int>? id,
    Expression<int>? medicationId,
    Expression<String>? timeOfDay,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  SchedulesCompanion copyWith({
    Value<int>? id,
    Value<int>? medicationId,
    Value<String>? timeOfDay,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return SchedulesCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $IntakesTable extends Intakes with TableInfo<$IntakesTable, Intake> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<int> scheduleId = GeneratedColumn<int>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduleId,
    medicationId,
    memberId,
    scheduledAt,
    status,
    takenAt,
    snoozedUntil,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Intake> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Intake map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Intake(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      ),
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}snoozed_until'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $IntakesTable createAlias(String alias) {
    return $IntakesTable(attachedDatabase, alias);
  }
}

class Intake extends DataClass implements Insertable<Intake> {
  final int id;
  final int scheduleId;
  final int medicationId;
  final int memberId;
  final DateTime scheduledAt;
  final String status;
  final DateTime? takenAt;
  final DateTime? snoozedUntil;
  final DateTime updatedAt;
  final String? syncUuid;
  const Intake({
    required this.id,
    required this.scheduleId,
    required this.medicationId,
    required this.memberId,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
    this.snoozedUntil,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['schedule_id'] = Variable<int>(scheduleId);
    map['medication_id'] = Variable<int>(medicationId);
    map['member_id'] = Variable<int>(memberId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<DateTime>(takenAt);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  IntakesCompanion toCompanion(bool nullToAbsent) {
    return IntakesCompanion(
      id: Value(id),
      scheduleId: Value(scheduleId),
      medicationId: Value(medicationId),
      memberId: Value(memberId),
      scheduledAt: Value(scheduledAt),
      status: Value(status),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory Intake.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Intake(
      id: serializer.fromJson<int>(json['id']),
      scheduleId: serializer.fromJson<int>(json['scheduleId']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      memberId: serializer.fromJson<int>(json['memberId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      status: serializer.fromJson<String>(json['status']),
      takenAt: serializer.fromJson<DateTime?>(json['takenAt']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scheduleId': serializer.toJson<int>(scheduleId),
      'medicationId': serializer.toJson<int>(medicationId),
      'memberId': serializer.toJson<int>(memberId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'status': serializer.toJson<String>(status),
      'takenAt': serializer.toJson<DateTime?>(takenAt),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  Intake copyWith({
    int? id,
    int? scheduleId,
    int? medicationId,
    int? memberId,
    DateTime? scheduledAt,
    String? status,
    Value<DateTime?> takenAt = const Value.absent(),
    Value<DateTime?> snoozedUntil = const Value.absent(),
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => Intake(
    id: id ?? this.id,
    scheduleId: scheduleId ?? this.scheduleId,
    medicationId: medicationId ?? this.medicationId,
    memberId: memberId ?? this.memberId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  Intake copyWithCompanion(IntakesCompanion data) {
    return Intake(
      id: data.id.present ? data.id.value : this.id,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      status: data.status.present ? data.status.value : this.status,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Intake(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('medicationId: $medicationId, ')
          ..write('memberId: $memberId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('takenAt: $takenAt, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scheduleId,
    medicationId,
    memberId,
    scheduledAt,
    status,
    takenAt,
    snoozedUntil,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Intake &&
          other.id == this.id &&
          other.scheduleId == this.scheduleId &&
          other.medicationId == this.medicationId &&
          other.memberId == this.memberId &&
          other.scheduledAt == this.scheduledAt &&
          other.status == this.status &&
          other.takenAt == this.takenAt &&
          other.snoozedUntil == this.snoozedUntil &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class IntakesCompanion extends UpdateCompanion<Intake> {
  final Value<int> id;
  final Value<int> scheduleId;
  final Value<int> medicationId;
  final Value<int> memberId;
  final Value<DateTime> scheduledAt;
  final Value<String> status;
  final Value<DateTime?> takenAt;
  final Value<DateTime?> snoozedUntil;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const IntakesCompanion({
    this.id = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  IntakesCompanion.insert({
    this.id = const Value.absent(),
    required int scheduleId,
    required int medicationId,
    required int memberId,
    required DateTime scheduledAt,
    this.status = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       medicationId = Value(medicationId),
       memberId = Value(memberId),
       scheduledAt = Value(scheduledAt);
  static Insertable<Intake> custom({
    Expression<int>? id,
    Expression<int>? scheduleId,
    Expression<int>? medicationId,
    Expression<int>? memberId,
    Expression<DateTime>? scheduledAt,
    Expression<String>? status,
    Expression<DateTime>? takenAt,
    Expression<DateTime>? snoozedUntil,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (medicationId != null) 'medication_id': medicationId,
      if (memberId != null) 'member_id': memberId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (status != null) 'status': status,
      if (takenAt != null) 'taken_at': takenAt,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  IntakesCompanion copyWith({
    Value<int>? id,
    Value<int>? scheduleId,
    Value<int>? medicationId,
    Value<int>? memberId,
    Value<DateTime>? scheduledAt,
    Value<String>? status,
    Value<DateTime?>? takenAt,
    Value<DateTime?>? snoozedUntil,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return IntakesCompanion(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      medicationId: medicationId ?? this.medicationId,
      memberId: memberId ?? this.memberId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<int>(scheduleId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakesCompanion(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('medicationId: $medicationId, ')
          ..write('memberId: $memberId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('takenAt: $takenAt, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $SymptomsTable extends Symptoms with TableInfo<$SymptomsTable, Symptom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymptomsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameKeyMeta = const VerificationMeta(
    'nameKey',
  );
  @override
  late final GeneratedColumn<String> nameKey = GeneratedColumn<String>(
    'name_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('common'),
  );
  static const VerificationMeta _isAllergyRiskMeta = const VerificationMeta(
    'isAllergyRisk',
  );
  @override
  late final GeneratedColumn<bool> isAllergyRisk = GeneratedColumn<bool>(
    'is_allergy_risk',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_allergy_risk" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isTrackedMeta = const VerificationMeta(
    'isTracked',
  );
  @override
  late final GeneratedColumn<bool> isTracked = GeneratedColumn<bool>(
    'is_tracked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_tracked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    nameKey,
    frequency,
    isAllergyRisk,
    isTracked,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symptoms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Symptom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_nameKeyMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('is_allergy_risk')) {
      context.handle(
        _isAllergyRiskMeta,
        isAllergyRisk.isAcceptableOrUnknown(
          data['is_allergy_risk']!,
          _isAllergyRiskMeta,
        ),
      );
    }
    if (data.containsKey('is_tracked')) {
      context.handle(
        _isTrackedMeta,
        isTracked.isAcceptableOrUnknown(data['is_tracked']!, _isTrackedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Symptom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Symptom(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      isAllergyRisk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_allergy_risk'],
      )!,
      isTracked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_tracked'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $SymptomsTable createAlias(String alias) {
    return $SymptomsTable(attachedDatabase, alias);
  }
}

class Symptom extends DataClass implements Insertable<Symptom> {
  final int id;
  final int medicationId;
  final String nameKey;
  final String frequency;
  final bool isAllergyRisk;
  final bool isTracked;
  final DateTime updatedAt;
  final String? syncUuid;
  const Symptom({
    required this.id,
    required this.medicationId,
    required this.nameKey,
    required this.frequency,
    required this.isAllergyRisk,
    required this.isTracked,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<int>(medicationId);
    map['name_key'] = Variable<String>(nameKey);
    map['frequency'] = Variable<String>(frequency);
    map['is_allergy_risk'] = Variable<bool>(isAllergyRisk);
    map['is_tracked'] = Variable<bool>(isTracked);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  SymptomsCompanion toCompanion(bool nullToAbsent) {
    return SymptomsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      nameKey: Value(nameKey),
      frequency: Value(frequency),
      isAllergyRisk: Value(isAllergyRisk),
      isTracked: Value(isTracked),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory Symptom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Symptom(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      nameKey: serializer.fromJson<String>(json['nameKey']),
      frequency: serializer.fromJson<String>(json['frequency']),
      isAllergyRisk: serializer.fromJson<bool>(json['isAllergyRisk']),
      isTracked: serializer.fromJson<bool>(json['isTracked']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<int>(medicationId),
      'nameKey': serializer.toJson<String>(nameKey),
      'frequency': serializer.toJson<String>(frequency),
      'isAllergyRisk': serializer.toJson<bool>(isAllergyRisk),
      'isTracked': serializer.toJson<bool>(isTracked),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  Symptom copyWith({
    int? id,
    int? medicationId,
    String? nameKey,
    String? frequency,
    bool? isAllergyRisk,
    bool? isTracked,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => Symptom(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    nameKey: nameKey ?? this.nameKey,
    frequency: frequency ?? this.frequency,
    isAllergyRisk: isAllergyRisk ?? this.isAllergyRisk,
    isTracked: isTracked ?? this.isTracked,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  Symptom copyWithCompanion(SymptomsCompanion data) {
    return Symptom(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      isAllergyRisk: data.isAllergyRisk.present
          ? data.isAllergyRisk.value
          : this.isAllergyRisk,
      isTracked: data.isTracked.present ? data.isTracked.value : this.isTracked,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Symptom(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('nameKey: $nameKey, ')
          ..write('frequency: $frequency, ')
          ..write('isAllergyRisk: $isAllergyRisk, ')
          ..write('isTracked: $isTracked, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    nameKey,
    frequency,
    isAllergyRisk,
    isTracked,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Symptom &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.nameKey == this.nameKey &&
          other.frequency == this.frequency &&
          other.isAllergyRisk == this.isAllergyRisk &&
          other.isTracked == this.isTracked &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class SymptomsCompanion extends UpdateCompanion<Symptom> {
  final Value<int> id;
  final Value<int> medicationId;
  final Value<String> nameKey;
  final Value<String> frequency;
  final Value<bool> isAllergyRisk;
  final Value<bool> isTracked;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const SymptomsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.nameKey = const Value.absent(),
    this.frequency = const Value.absent(),
    this.isAllergyRisk = const Value.absent(),
    this.isTracked = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  SymptomsCompanion.insert({
    this.id = const Value.absent(),
    required int medicationId,
    required String nameKey,
    this.frequency = const Value.absent(),
    this.isAllergyRisk = const Value.absent(),
    this.isTracked = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : medicationId = Value(medicationId),
       nameKey = Value(nameKey);
  static Insertable<Symptom> custom({
    Expression<int>? id,
    Expression<int>? medicationId,
    Expression<String>? nameKey,
    Expression<String>? frequency,
    Expression<bool>? isAllergyRisk,
    Expression<bool>? isTracked,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (nameKey != null) 'name_key': nameKey,
      if (frequency != null) 'frequency': frequency,
      if (isAllergyRisk != null) 'is_allergy_risk': isAllergyRisk,
      if (isTracked != null) 'is_tracked': isTracked,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  SymptomsCompanion copyWith({
    Value<int>? id,
    Value<int>? medicationId,
    Value<String>? nameKey,
    Value<String>? frequency,
    Value<bool>? isAllergyRisk,
    Value<bool>? isTracked,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return SymptomsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      nameKey: nameKey ?? this.nameKey,
      frequency: frequency ?? this.frequency,
      isAllergyRisk: isAllergyRisk ?? this.isAllergyRisk,
      isTracked: isTracked ?? this.isTracked,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (nameKey.present) {
      map['name_key'] = Variable<String>(nameKey.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (isAllergyRisk.present) {
      map['is_allergy_risk'] = Variable<bool>(isAllergyRisk.value);
    }
    if (isTracked.present) {
      map['is_tracked'] = Variable<bool>(isTracked.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymptomsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('nameKey: $nameKey, ')
          ..write('frequency: $frequency, ')
          ..write('isAllergyRisk: $isAllergyRisk, ')
          ..write('isTracked: $isTracked, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $WellbeingLogsTable extends WellbeingLogs
    with TableInfo<$WellbeingLogsTable, WellbeingLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WellbeingLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symptomsJsonMeta = const VerificationMeta(
    'symptomsJson',
  );
  @override
  late final GeneratedColumn<String> symptomsJson = GeneratedColumn<String>(
    'symptoms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voiceNotePathMeta = const VerificationMeta(
    'voiceNotePath',
  );
  @override
  late final GeneratedColumn<String> voiceNotePath = GeneratedColumn<String>(
    'voice_note_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    mood,
    symptomsJson,
    comment,
    voiceNotePath,
    skipped,
    loggedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wellbeing_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WellbeingLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    } else if (isInserting) {
      context.missing(_moodMeta);
    }
    if (data.containsKey('symptoms_json')) {
      context.handle(
        _symptomsJsonMeta,
        symptomsJson.isAcceptableOrUnknown(
          data['symptoms_json']!,
          _symptomsJsonMeta,
        ),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('voice_note_path')) {
      context.handle(
        _voiceNotePathMeta,
        voiceNotePath.isAcceptableOrUnknown(
          data['voice_note_path']!,
          _voiceNotePathMeta,
        ),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WellbeingLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WellbeingLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      )!,
      symptomsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptoms_json'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      voiceNotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_note_path'],
      ),
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WellbeingLogsTable createAlias(String alias) {
    return $WellbeingLogsTable(attachedDatabase, alias);
  }
}

class WellbeingLog extends DataClass implements Insertable<WellbeingLog> {
  final int id;
  final int memberId;
  final int mood;
  final String symptomsJson;
  final String? comment;
  final String? voiceNotePath;
  final bool skipped;
  final DateTime loggedAt;
  final DateTime updatedAt;
  const WellbeingLog({
    required this.id,
    required this.memberId,
    required this.mood,
    required this.symptomsJson,
    this.comment,
    this.voiceNotePath,
    required this.skipped,
    required this.loggedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['mood'] = Variable<int>(mood);
    map['symptoms_json'] = Variable<String>(symptomsJson);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || voiceNotePath != null) {
      map['voice_note_path'] = Variable<String>(voiceNotePath);
    }
    map['skipped'] = Variable<bool>(skipped);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WellbeingLogsCompanion toCompanion(bool nullToAbsent) {
    return WellbeingLogsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      mood: Value(mood),
      symptomsJson: Value(symptomsJson),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      voiceNotePath: voiceNotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceNotePath),
      skipped: Value(skipped),
      loggedAt: Value(loggedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WellbeingLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WellbeingLog(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      mood: serializer.fromJson<int>(json['mood']),
      symptomsJson: serializer.fromJson<String>(json['symptomsJson']),
      comment: serializer.fromJson<String?>(json['comment']),
      voiceNotePath: serializer.fromJson<String?>(json['voiceNotePath']),
      skipped: serializer.fromJson<bool>(json['skipped']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'mood': serializer.toJson<int>(mood),
      'symptomsJson': serializer.toJson<String>(symptomsJson),
      'comment': serializer.toJson<String?>(comment),
      'voiceNotePath': serializer.toJson<String?>(voiceNotePath),
      'skipped': serializer.toJson<bool>(skipped),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WellbeingLog copyWith({
    int? id,
    int? memberId,
    int? mood,
    String? symptomsJson,
    Value<String?> comment = const Value.absent(),
    Value<String?> voiceNotePath = const Value.absent(),
    bool? skipped,
    DateTime? loggedAt,
    DateTime? updatedAt,
  }) => WellbeingLog(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    mood: mood ?? this.mood,
    symptomsJson: symptomsJson ?? this.symptomsJson,
    comment: comment.present ? comment.value : this.comment,
    voiceNotePath: voiceNotePath.present
        ? voiceNotePath.value
        : this.voiceNotePath,
    skipped: skipped ?? this.skipped,
    loggedAt: loggedAt ?? this.loggedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WellbeingLog copyWithCompanion(WellbeingLogsCompanion data) {
    return WellbeingLog(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      mood: data.mood.present ? data.mood.value : this.mood,
      symptomsJson: data.symptomsJson.present
          ? data.symptomsJson.value
          : this.symptomsJson,
      comment: data.comment.present ? data.comment.value : this.comment,
      voiceNotePath: data.voiceNotePath.present
          ? data.voiceNotePath.value
          : this.voiceNotePath,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WellbeingLog(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('mood: $mood, ')
          ..write('symptomsJson: $symptomsJson, ')
          ..write('comment: $comment, ')
          ..write('voiceNotePath: $voiceNotePath, ')
          ..write('skipped: $skipped, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    mood,
    symptomsJson,
    comment,
    voiceNotePath,
    skipped,
    loggedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WellbeingLog &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.mood == this.mood &&
          other.symptomsJson == this.symptomsJson &&
          other.comment == this.comment &&
          other.voiceNotePath == this.voiceNotePath &&
          other.skipped == this.skipped &&
          other.loggedAt == this.loggedAt &&
          other.updatedAt == this.updatedAt);
}

class WellbeingLogsCompanion extends UpdateCompanion<WellbeingLog> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<int> mood;
  final Value<String> symptomsJson;
  final Value<String?> comment;
  final Value<String?> voiceNotePath;
  final Value<bool> skipped;
  final Value<DateTime> loggedAt;
  final Value<DateTime> updatedAt;
  const WellbeingLogsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.mood = const Value.absent(),
    this.symptomsJson = const Value.absent(),
    this.comment = const Value.absent(),
    this.voiceNotePath = const Value.absent(),
    this.skipped = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WellbeingLogsCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required int mood,
    this.symptomsJson = const Value.absent(),
    this.comment = const Value.absent(),
    this.voiceNotePath = const Value.absent(),
    this.skipped = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : memberId = Value(memberId),
       mood = Value(mood);
  static Insertable<WellbeingLog> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<int>? mood,
    Expression<String>? symptomsJson,
    Expression<String>? comment,
    Expression<String>? voiceNotePath,
    Expression<bool>? skipped,
    Expression<DateTime>? loggedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (mood != null) 'mood': mood,
      if (symptomsJson != null) 'symptoms_json': symptomsJson,
      if (comment != null) 'comment': comment,
      if (voiceNotePath != null) 'voice_note_path': voiceNotePath,
      if (skipped != null) 'skipped': skipped,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WellbeingLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<int>? mood,
    Value<String>? symptomsJson,
    Value<String?>? comment,
    Value<String?>? voiceNotePath,
    Value<bool>? skipped,
    Value<DateTime>? loggedAt,
    Value<DateTime>? updatedAt,
  }) {
    return WellbeingLogsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      mood: mood ?? this.mood,
      symptomsJson: symptomsJson ?? this.symptomsJson,
      comment: comment ?? this.comment,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      skipped: skipped ?? this.skipped,
      loggedAt: loggedAt ?? this.loggedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (symptomsJson.present) {
      map['symptoms_json'] = Variable<String>(symptomsJson.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (voiceNotePath.present) {
      map['voice_note_path'] = Variable<String>(voiceNotePath.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WellbeingLogsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('mood: $mood, ')
          ..write('symptomsJson: $symptomsJson, ')
          ..write('comment: $comment, ')
          ..write('voiceNotePath: $voiceNotePath, ')
          ..write('skipped: $skipped, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WellbeingSchedulesTable extends WellbeingSchedules
    with TableInfo<$WellbeingSchedulesTable, WellbeingSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WellbeingSchedulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timesPerDayMeta = const VerificationMeta(
    'timesPerDay',
  );
  @override
  late final GeneratedColumn<int> timesPerDay = GeneratedColumn<int>(
    'times_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _timesMeta = const VerificationMeta('times');
  @override
  late final GeneratedColumn<String> times = GeneratedColumn<String>(
    'times',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('["08:00","20:00"]'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    timesPerDay,
    times,
    isActive,
    color,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wellbeing_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<WellbeingSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('times_per_day')) {
      context.handle(
        _timesPerDayMeta,
        timesPerDay.isAcceptableOrUnknown(
          data['times_per_day']!,
          _timesPerDayMeta,
        ),
      );
    }
    if (data.containsKey('times')) {
      context.handle(
        _timesMeta,
        times.isAcceptableOrUnknown(data['times']!, _timesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WellbeingSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WellbeingSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      timesPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_per_day'],
      )!,
      times: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WellbeingSchedulesTable createAlias(String alias) {
    return $WellbeingSchedulesTable(attachedDatabase, alias);
  }
}

class WellbeingSchedule extends DataClass
    implements Insertable<WellbeingSchedule> {
  final int id;
  final int memberId;
  final int timesPerDay;
  final String times;
  final bool isActive;
  final String? color;
  final DateTime updatedAt;
  const WellbeingSchedule({
    required this.id,
    required this.memberId,
    required this.timesPerDay,
    required this.times,
    required this.isActive,
    this.color,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['times_per_day'] = Variable<int>(timesPerDay);
    map['times'] = Variable<String>(times);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WellbeingSchedulesCompanion toCompanion(bool nullToAbsent) {
    return WellbeingSchedulesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      timesPerDay: Value(timesPerDay),
      times: Value(times),
      isActive: Value(isActive),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      updatedAt: Value(updatedAt),
    );
  }

  factory WellbeingSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WellbeingSchedule(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      timesPerDay: serializer.fromJson<int>(json['timesPerDay']),
      times: serializer.fromJson<String>(json['times']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      color: serializer.fromJson<String?>(json['color']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'timesPerDay': serializer.toJson<int>(timesPerDay),
      'times': serializer.toJson<String>(times),
      'isActive': serializer.toJson<bool>(isActive),
      'color': serializer.toJson<String?>(color),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WellbeingSchedule copyWith({
    int? id,
    int? memberId,
    int? timesPerDay,
    String? times,
    bool? isActive,
    Value<String?> color = const Value.absent(),
    DateTime? updatedAt,
  }) => WellbeingSchedule(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    timesPerDay: timesPerDay ?? this.timesPerDay,
    times: times ?? this.times,
    isActive: isActive ?? this.isActive,
    color: color.present ? color.value : this.color,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WellbeingSchedule copyWithCompanion(WellbeingSchedulesCompanion data) {
    return WellbeingSchedule(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      timesPerDay: data.timesPerDay.present
          ? data.timesPerDay.value
          : this.timesPerDay,
      times: data.times.present ? data.times.value : this.times,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      color: data.color.present ? data.color.value : this.color,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WellbeingSchedule(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('times: $times, ')
          ..write('isActive: $isActive, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, memberId, timesPerDay, times, isActive, color, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WellbeingSchedule &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.timesPerDay == this.timesPerDay &&
          other.times == this.times &&
          other.isActive == this.isActive &&
          other.color == this.color &&
          other.updatedAt == this.updatedAt);
}

class WellbeingSchedulesCompanion extends UpdateCompanion<WellbeingSchedule> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<int> timesPerDay;
  final Value<String> times;
  final Value<bool> isActive;
  final Value<String?> color;
  final Value<DateTime> updatedAt;
  const WellbeingSchedulesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.timesPerDay = const Value.absent(),
    this.times = const Value.absent(),
    this.isActive = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WellbeingSchedulesCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    this.timesPerDay = const Value.absent(),
    this.times = const Value.absent(),
    this.isActive = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : memberId = Value(memberId);
  static Insertable<WellbeingSchedule> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<int>? timesPerDay,
    Expression<String>? times,
    Expression<bool>? isActive,
    Expression<String>? color,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (timesPerDay != null) 'times_per_day': timesPerDay,
      if (times != null) 'times': times,
      if (isActive != null) 'is_active': isActive,
      if (color != null) 'color': color,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WellbeingSchedulesCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<int>? timesPerDay,
    Value<String>? times,
    Value<bool>? isActive,
    Value<String?>? color,
    Value<DateTime>? updatedAt,
  }) {
    return WellbeingSchedulesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      times: times ?? this.times,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (timesPerDay.present) {
      map['times_per_day'] = Variable<int>(timesPerDay.value);
    }
    if (times.present) {
      map['times'] = Variable<String>(times.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WellbeingSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('times: $times, ')
          ..write('isActive: $isActive, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, Activity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('walk'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _repeatDaysMeta = const VerificationMeta(
    'repeatDays',
  );
  @override
  late final GeneratedColumn<String> repeatDays = GeneratedColumn<String>(
    'repeat_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[1,2,3,4,5]'),
  );
  static const VerificationMeta _reminderBeforeMinMeta = const VerificationMeta(
    'reminderBeforeMin',
  );
  @override
  late final GeneratedColumn<int> reminderBeforeMin = GeneratedColumn<int>(
    'reminder_before_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _youtubeUrlMeta = const VerificationMeta(
    'youtubeUrl',
  );
  @override
  late final GeneratedColumn<String> youtubeUrl = GeneratedColumn<String>(
    'youtube_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    type,
    name,
    durationMin,
    repeatDays,
    reminderBeforeMin,
    youtubeUrl,
    color,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Activity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('repeat_days')) {
      context.handle(
        _repeatDaysMeta,
        repeatDays.isAcceptableOrUnknown(data['repeat_days']!, _repeatDaysMeta),
      );
    }
    if (data.containsKey('reminder_before_min')) {
      context.handle(
        _reminderBeforeMinMeta,
        reminderBeforeMin.isAcceptableOrUnknown(
          data['reminder_before_min']!,
          _reminderBeforeMinMeta,
        ),
      );
    }
    if (data.containsKey('youtube_url')) {
      context.handle(
        _youtubeUrlMeta,
        youtubeUrl.isAcceptableOrUnknown(data['youtube_url']!, _youtubeUrlMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Activity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Activity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      repeatDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_days'],
      )!,
      reminderBeforeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_before_min'],
      )!,
      youtubeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube_url'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class Activity extends DataClass implements Insertable<Activity> {
  final int id;
  final int memberId;
  final String type;
  final String name;
  final int durationMin;
  final String repeatDays;
  final int reminderBeforeMin;
  final String? youtubeUrl;
  final String? color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Activity({
    required this.id,
    required this.memberId,
    required this.type,
    required this.name,
    required this.durationMin,
    required this.repeatDays,
    required this.reminderBeforeMin,
    this.youtubeUrl,
    this.color,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['duration_min'] = Variable<int>(durationMin);
    map['repeat_days'] = Variable<String>(repeatDays);
    map['reminder_before_min'] = Variable<int>(reminderBeforeMin);
    if (!nullToAbsent || youtubeUrl != null) {
      map['youtube_url'] = Variable<String>(youtubeUrl);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      type: Value(type),
      name: Value(name),
      durationMin: Value(durationMin),
      repeatDays: Value(repeatDays),
      reminderBeforeMin: Value(reminderBeforeMin),
      youtubeUrl: youtubeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(youtubeUrl),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Activity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Activity(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      repeatDays: serializer.fromJson<String>(json['repeatDays']),
      reminderBeforeMin: serializer.fromJson<int>(json['reminderBeforeMin']),
      youtubeUrl: serializer.fromJson<String?>(json['youtubeUrl']),
      color: serializer.fromJson<String?>(json['color']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'durationMin': serializer.toJson<int>(durationMin),
      'repeatDays': serializer.toJson<String>(repeatDays),
      'reminderBeforeMin': serializer.toJson<int>(reminderBeforeMin),
      'youtubeUrl': serializer.toJson<String?>(youtubeUrl),
      'color': serializer.toJson<String?>(color),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Activity copyWith({
    int? id,
    int? memberId,
    String? type,
    String? name,
    int? durationMin,
    String? repeatDays,
    int? reminderBeforeMin,
    Value<String?> youtubeUrl = const Value.absent(),
    Value<String?> color = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Activity(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    type: type ?? this.type,
    name: name ?? this.name,
    durationMin: durationMin ?? this.durationMin,
    repeatDays: repeatDays ?? this.repeatDays,
    reminderBeforeMin: reminderBeforeMin ?? this.reminderBeforeMin,
    youtubeUrl: youtubeUrl.present ? youtubeUrl.value : this.youtubeUrl,
    color: color.present ? color.value : this.color,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Activity copyWithCompanion(ActivitiesCompanion data) {
    return Activity(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      repeatDays: data.repeatDays.present
          ? data.repeatDays.value
          : this.repeatDays,
      reminderBeforeMin: data.reminderBeforeMin.present
          ? data.reminderBeforeMin.value
          : this.reminderBeforeMin,
      youtubeUrl: data.youtubeUrl.present
          ? data.youtubeUrl.value
          : this.youtubeUrl,
      color: data.color.present ? data.color.value : this.color,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Activity(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('durationMin: $durationMin, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('reminderBeforeMin: $reminderBeforeMin, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('color: $color, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    type,
    name,
    durationMin,
    repeatDays,
    reminderBeforeMin,
    youtubeUrl,
    color,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Activity &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.type == this.type &&
          other.name == this.name &&
          other.durationMin == this.durationMin &&
          other.repeatDays == this.repeatDays &&
          other.reminderBeforeMin == this.reminderBeforeMin &&
          other.youtubeUrl == this.youtubeUrl &&
          other.color == this.color &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ActivitiesCompanion extends UpdateCompanion<Activity> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> type;
  final Value<String> name;
  final Value<int> durationMin;
  final Value<String> repeatDays;
  final Value<int> reminderBeforeMin;
  final Value<String?> youtubeUrl;
  final Value<String?> color;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.repeatDays = const Value.absent(),
    this.reminderBeforeMin = const Value.absent(),
    this.youtubeUrl = const Value.absent(),
    this.color = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    this.type = const Value.absent(),
    required String name,
    this.durationMin = const Value.absent(),
    this.repeatDays = const Value.absent(),
    this.reminderBeforeMin = const Value.absent(),
    this.youtubeUrl = const Value.absent(),
    this.color = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : memberId = Value(memberId),
       name = Value(name);
  static Insertable<Activity> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<int>? durationMin,
    Expression<String>? repeatDays,
    Expression<int>? reminderBeforeMin,
    Expression<String>? youtubeUrl,
    Expression<String>? color,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (durationMin != null) 'duration_min': durationMin,
      if (repeatDays != null) 'repeat_days': repeatDays,
      if (reminderBeforeMin != null) 'reminder_before_min': reminderBeforeMin,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (color != null) 'color': color,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ActivitiesCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? type,
    Value<String>? name,
    Value<int>? durationMin,
    Value<String>? repeatDays,
    Value<int>? reminderBeforeMin,
    Value<String?>? youtubeUrl,
    Value<String?>? color,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      type: type ?? this.type,
      name: name ?? this.name,
      durationMin: durationMin ?? this.durationMin,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderBeforeMin: reminderBeforeMin ?? this.reminderBeforeMin,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (repeatDays.present) {
      map['repeat_days'] = Variable<String>(repeatDays.value);
    }
    if (reminderBeforeMin.present) {
      map['reminder_before_min'] = Variable<int>(reminderBeforeMin.value);
    }
    if (youtubeUrl.present) {
      map['youtube_url'] = Variable<String>(youtubeUrl.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('durationMin: $durationMin, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('reminderBeforeMin: $reminderBeforeMin, ')
          ..write('youtubeUrl: $youtubeUrl, ')
          ..write('color: $color, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivitySlotsTable extends ActivitySlots
    with TableInfo<$ActivitySlotsTable, ActivitySlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitySlotsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    timeOfDay,
    durationMin,
    sortOrder,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivitySlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivitySlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivitySlot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ActivitySlotsTable createAlias(String alias) {
    return $ActivitySlotsTable(attachedDatabase, alias);
  }
}

class ActivitySlot extends DataClass implements Insertable<ActivitySlot> {
  final int id;
  final int activityId;
  final String timeOfDay;
  final int durationMin;
  final int sortOrder;
  final DateTime updatedAt;
  const ActivitySlot({
    required this.id,
    required this.activityId,
    required this.timeOfDay,
    required this.durationMin,
    required this.sortOrder,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_id'] = Variable<int>(activityId);
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['duration_min'] = Variable<int>(durationMin);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ActivitySlotsCompanion toCompanion(bool nullToAbsent) {
    return ActivitySlotsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      timeOfDay: Value(timeOfDay),
      durationMin: Value(durationMin),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActivitySlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivitySlot(
      id: serializer.fromJson<int>(json['id']),
      activityId: serializer.fromJson<int>(json['activityId']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityId': serializer.toJson<int>(activityId),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'durationMin': serializer.toJson<int>(durationMin),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ActivitySlot copyWith({
    int? id,
    int? activityId,
    String? timeOfDay,
    int? durationMin,
    int? sortOrder,
    DateTime? updatedAt,
  }) => ActivitySlot(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    durationMin: durationMin ?? this.durationMin,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ActivitySlot copyWithCompanion(ActivitySlotsCompanion data) {
    return ActivitySlot(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySlot(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('durationMin: $durationMin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, activityId, timeOfDay, durationMin, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivitySlot &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.timeOfDay == this.timeOfDay &&
          other.durationMin == this.durationMin &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class ActivitySlotsCompanion extends UpdateCompanion<ActivitySlot> {
  final Value<int> id;
  final Value<int> activityId;
  final Value<String> timeOfDay;
  final Value<int> durationMin;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  const ActivitySlotsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ActivitySlotsCompanion.insert({
    this.id = const Value.absent(),
    required int activityId,
    required String timeOfDay,
    this.durationMin = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : activityId = Value(activityId),
       timeOfDay = Value(timeOfDay);
  static Insertable<ActivitySlot> custom({
    Expression<int>? id,
    Expression<int>? activityId,
    Expression<String>? timeOfDay,
    Expression<int>? durationMin,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (durationMin != null) 'duration_min': durationMin,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ActivitySlotsCompanion copyWith({
    Value<int>? id,
    Value<int>? activityId,
    Value<String>? timeOfDay,
    Value<int>? durationMin,
    Value<int>? sortOrder,
    Value<DateTime>? updatedAt,
  }) {
    return ActivitySlotsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      durationMin: durationMin ?? this.durationMin,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySlotsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('durationMin: $durationMin, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivityLogsTable extends ActivityLogs
    with TableInfo<$ActivityLogsTable, ActivityLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<int> activityId = GeneratedColumn<int>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activityId,
    memberId,
    scheduledAt,
    status,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ActivityLogsTable createAlias(String alias) {
    return $ActivityLogsTable(attachedDatabase, alias);
  }
}

class ActivityLog extends DataClass implements Insertable<ActivityLog> {
  final int id;
  final int activityId;
  final int memberId;
  final DateTime scheduledAt;
  final String status;
  final DateTime updatedAt;
  const ActivityLog({
    required this.id,
    required this.activityId,
    required this.memberId,
    required this.scheduledAt,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity_id'] = Variable<int>(activityId);
    map['member_id'] = Variable<int>(memberId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ActivityLogsCompanion toCompanion(bool nullToAbsent) {
    return ActivityLogsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      memberId: Value(memberId),
      scheduledAt: Value(scheduledAt),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActivityLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityLog(
      id: serializer.fromJson<int>(json['id']),
      activityId: serializer.fromJson<int>(json['activityId']),
      memberId: serializer.fromJson<int>(json['memberId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activityId': serializer.toJson<int>(activityId),
      'memberId': serializer.toJson<int>(memberId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'status': serializer.toJson<String>(status),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ActivityLog copyWith({
    int? id,
    int? activityId,
    int? memberId,
    DateTime? scheduledAt,
    String? status,
    DateTime? updatedAt,
  }) => ActivityLog(
    id: id ?? this.id,
    activityId: activityId ?? this.activityId,
    memberId: memberId ?? this.memberId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ActivityLog copyWithCompanion(ActivityLogsCompanion data) {
    return ActivityLog(
      id: data.id.present ? data.id.value : this.id,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLog(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('memberId: $memberId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, activityId, memberId, scheduledAt, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityLog &&
          other.id == this.id &&
          other.activityId == this.activityId &&
          other.memberId == this.memberId &&
          other.scheduledAt == this.scheduledAt &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class ActivityLogsCompanion extends UpdateCompanion<ActivityLog> {
  final Value<int> id;
  final Value<int> activityId;
  final Value<int> memberId;
  final Value<DateTime> scheduledAt;
  final Value<String> status;
  final Value<DateTime> updatedAt;
  const ActivityLogsCompanion({
    this.id = const Value.absent(),
    this.activityId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ActivityLogsCompanion.insert({
    this.id = const Value.absent(),
    required int activityId,
    required int memberId,
    required DateTime scheduledAt,
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : activityId = Value(activityId),
       memberId = Value(memberId),
       scheduledAt = Value(scheduledAt);
  static Insertable<ActivityLog> custom({
    Expression<int>? id,
    Expression<int>? activityId,
    Expression<int>? memberId,
    Expression<DateTime>? scheduledAt,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      if (memberId != null) 'member_id': memberId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ActivityLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? activityId,
    Value<int>? memberId,
    Value<DateTime>? scheduledAt,
    Value<String>? status,
    Value<DateTime>? updatedAt,
  }) {
    return ActivityLogsCompanion(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      memberId: memberId ?? this.memberId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<int>(activityId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityLogsCompanion(')
          ..write('id: $id, ')
          ..write('activityId: $activityId, ')
          ..write('memberId: $memberId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DoctorAppointmentsTable extends DoctorAppointments
    with TableInfo<$DoctorAppointmentsTable, DoctorAppointment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoctorAppointmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doctorTypeMeta = const VerificationMeta(
    'doctorType',
  );
  @override
  late final GeneratedColumn<String> doctorType = GeneratedColumn<String>(
    'doctor_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindBeforeMinMeta = const VerificationMeta(
    'remindBeforeMin',
  );
  @override
  late final GeneratedColumn<int> remindBeforeMin = GeneratedColumn<int>(
    'remind_before_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentPathsMeta = const VerificationMeta(
    'documentPaths',
  );
  @override
  late final GeneratedColumn<String> documentPaths = GeneratedColumn<String>(
    'document_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    doctorType,
    location,
    scheduledAt,
    remindBeforeMin,
    notes,
    pdfPath,
    documentPaths,
    color,
    status,
    createdAt,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'doctor_appointments';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoctorAppointment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('doctor_type')) {
      context.handle(
        _doctorTypeMeta,
        doctorType.isAcceptableOrUnknown(data['doctor_type']!, _doctorTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_doctorTypeMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('remind_before_min')) {
      context.handle(
        _remindBeforeMinMeta,
        remindBeforeMin.isAcceptableOrUnknown(
          data['remind_before_min']!,
          _remindBeforeMinMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('document_paths')) {
      context.handle(
        _documentPathsMeta,
        documentPaths.isAcceptableOrUnknown(
          data['document_paths']!,
          _documentPathsMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoctorAppointment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoctorAppointment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      doctorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_type'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      remindBeforeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_before_min'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      documentPaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_paths'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $DoctorAppointmentsTable createAlias(String alias) {
    return $DoctorAppointmentsTable(attachedDatabase, alias);
  }
}

class DoctorAppointment extends DataClass
    implements Insertable<DoctorAppointment> {
  final int id;
  final int memberId;
  final String doctorType;
  final String? location;
  final DateTime scheduledAt;
  final int remindBeforeMin;
  final String? notes;
  final String? pdfPath;
  final String documentPaths;
  final String? color;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? syncUuid;
  const DoctorAppointment({
    required this.id,
    required this.memberId,
    required this.doctorType,
    this.location,
    required this.scheduledAt,
    required this.remindBeforeMin,
    this.notes,
    this.pdfPath,
    required this.documentPaths,
    this.color,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['doctor_type'] = Variable<String>(doctorType);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['remind_before_min'] = Variable<int>(remindBeforeMin);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    map['document_paths'] = Variable<String>(documentPaths);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  DoctorAppointmentsCompanion toCompanion(bool nullToAbsent) {
    return DoctorAppointmentsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      doctorType: Value(doctorType),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      scheduledAt: Value(scheduledAt),
      remindBeforeMin: Value(remindBeforeMin),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      documentPaths: Value(documentPaths),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory DoctorAppointment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoctorAppointment(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      doctorType: serializer.fromJson<String>(json['doctorType']),
      location: serializer.fromJson<String?>(json['location']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      remindBeforeMin: serializer.fromJson<int>(json['remindBeforeMin']),
      notes: serializer.fromJson<String?>(json['notes']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      documentPaths: serializer.fromJson<String>(json['documentPaths']),
      color: serializer.fromJson<String?>(json['color']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'doctorType': serializer.toJson<String>(doctorType),
      'location': serializer.toJson<String?>(location),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'remindBeforeMin': serializer.toJson<int>(remindBeforeMin),
      'notes': serializer.toJson<String?>(notes),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'documentPaths': serializer.toJson<String>(documentPaths),
      'color': serializer.toJson<String?>(color),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  DoctorAppointment copyWith({
    int? id,
    int? memberId,
    String? doctorType,
    Value<String?> location = const Value.absent(),
    DateTime? scheduledAt,
    int? remindBeforeMin,
    Value<String?> notes = const Value.absent(),
    Value<String?> pdfPath = const Value.absent(),
    String? documentPaths,
    Value<String?> color = const Value.absent(),
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => DoctorAppointment(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    doctorType: doctorType ?? this.doctorType,
    location: location.present ? location.value : this.location,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    remindBeforeMin: remindBeforeMin ?? this.remindBeforeMin,
    notes: notes.present ? notes.value : this.notes,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    documentPaths: documentPaths ?? this.documentPaths,
    color: color.present ? color.value : this.color,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  DoctorAppointment copyWithCompanion(DoctorAppointmentsCompanion data) {
    return DoctorAppointment(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      doctorType: data.doctorType.present
          ? data.doctorType.value
          : this.doctorType,
      location: data.location.present ? data.location.value : this.location,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      remindBeforeMin: data.remindBeforeMin.present
          ? data.remindBeforeMin.value
          : this.remindBeforeMin,
      notes: data.notes.present ? data.notes.value : this.notes,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      documentPaths: data.documentPaths.present
          ? data.documentPaths.value
          : this.documentPaths,
      color: data.color.present ? data.color.value : this.color,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoctorAppointment(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('doctorType: $doctorType, ')
          ..write('location: $location, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('remindBeforeMin: $remindBeforeMin, ')
          ..write('notes: $notes, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('documentPaths: $documentPaths, ')
          ..write('color: $color, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    doctorType,
    location,
    scheduledAt,
    remindBeforeMin,
    notes,
    pdfPath,
    documentPaths,
    color,
    status,
    createdAt,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoctorAppointment &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.doctorType == this.doctorType &&
          other.location == this.location &&
          other.scheduledAt == this.scheduledAt &&
          other.remindBeforeMin == this.remindBeforeMin &&
          other.notes == this.notes &&
          other.pdfPath == this.pdfPath &&
          other.documentPaths == this.documentPaths &&
          other.color == this.color &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class DoctorAppointmentsCompanion extends UpdateCompanion<DoctorAppointment> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> doctorType;
  final Value<String?> location;
  final Value<DateTime> scheduledAt;
  final Value<int> remindBeforeMin;
  final Value<String?> notes;
  final Value<String?> pdfPath;
  final Value<String> documentPaths;
  final Value<String?> color;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const DoctorAppointmentsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.doctorType = const Value.absent(),
    this.location = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.remindBeforeMin = const Value.absent(),
    this.notes = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.documentPaths = const Value.absent(),
    this.color = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  DoctorAppointmentsCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required String doctorType,
    this.location = const Value.absent(),
    required DateTime scheduledAt,
    this.remindBeforeMin = const Value.absent(),
    this.notes = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.documentPaths = const Value.absent(),
    this.color = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : memberId = Value(memberId),
       doctorType = Value(doctorType),
       scheduledAt = Value(scheduledAt);
  static Insertable<DoctorAppointment> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? doctorType,
    Expression<String>? location,
    Expression<DateTime>? scheduledAt,
    Expression<int>? remindBeforeMin,
    Expression<String>? notes,
    Expression<String>? pdfPath,
    Expression<String>? documentPaths,
    Expression<String>? color,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (doctorType != null) 'doctor_type': doctorType,
      if (location != null) 'location': location,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (remindBeforeMin != null) 'remind_before_min': remindBeforeMin,
      if (notes != null) 'notes': notes,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (documentPaths != null) 'document_paths': documentPaths,
      if (color != null) 'color': color,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  DoctorAppointmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? doctorType,
    Value<String?>? location,
    Value<DateTime>? scheduledAt,
    Value<int>? remindBeforeMin,
    Value<String?>? notes,
    Value<String?>? pdfPath,
    Value<String>? documentPaths,
    Value<String?>? color,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return DoctorAppointmentsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      doctorType: doctorType ?? this.doctorType,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      remindBeforeMin: remindBeforeMin ?? this.remindBeforeMin,
      notes: notes ?? this.notes,
      pdfPath: pdfPath ?? this.pdfPath,
      documentPaths: documentPaths ?? this.documentPaths,
      color: color ?? this.color,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (doctorType.present) {
      map['doctor_type'] = Variable<String>(doctorType.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (remindBeforeMin.present) {
      map['remind_before_min'] = Variable<int>(remindBeforeMin.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (documentPaths.present) {
      map['document_paths'] = Variable<String>(documentPaths.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoctorAppointmentsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('doctorType: $doctorType, ')
          ..write('location: $location, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('remindBeforeMin: $remindBeforeMin, ')
          ..write('notes: $notes, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('documentPaths: $documentPaths, ')
          ..write('color: $color, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $SharedChannelsTable extends SharedChannels
    with TableInfo<$SharedChannelsTable, SharedChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SharedChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    memberId,
    lastSyncedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shared_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<SharedChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  SharedChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SharedChannel(
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SharedChannelsTable createAlias(String alias) {
    return $SharedChannelsTable(attachedDatabase, alias);
  }
}

class SharedChannel extends DataClass implements Insertable<SharedChannel> {
  final String channelId;
  final int memberId;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  const SharedChannel({
    required this.channelId,
    required this.memberId,
    this.lastSyncedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['member_id'] = Variable<int>(memberId);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SharedChannelsCompanion toCompanion(bool nullToAbsent) {
    return SharedChannelsCompanion(
      channelId: Value(channelId),
      memberId: Value(memberId),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      createdAt: Value(createdAt),
    );
  }

  factory SharedChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SharedChannel(
      channelId: serializer.fromJson<String>(json['channelId']),
      memberId: serializer.fromJson<int>(json['memberId']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'memberId': serializer.toJson<int>(memberId),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SharedChannel copyWith({
    String? channelId,
    int? memberId,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    DateTime? createdAt,
  }) => SharedChannel(
    channelId: channelId ?? this.channelId,
    memberId: memberId ?? this.memberId,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SharedChannel copyWithCompanion(SharedChannelsCompanion data) {
    return SharedChannel(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SharedChannel(')
          ..write('channelId: $channelId, ')
          ..write('memberId: $memberId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(channelId, memberId, lastSyncedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharedChannel &&
          other.channelId == this.channelId &&
          other.memberId == this.memberId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.createdAt == this.createdAt);
}

class SharedChannelsCompanion extends UpdateCompanion<SharedChannel> {
  final Value<String> channelId;
  final Value<int> memberId;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SharedChannelsCompanion({
    this.channelId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SharedChannelsCompanion.insert({
    required String channelId,
    required int memberId,
    this.lastSyncedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       memberId = Value(memberId);
  static Insertable<SharedChannel> custom({
    Expression<String>? channelId,
    Expression<int>? memberId,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (memberId != null) 'member_id': memberId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SharedChannelsCompanion copyWith({
    Value<String>? channelId,
    Value<int>? memberId,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SharedChannelsCompanion(
      channelId: channelId ?? this.channelId,
      memberId: memberId ?? this.memberId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SharedChannelsCompanion(')
          ..write('channelId: $channelId, ')
          ..write('memberId: $memberId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabResultsTable extends LabResults
    with TableInfo<$LabResultsTable, LabResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabResultsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specialtyMeta = const VerificationMeta(
    'specialty',
  );
  @override
  late final GeneratedColumn<String> specialty = GeneratedColumn<String>(
    'specialty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testNameMeta = const VerificationMeta(
    'testName',
  );
  @override
  late final GeneratedColumn<String> testName = GeneratedColumn<String>(
    'test_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta(
    'attachmentPath',
  );
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentPathsMeta = const VerificationMeta(
    'documentPaths',
  );
  @override
  late final GeneratedColumn<String> documentPaths = GeneratedColumn<String>(
    'document_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    specialty,
    testName,
    takenAt,
    notes,
    attachmentPath,
    documentPaths,
    createdAt,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lab_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('specialty')) {
      context.handle(
        _specialtyMeta,
        specialty.isAcceptableOrUnknown(data['specialty']!, _specialtyMeta),
      );
    } else if (isInserting) {
      context.missing(_specialtyMeta);
    }
    if (data.containsKey('test_name')) {
      context.handle(
        _testNameMeta,
        testName.isAcceptableOrUnknown(data['test_name']!, _testNameMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(
          data['attachment_path']!,
          _attachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('document_paths')) {
      context.handle(
        _documentPathsMeta,
        documentPaths.isAcceptableOrUnknown(
          data['document_paths']!,
          _documentPathsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LabResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      specialty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialty'],
      )!,
      testName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}test_name'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      documentPaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_paths'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $LabResultsTable createAlias(String alias) {
    return $LabResultsTable(attachedDatabase, alias);
  }
}

class LabResult extends DataClass implements Insertable<LabResult> {
  final int id;
  final int memberId;
  final String specialty;
  final String? testName;
  final DateTime takenAt;
  final String? notes;
  final String? attachmentPath;
  final String documentPaths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? syncUuid;
  const LabResult({
    required this.id,
    required this.memberId,
    required this.specialty,
    this.testName,
    required this.takenAt,
    this.notes,
    this.attachmentPath,
    required this.documentPaths,
    required this.createdAt,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['specialty'] = Variable<String>(specialty);
    if (!nullToAbsent || testName != null) {
      map['test_name'] = Variable<String>(testName);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    map['document_paths'] = Variable<String>(documentPaths);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  LabResultsCompanion toCompanion(bool nullToAbsent) {
    return LabResultsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      specialty: Value(specialty),
      testName: testName == null && nullToAbsent
          ? const Value.absent()
          : Value(testName),
      takenAt: Value(takenAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      documentPaths: Value(documentPaths),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory LabResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabResult(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      specialty: serializer.fromJson<String>(json['specialty']),
      testName: serializer.fromJson<String?>(json['testName']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      documentPaths: serializer.fromJson<String>(json['documentPaths']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'specialty': serializer.toJson<String>(specialty),
      'testName': serializer.toJson<String?>(testName),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'notes': serializer.toJson<String?>(notes),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'documentPaths': serializer.toJson<String>(documentPaths),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  LabResult copyWith({
    int? id,
    int? memberId,
    String? specialty,
    Value<String?> testName = const Value.absent(),
    DateTime? takenAt,
    Value<String?> notes = const Value.absent(),
    Value<String?> attachmentPath = const Value.absent(),
    String? documentPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => LabResult(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    specialty: specialty ?? this.specialty,
    testName: testName.present ? testName.value : this.testName,
    takenAt: takenAt ?? this.takenAt,
    notes: notes.present ? notes.value : this.notes,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    documentPaths: documentPaths ?? this.documentPaths,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  LabResult copyWithCompanion(LabResultsCompanion data) {
    return LabResult(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      specialty: data.specialty.present ? data.specialty.value : this.specialty,
      testName: data.testName.present ? data.testName.value : this.testName,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      documentPaths: data.documentPaths.present
          ? data.documentPaths.value
          : this.documentPaths,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabResult(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('specialty: $specialty, ')
          ..write('testName: $testName, ')
          ..write('takenAt: $takenAt, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('documentPaths: $documentPaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    specialty,
    testName,
    takenAt,
    notes,
    attachmentPath,
    documentPaths,
    createdAt,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabResult &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.specialty == this.specialty &&
          other.testName == this.testName &&
          other.takenAt == this.takenAt &&
          other.notes == this.notes &&
          other.attachmentPath == this.attachmentPath &&
          other.documentPaths == this.documentPaths &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class LabResultsCompanion extends UpdateCompanion<LabResult> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> specialty;
  final Value<String?> testName;
  final Value<DateTime> takenAt;
  final Value<String?> notes;
  final Value<String?> attachmentPath;
  final Value<String> documentPaths;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const LabResultsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.specialty = const Value.absent(),
    this.testName = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.documentPaths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  LabResultsCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required String specialty,
    this.testName = const Value.absent(),
    required DateTime takenAt,
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.documentPaths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : memberId = Value(memberId),
       specialty = Value(specialty),
       takenAt = Value(takenAt);
  static Insertable<LabResult> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? specialty,
    Expression<String>? testName,
    Expression<DateTime>? takenAt,
    Expression<String>? notes,
    Expression<String>? attachmentPath,
    Expression<String>? documentPaths,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (specialty != null) 'specialty': specialty,
      if (testName != null) 'test_name': testName,
      if (takenAt != null) 'taken_at': takenAt,
      if (notes != null) 'notes': notes,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (documentPaths != null) 'document_paths': documentPaths,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  LabResultsCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? specialty,
    Value<String?>? testName,
    Value<DateTime>? takenAt,
    Value<String?>? notes,
    Value<String?>? attachmentPath,
    Value<String>? documentPaths,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return LabResultsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      specialty: specialty ?? this.specialty,
      testName: testName ?? this.testName,
      takenAt: takenAt ?? this.takenAt,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      documentPaths: documentPaths ?? this.documentPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (specialty.present) {
      map['specialty'] = Variable<String>(specialty.value);
    }
    if (testName.present) {
      map['test_name'] = Variable<String>(testName.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (documentPaths.present) {
      map['document_paths'] = Variable<String>(documentPaths.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabResultsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('specialty: $specialty, ')
          ..write('testName: $testName, ')
          ..write('takenAt: $takenAt, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('documentPaths: $documentPaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $AllergiesTable extends Allergies
    with TableInfo<$AllergiesTable, Allergy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AllergiesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allergenMeta = const VerificationMeta(
    'allergen',
  );
  @override
  late final GeneratedColumn<String> allergen = GeneratedColumn<String>(
    'allergen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reactionMeta = const VerificationMeta(
    'reaction',
  );
  @override
  late final GeneratedColumn<String> reaction = GeneratedColumn<String>(
    'reaction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('mild'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    allergen,
    reaction,
    severity,
    notes,
    createdAt,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'allergies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Allergy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('allergen')) {
      context.handle(
        _allergenMeta,
        allergen.isAcceptableOrUnknown(data['allergen']!, _allergenMeta),
      );
    } else if (isInserting) {
      context.missing(_allergenMeta);
    }
    if (data.containsKey('reaction')) {
      context.handle(
        _reactionMeta,
        reaction.isAcceptableOrUnknown(data['reaction']!, _reactionMeta),
      );
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Allergy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Allergy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      allergen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergen'],
      )!,
      reaction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reaction'],
      ),
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $AllergiesTable createAlias(String alias) {
    return $AllergiesTable(attachedDatabase, alias);
  }
}

class Allergy extends DataClass implements Insertable<Allergy> {
  final int id;
  final int memberId;
  final String allergen;
  final String? reaction;
  final String severity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? syncUuid;
  const Allergy({
    required this.id,
    required this.memberId,
    required this.allergen,
    this.reaction,
    required this.severity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['allergen'] = Variable<String>(allergen);
    if (!nullToAbsent || reaction != null) {
      map['reaction'] = Variable<String>(reaction);
    }
    map['severity'] = Variable<String>(severity);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  AllergiesCompanion toCompanion(bool nullToAbsent) {
    return AllergiesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      allergen: Value(allergen),
      reaction: reaction == null && nullToAbsent
          ? const Value.absent()
          : Value(reaction),
      severity: Value(severity),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory Allergy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Allergy(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      allergen: serializer.fromJson<String>(json['allergen']),
      reaction: serializer.fromJson<String?>(json['reaction']),
      severity: serializer.fromJson<String>(json['severity']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'allergen': serializer.toJson<String>(allergen),
      'reaction': serializer.toJson<String?>(reaction),
      'severity': serializer.toJson<String>(severity),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  Allergy copyWith({
    int? id,
    int? memberId,
    String? allergen,
    Value<String?> reaction = const Value.absent(),
    String? severity,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => Allergy(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    allergen: allergen ?? this.allergen,
    reaction: reaction.present ? reaction.value : this.reaction,
    severity: severity ?? this.severity,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  Allergy copyWithCompanion(AllergiesCompanion data) {
    return Allergy(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      allergen: data.allergen.present ? data.allergen.value : this.allergen,
      reaction: data.reaction.present ? data.reaction.value : this.reaction,
      severity: data.severity.present ? data.severity.value : this.severity,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Allergy(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('allergen: $allergen, ')
          ..write('reaction: $reaction, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    allergen,
    reaction,
    severity,
    notes,
    createdAt,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Allergy &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.allergen == this.allergen &&
          other.reaction == this.reaction &&
          other.severity == this.severity &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class AllergiesCompanion extends UpdateCompanion<Allergy> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> allergen;
  final Value<String?> reaction;
  final Value<String> severity;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const AllergiesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.allergen = const Value.absent(),
    this.reaction = const Value.absent(),
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  AllergiesCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required String allergen,
    this.reaction = const Value.absent(),
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : memberId = Value(memberId),
       allergen = Value(allergen);
  static Insertable<Allergy> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? allergen,
    Expression<String>? reaction,
    Expression<String>? severity,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (allergen != null) 'allergen': allergen,
      if (reaction != null) 'reaction': reaction,
      if (severity != null) 'severity': severity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  AllergiesCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? allergen,
    Value<String?>? reaction,
    Value<String>? severity,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return AllergiesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      allergen: allergen ?? this.allergen,
      reaction: reaction ?? this.reaction,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (allergen.present) {
      map['allergen'] = Variable<String>(allergen.value);
    }
    if (reaction.present) {
      map['reaction'] = Variable<String>(reaction.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AllergiesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('allergen: $allergen, ')
          ..write('reaction: $reaction, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $ChronicConditionsTable extends ChronicConditions
    with TableInfo<$ChronicConditionsTable, ChronicCondition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChronicConditionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specialtyMeta = const VerificationMeta(
    'specialty',
  );
  @override
  late final GeneratedColumn<String> specialty = GeneratedColumn<String>(
    'specialty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diagnosedAtMeta = const VerificationMeta(
    'diagnosedAt',
  );
  @override
  late final GeneratedColumn<DateTime> diagnosedAt = GeneratedColumn<DateTime>(
    'diagnosed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    specialty,
    diagnosedAt,
    notes,
    createdAt,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chronic_conditions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChronicCondition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('specialty')) {
      context.handle(
        _specialtyMeta,
        specialty.isAcceptableOrUnknown(data['specialty']!, _specialtyMeta),
      );
    }
    if (data.containsKey('diagnosed_at')) {
      context.handle(
        _diagnosedAtMeta,
        diagnosedAt.isAcceptableOrUnknown(
          data['diagnosed_at']!,
          _diagnosedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChronicCondition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChronicCondition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      specialty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialty'],
      ),
      diagnosedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}diagnosed_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $ChronicConditionsTable createAlias(String alias) {
    return $ChronicConditionsTable(attachedDatabase, alias);
  }
}

class ChronicCondition extends DataClass
    implements Insertable<ChronicCondition> {
  final int id;
  final int memberId;
  final String name;
  final String? specialty;
  final DateTime? diagnosedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? syncUuid;
  const ChronicCondition({
    required this.id,
    required this.memberId,
    required this.name,
    this.specialty,
    this.diagnosedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || specialty != null) {
      map['specialty'] = Variable<String>(specialty);
    }
    if (!nullToAbsent || diagnosedAt != null) {
      map['diagnosed_at'] = Variable<DateTime>(diagnosedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  ChronicConditionsCompanion toCompanion(bool nullToAbsent) {
    return ChronicConditionsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      specialty: specialty == null && nullToAbsent
          ? const Value.absent()
          : Value(specialty),
      diagnosedAt: diagnosedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory ChronicCondition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChronicCondition(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      name: serializer.fromJson<String>(json['name']),
      specialty: serializer.fromJson<String?>(json['specialty']),
      diagnosedAt: serializer.fromJson<DateTime?>(json['diagnosedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'name': serializer.toJson<String>(name),
      'specialty': serializer.toJson<String?>(specialty),
      'diagnosedAt': serializer.toJson<DateTime?>(diagnosedAt),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  ChronicCondition copyWith({
    int? id,
    int? memberId,
    String? name,
    Value<String?> specialty = const Value.absent(),
    Value<DateTime?> diagnosedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => ChronicCondition(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    specialty: specialty.present ? specialty.value : this.specialty,
    diagnosedAt: diagnosedAt.present ? diagnosedAt.value : this.diagnosedAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  ChronicCondition copyWithCompanion(ChronicConditionsCompanion data) {
    return ChronicCondition(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      specialty: data.specialty.present ? data.specialty.value : this.specialty,
      diagnosedAt: data.diagnosedAt.present
          ? data.diagnosedAt.value
          : this.diagnosedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChronicCondition(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('specialty: $specialty, ')
          ..write('diagnosedAt: $diagnosedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    specialty,
    diagnosedAt,
    notes,
    createdAt,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChronicCondition &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.specialty == this.specialty &&
          other.diagnosedAt == this.diagnosedAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class ChronicConditionsCompanion extends UpdateCompanion<ChronicCondition> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> name;
  final Value<String?> specialty;
  final Value<DateTime?> diagnosedAt;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const ChronicConditionsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.specialty = const Value.absent(),
    this.diagnosedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  ChronicConditionsCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required String name,
    this.specialty = const Value.absent(),
    this.diagnosedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : memberId = Value(memberId),
       name = Value(name);
  static Insertable<ChronicCondition> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? name,
    Expression<String>? specialty,
    Expression<DateTime>? diagnosedAt,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (specialty != null) 'specialty': specialty,
      if (diagnosedAt != null) 'diagnosed_at': diagnosedAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  ChronicConditionsCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? name,
    Value<String?>? specialty,
    Value<DateTime?>? diagnosedAt,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return ChronicConditionsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      diagnosedAt: diagnosedAt ?? this.diagnosedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (specialty.present) {
      map['specialty'] = Variable<String>(specialty.value);
    }
    if (diagnosedAt.present) {
      map['diagnosed_at'] = Variable<DateTime>(diagnosedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChronicConditionsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('specialty: $specialty, ')
          ..write('diagnosedAt: $diagnosedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $VaccinationsTable extends Vaccinations
    with TableInfo<$VaccinationsTable, Vaccination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaccinationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _givenAtMeta = const VerificationMeta(
    'givenAt',
  );
  @override
  late final GeneratedColumn<DateTime> givenAt = GeneratedColumn<DateTime>(
    'given_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextDoseAtMeta = const VerificationMeta(
    'nextDoseAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextDoseAt = GeneratedColumn<DateTime>(
    'next_dose_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    givenAt,
    nextDoseAt,
    notes,
    createdAt,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vaccinations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Vaccination> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('given_at')) {
      context.handle(
        _givenAtMeta,
        givenAt.isAcceptableOrUnknown(data['given_at']!, _givenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_givenAtMeta);
    }
    if (data.containsKey('next_dose_at')) {
      context.handle(
        _nextDoseAtMeta,
        nextDoseAt.isAcceptableOrUnknown(
          data['next_dose_at']!,
          _nextDoseAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Vaccination map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vaccination(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      givenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}given_at'],
      )!,
      nextDoseAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_dose_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $VaccinationsTable createAlias(String alias) {
    return $VaccinationsTable(attachedDatabase, alias);
  }
}

class Vaccination extends DataClass implements Insertable<Vaccination> {
  final int id;
  final int memberId;
  final String name;
  final DateTime givenAt;
  final DateTime? nextDoseAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? syncUuid;
  const Vaccination({
    required this.id,
    required this.memberId,
    required this.name,
    required this.givenAt,
    this.nextDoseAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['name'] = Variable<String>(name);
    map['given_at'] = Variable<DateTime>(givenAt);
    if (!nullToAbsent || nextDoseAt != null) {
      map['next_dose_at'] = Variable<DateTime>(nextDoseAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  VaccinationsCompanion toCompanion(bool nullToAbsent) {
    return VaccinationsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      givenAt: Value(givenAt),
      nextDoseAt: nextDoseAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDoseAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory Vaccination.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vaccination(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      name: serializer.fromJson<String>(json['name']),
      givenAt: serializer.fromJson<DateTime>(json['givenAt']),
      nextDoseAt: serializer.fromJson<DateTime?>(json['nextDoseAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'name': serializer.toJson<String>(name),
      'givenAt': serializer.toJson<DateTime>(givenAt),
      'nextDoseAt': serializer.toJson<DateTime?>(nextDoseAt),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  Vaccination copyWith({
    int? id,
    int? memberId,
    String? name,
    DateTime? givenAt,
    Value<DateTime?> nextDoseAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => Vaccination(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    givenAt: givenAt ?? this.givenAt,
    nextDoseAt: nextDoseAt.present ? nextDoseAt.value : this.nextDoseAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  Vaccination copyWithCompanion(VaccinationsCompanion data) {
    return Vaccination(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      givenAt: data.givenAt.present ? data.givenAt.value : this.givenAt,
      nextDoseAt: data.nextDoseAt.present
          ? data.nextDoseAt.value
          : this.nextDoseAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Vaccination(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('givenAt: $givenAt, ')
          ..write('nextDoseAt: $nextDoseAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    givenAt,
    nextDoseAt,
    notes,
    createdAt,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vaccination &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.givenAt == this.givenAt &&
          other.nextDoseAt == this.nextDoseAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class VaccinationsCompanion extends UpdateCompanion<Vaccination> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> name;
  final Value<DateTime> givenAt;
  final Value<DateTime?> nextDoseAt;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const VaccinationsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.givenAt = const Value.absent(),
    this.nextDoseAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  VaccinationsCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required String name,
    required DateTime givenAt,
    this.nextDoseAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : memberId = Value(memberId),
       name = Value(name),
       givenAt = Value(givenAt);
  static Insertable<Vaccination> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? name,
    Expression<DateTime>? givenAt,
    Expression<DateTime>? nextDoseAt,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (givenAt != null) 'given_at': givenAt,
      if (nextDoseAt != null) 'next_dose_at': nextDoseAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  VaccinationsCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? name,
    Value<DateTime>? givenAt,
    Value<DateTime?>? nextDoseAt,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return VaccinationsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      givenAt: givenAt ?? this.givenAt,
      nextDoseAt: nextDoseAt ?? this.nextDoseAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (givenAt.present) {
      map['given_at'] = Variable<DateTime>(givenAt.value);
    }
    if (nextDoseAt.present) {
      map['next_dose_at'] = Variable<DateTime>(nextDoseAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaccinationsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('givenAt: $givenAt, ')
          ..write('nextDoseAt: $nextDoseAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

class $SurgeriesTable extends Surgeries
    with TableInfo<$SurgeriesTable, Surgery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurgeriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<int> memberId = GeneratedColumn<int>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _performedAtMeta = const VerificationMeta(
    'performedAt',
  );
  @override
  late final GeneratedColumn<DateTime> performedAt = GeneratedColumn<DateTime>(
    'performed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta(
    'attachmentPath',
  );
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentPathsMeta = const VerificationMeta(
    'documentPaths',
  );
  @override
  late final GeneratedColumn<String> documentPaths = GeneratedColumn<String>(
    'document_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncUuidMeta = const VerificationMeta(
    'syncUuid',
  );
  @override
  late final GeneratedColumn<String> syncUuid = GeneratedColumn<String>(
    'sync_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    name,
    performedAt,
    notes,
    attachmentPath,
    documentPaths,
    createdAt,
    updatedAt,
    syncUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surgeries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Surgery> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('performed_at')) {
      context.handle(
        _performedAtMeta,
        performedAt.isAcceptableOrUnknown(
          data['performed_at']!,
          _performedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_performedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(
          data['attachment_path']!,
          _attachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('document_paths')) {
      context.handle(
        _documentPathsMeta,
        documentPaths.isAcceptableOrUnknown(
          data['document_paths']!,
          _documentPathsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('sync_uuid')) {
      context.handle(
        _syncUuidMeta,
        syncUuid.isAcceptableOrUnknown(data['sync_uuid']!, _syncUuidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Surgery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surgery(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      performedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}performed_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      documentPaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_paths'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_uuid'],
      ),
    );
  }

  @override
  $SurgeriesTable createAlias(String alias) {
    return $SurgeriesTable(attachedDatabase, alias);
  }
}

class Surgery extends DataClass implements Insertable<Surgery> {
  final int id;
  final int memberId;
  final String name;
  final DateTime performedAt;
  final String? notes;
  final String? attachmentPath;
  final String documentPaths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? syncUuid;
  const Surgery({
    required this.id,
    required this.memberId,
    required this.name,
    required this.performedAt,
    this.notes,
    this.attachmentPath,
    required this.documentPaths,
    required this.createdAt,
    required this.updatedAt,
    this.syncUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['member_id'] = Variable<int>(memberId);
    map['name'] = Variable<String>(name);
    map['performed_at'] = Variable<DateTime>(performedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    map['document_paths'] = Variable<String>(documentPaths);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncUuid != null) {
      map['sync_uuid'] = Variable<String>(syncUuid);
    }
    return map;
  }

  SurgeriesCompanion toCompanion(bool nullToAbsent) {
    return SurgeriesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      name: Value(name),
      performedAt: Value(performedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      documentPaths: Value(documentPaths),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncUuid: syncUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(syncUuid),
    );
  }

  factory Surgery.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surgery(
      id: serializer.fromJson<int>(json['id']),
      memberId: serializer.fromJson<int>(json['memberId']),
      name: serializer.fromJson<String>(json['name']),
      performedAt: serializer.fromJson<DateTime>(json['performedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      documentPaths: serializer.fromJson<String>(json['documentPaths']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncUuid: serializer.fromJson<String?>(json['syncUuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'memberId': serializer.toJson<int>(memberId),
      'name': serializer.toJson<String>(name),
      'performedAt': serializer.toJson<DateTime>(performedAt),
      'notes': serializer.toJson<String?>(notes),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'documentPaths': serializer.toJson<String>(documentPaths),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncUuid': serializer.toJson<String?>(syncUuid),
    };
  }

  Surgery copyWith({
    int? id,
    int? memberId,
    String? name,
    DateTime? performedAt,
    Value<String?> notes = const Value.absent(),
    Value<String?> attachmentPath = const Value.absent(),
    String? documentPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> syncUuid = const Value.absent(),
  }) => Surgery(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    name: name ?? this.name,
    performedAt: performedAt ?? this.performedAt,
    notes: notes.present ? notes.value : this.notes,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    documentPaths: documentPaths ?? this.documentPaths,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncUuid: syncUuid.present ? syncUuid.value : this.syncUuid,
  );
  Surgery copyWithCompanion(SurgeriesCompanion data) {
    return Surgery(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      name: data.name.present ? data.name.value : this.name,
      performedAt: data.performedAt.present
          ? data.performedAt.value
          : this.performedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      documentPaths: data.documentPaths.present
          ? data.documentPaths.value
          : this.documentPaths,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncUuid: data.syncUuid.present ? data.syncUuid.value : this.syncUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surgery(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('performedAt: $performedAt, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('documentPaths: $documentPaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    performedAt,
    notes,
    attachmentPath,
    documentPaths,
    createdAt,
    updatedAt,
    syncUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surgery &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.name == this.name &&
          other.performedAt == this.performedAt &&
          other.notes == this.notes &&
          other.attachmentPath == this.attachmentPath &&
          other.documentPaths == this.documentPaths &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncUuid == this.syncUuid);
}

class SurgeriesCompanion extends UpdateCompanion<Surgery> {
  final Value<int> id;
  final Value<int> memberId;
  final Value<String> name;
  final Value<DateTime> performedAt;
  final Value<String?> notes;
  final Value<String?> attachmentPath;
  final Value<String> documentPaths;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> syncUuid;
  const SurgeriesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.name = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.documentPaths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  });
  SurgeriesCompanion.insert({
    this.id = const Value.absent(),
    required int memberId,
    required String name,
    required DateTime performedAt,
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.documentPaths = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncUuid = const Value.absent(),
  }) : memberId = Value(memberId),
       name = Value(name),
       performedAt = Value(performedAt);
  static Insertable<Surgery> custom({
    Expression<int>? id,
    Expression<int>? memberId,
    Expression<String>? name,
    Expression<DateTime>? performedAt,
    Expression<String>? notes,
    Expression<String>? attachmentPath,
    Expression<String>? documentPaths,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncUuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (name != null) 'name': name,
      if (performedAt != null) 'performed_at': performedAt,
      if (notes != null) 'notes': notes,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (documentPaths != null) 'document_paths': documentPaths,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncUuid != null) 'sync_uuid': syncUuid,
    });
  }

  SurgeriesCompanion copyWith({
    Value<int>? id,
    Value<int>? memberId,
    Value<String>? name,
    Value<DateTime>? performedAt,
    Value<String?>? notes,
    Value<String?>? attachmentPath,
    Value<String>? documentPaths,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? syncUuid,
  }) {
    return SurgeriesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      performedAt: performedAt ?? this.performedAt,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      documentPaths: documentPaths ?? this.documentPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncUuid: syncUuid ?? this.syncUuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<int>(memberId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (performedAt.present) {
      map['performed_at'] = Variable<DateTime>(performedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (documentPaths.present) {
      map['document_paths'] = Variable<String>(documentPaths.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncUuid.present) {
      map['sync_uuid'] = Variable<String>(syncUuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurgeriesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('name: $name, ')
          ..write('performedAt: $performedAt, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('documentPaths: $documentPaths, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncUuid: $syncUuid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $MembersTable members = $MembersTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final $IntakesTable intakes = $IntakesTable(this);
  late final $SymptomsTable symptoms = $SymptomsTable(this);
  late final $WellbeingLogsTable wellbeingLogs = $WellbeingLogsTable(this);
  late final $WellbeingSchedulesTable wellbeingSchedules =
      $WellbeingSchedulesTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $ActivitySlotsTable activitySlots = $ActivitySlotsTable(this);
  late final $ActivityLogsTable activityLogs = $ActivityLogsTable(this);
  late final $DoctorAppointmentsTable doctorAppointments =
      $DoctorAppointmentsTable(this);
  late final $SharedChannelsTable sharedChannels = $SharedChannelsTable(this);
  late final $LabResultsTable labResults = $LabResultsTable(this);
  late final $AllergiesTable allergies = $AllergiesTable(this);
  late final $ChronicConditionsTable chronicConditions =
      $ChronicConditionsTable(this);
  late final $VaccinationsTable vaccinations = $VaccinationsTable(this);
  late final $SurgeriesTable surgeries = $SurgeriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    members,
    medications,
    schedules,
    intakes,
    symptoms,
    wellbeingLogs,
    wellbeingSchedules,
    activities,
    activitySlots,
    activityLogs,
    doctorAppointments,
    sharedChannels,
    labResults,
    allergies,
    chronicConditions,
    vaccinations,
    surgeries,
  ];
}
