library jaguar_orm.generator.parser;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/constant/value.dart';

import 'package:jaguar_orm/src/annotations/annotations.dart' as ant;

import 'package:jaguar_orm_cli/src/common/common.dart';

class ParsedColumn {
  final FieldElement element;

  final ant.ColumnBase instantiated;

  final DartType fieldType;

  ParsedColumn(this.element, this.fieldType, this.instantiated);

  String get key => instantiated.key ?? name;

  String get name => element.name;

  bool get isPrimary => instantiated is ant.PrimaryKey;

  static ParsedColumn detect(FieldElement f) {
    //If IgnoreField is present, skip!
    {
      int ignore = f.metadata
          .map((ElementAnnotation annot) => annot.computeConstantValue())
          .where((DartObject inst) => isIgnore.isExactlyType(inst.type))
          .length;

      if (ignore != 0) {
        return null;
      }
    }

    final DartType type = f.type;

    if (f.isStatic || (!isBuiltin(type) && !isDateTime.isExactlyType(type))) {
      return null;
    }

    List<ant.ColumnBase> columns = f.metadata
        .map((ElementAnnotation annot) => annot.computeConstantValue())
        .where((DartObject i) => isColumnBase.isAssignableFromType(i.type))
        .map(parseColumn)
        .toList();

    if (columns.length > 1) {
      throw new Exception('Only one Column annotation is allowed on a Field!');
    }

    if (columns.length == 0) {
      return new ParsedColumn(f, type, new ant.Column());
    }

    return new ParsedColumn(f, type, columns.first);
  }
}

class ParsedBean {
  final ClassElement clazz;

  final DartType model;

  final List<ParsedColumn> columns;

  final ParsedColumn primary;

  ParsedBean(this.clazz, this.model, this.columns, this.primary);

  String get name => clazz.name;

  static ParsedBean detect(ClassElement clazz) {
    if (!isBean.isAssignableFromType(clazz.type)) {
      throw new Exception("Beans must implement Bean interface!");
    }

    final InterfaceType interface = clazz.allSupertypes
        .firstWhere((InterfaceType i) => isBean.isExactlyType(i));

    final DartType model = interface.typeArguments.first;

    if (model.isDynamic) {
      throw new Exception("Don't support Model of type dynamic!");
    }

    final ClassElement modelClass = model.element;

    List<ParsedColumn> columns = modelClass.fields
        .map(ParsedColumn.detect)
        .where((ParsedColumn col) => col is ParsedColumn)
        .toList();

    List<ParsedColumn> primaries =
        columns.where((ParsedColumn col) => col.isPrimary).toList();

    if (primaries.length > 1) {
      throw new Exception('Only one primary key allowed!');
    }

    ParsedColumn primary = primaries.length == 1 ? primaries.first : null;

    return new ParsedBean(clazz, model, columns, primary);
  }
}

ant.ColumnBase parseColumn(DartObject obj) {
  if (isColumn.isExactlyType(obj.type)) {
    return new ant.Column(obj.getField('key').toStringValue());
  } else if (isPrimaryKey.isExactlyType(obj.type)) {
    return new ant.PrimaryKey(obj.getField('key').toStringValue());
  } else if (isForeignKey.isExactlyType(obj.type)) {
    throw new Exception('ForeignKey not implemented!');
  }

  throw new Exception('Invalid ColumnBase type!');
}
