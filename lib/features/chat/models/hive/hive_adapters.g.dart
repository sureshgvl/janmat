// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveMessageAdapter extends TypeAdapter<HiveMessage> {
  @override
  final int typeId = 0;

  @override
  HiveMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveMessage(
      messageId: fields[0] as String,
      text: fields[1] as String,
      senderId: fields[2] as String,
      type: fields[3] as String,
      createdAt: fields[4] as DateTime,
      readBy: (fields[5] as List).cast<String>(),
      mediaUrl: fields[6] as String?,
      metadata: (fields[7] as Map?)?.cast<String, dynamic>(),
      isDeleted: fields[8] as bool?,
      reactions: (fields[9] as List?)?.cast<HiveMessageReaction>(),
      status: fields[10] as int,
      retryCount: fields[11] as int,
      roomId: fields[12] as String,
      localMediaPath: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveMessage obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.readBy)
      ..writeByte(6)
      ..write(obj.mediaUrl)
      ..writeByte(7)
      ..write(obj.metadata)
      ..writeByte(8)
      ..write(obj.isDeleted)
      ..writeByte(9)
      ..write(obj.reactions)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.retryCount)
      ..writeByte(12)
      ..write(obj.roomId)
      ..writeByte(13)
      ..write(obj.localMediaPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveMessageReactionAdapter extends TypeAdapter<HiveMessageReaction> {
  @override
  final int typeId = 1;

  @override
  HiveMessageReaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveMessageReaction(
      emoji: fields[0] as String,
      userId: fields[1] as String,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HiveMessageReaction obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.emoji)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveMessageReactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
