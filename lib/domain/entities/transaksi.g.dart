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
      rowsData: fields[5] as String?,
      catatanSubsidi: fields[6] as String?,
      catatanReimburse: fields[7] as String?,
      catatanPotongan: fields[8] as String?,
      isLunas: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Transaksi obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tanggal)
      ..writeByte(2)
      ..write(obj.jenis)
      ..writeByte(3)
      ..write(obj.namaTarget)
      ..writeByte(4)
      ..write(obj.total)
      ..writeByte(5)
      ..write(obj.rowsData)
      ..writeByte(6)
      ..write(obj.catatanSubsidi)
      ..writeByte(7)
      ..write(obj.catatanReimburse)
      ..writeByte(8)
      ..write(obj.catatanPotongan)
      ..writeByte(9)
      ..write(obj.isLunas);
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
