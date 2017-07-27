library jaguar_orm.generator.model;

import 'package:analyzer/dart/element/type.dart';

import 'package:jaguar_orm_cli/src/parser/parser.dart';
import 'package:jaguar_orm_cli/src/common/common.dart';

class ForeignBean {
  final String relationName;

  final List<String> fields;
}

class Field {
  final String field;

  final String type;

  final String vType;

  final String key;

  Field(this.type, this.vType, this.field, this.key);

  static Field fromParsed(ParsedColumn col) => new Field(
      col.fieldType.name, _getValType(col.fieldType), col.name, col.key);
}

class WriterInfo {
  final String name;

  final String modelType;

  final List<Field> fields;

  final Field primary;

  WriterInfo(this.name, this.modelType, this.fields, this.primary);
}

class ToModel {
  final ParsedBean _parsed;

  WriterInfo _model;

  ToModel(this._parsed) {
    final List<Field> fields = [];

    _parsed.columns.map(Field.fromParsed).forEach(fields.add);

    _model = new WriterInfo(_parsed.name, _parsed.model.name, fields,
        Field.fromParsed(_parsed.primary));
  }

  WriterInfo get model => _model;
}

String _getValType(DartType type) {
  if (isString.isExactlyType(type)) {
    return 'StrField';
  } else if (isBool.isExactlyType(type)) {
    return 'BitField';
  } else if (isInt.isExactlyType(type)) {
    return 'IntField';
  } else if (isNum.isExactlyType(type) || isDouble.isExactlyType(type)) {
    return 'NumField';
  } else if (isDateTime.isExactlyType(type)) {
    return 'DateTimeField';
  }

  throw new Exception('Field type not recognised!');
}
