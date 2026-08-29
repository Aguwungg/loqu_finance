// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaksi.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransaksiAdapter extends TypeAdapter<Transaksi> {
  @override
  final int typeId = 2;

  @override
  Transaksi read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaksi(
      id: fields[0] as String,
      tanggal: fields[1] as DateTime,
      jenis: fields[2] as String,
      namaTarget: fields[3] as String,
      total: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Transaksi obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tanggal)
      ..writeByte(2)
      ..write(obj.jenis)
      ..writeByte(3)
      ..write(obj.namaTarget)
      ..writeByte(4)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransaksiAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
