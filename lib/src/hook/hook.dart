library jaguar_orm.generator.hook;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';

import 'package:jaguar_orm/src/annotations/annotations.dart' as ant;

import 'package:jaguar_orm_cli/src/parser/parser.dart';
import 'package:jaguar_orm_cli/src/writer/writer.dart';
import 'package:jaguar_orm_cli/src/model/model.dart';

/// source_gen hook to generate serializer
class BeanGenerator extends GeneratorForAnnotation<ant.GenBean> {
  const BeanGenerator();

  /// This method is called when build finds an element with
  /// [GenSerializer] annotation.
  ///
  /// [element] is the element annotated with [Api]
  /// [api] is an instantiation of the [Api] annotation
  @override
  Future<String> generateForAnnotatedElement(
      final Element element, ConstantReader annot, BuildStep buildStep) async {
    if (element is! ClassElement) {
      throw new Exception("GenBean annotation can only be defined on a class.");
    }

    final String className = element.name;

    print("Generating bean for $className ...");

    /// Parse the element
    ParsedBean parsed = ParsedBean.detect(element);

    /// Morph [ParsedBean] to [WriterInfo]
    final WriterInfo bean = new ToModel(parsed).model;

    /// Write the info
    final writer = new Writer(bean);

    return writer.toString();
  }
}
