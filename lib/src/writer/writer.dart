library jaguar_orm.generator.writer;

import 'package:jaguar_orm_cli/src/model/model.dart';

class Writer {
  final StringBuffer _w = new StringBuffer();

  final WriterInfo _b;

  Writer(this._b) {
    _generate();
  }

  String toString() => _w.toString();

  void _generate() {
    _w.writeln('abstract class _${_b.name} implements Bean<${_b.modelType}> {');
    _w.writeln();

    _writeTableName();

    _b.fields.values.forEach(_writeFields);

    _writeFromMap();

    _writeToSetColumns();

    _writeCrud();

    // TODO get by foreign for non-beaned

    // TODO remove by foreign for non-beaned

    _b.getByForeign.values
        .where((FindByForeign f) => f is FindByForeignBean)
        .forEach(_writeGetOneByForeign);

    _b.getByForeign.values
        .where((FindByForeign f) => f is FindByForeignBean)
        .forEach(_removeByForeign);

    _b.getByForeign.values
        .where((FindByForeign f) => f is FindByForeignBean)
        .forEach(_writeFindByForeignList);

    _b.getByForeign.values
        .where((FindByForeign f) => f is FindByForeignBean)
        .forEach(_writeAssociate);

    _b.getByForeign.values
        .where((FindByForeign f) => f is FindByForeignBean && f.belongsToMany)
        .forEach(_writeDetach);

    _b.getByForeign.values
        .where((FindByForeign f) => f is FindByForeignBean && f.belongsToMany)
        .forEach(_writeFetchOther);
    _writeAttach();

    _writePreload();

    _writePreloadAll();

    _writePreloadBeans();

    _w.writeln('}');
  }

  void _writeTableName() {
    _w.writeln('String get tableName => ${_b.modelType}.tableName;');
    _w.writeln();
  }

  void _writeFields(Field field) {
    _writeln(
        "final ${field.vType} ${field.field} = new ${field.vType}('${field.colName}');");
    _w.writeln();
  }

  void _writeFromMap() {
    _w.writeln('${_b.modelType} fromMap(Map map) {');
    _w.writeln('${_b.modelType} model = new ${_b.modelType}();');
    _w.writeln();

    _b.fields.values.forEach((Field field) {
      _w.writeln("model.${field.field} = map['${field.colName}'];");
    });

    _w.writeln();
    _w.writeln('return model;');
    _w.writeln('}');
  }

  void _writeToSetColumns() {
    _w.writeln(
        'List<SetColumn> toSetColumns(${_b.modelType} model, [bool update = false]) {');
    _w.writeln('List<SetColumn> ret = [];');
    _w.writeln();

    // TODO if update, don't set primary key
    _b.fields.values.forEach((Field field) {
      _w.writeln("ret.add(${field.field}.set(model.${field.field}));");
    });

    _w.writeln();
    _w.writeln('return ret;');
    _w.writeln('}');
  }

  void _writeCrud() {
    _writeInsert();
    _writeUpdate();
    _writeFind();
    _writeFindWhere();
    _writeRemove();
    _writeRemoveMany();
    _writeRemoveWhere();
  }

  void _writeInsert() {
    if (_b.preloads.length == 0 || _b.primary.length == 0) {
      _w.writeln('Future<dynamic> insert(${_b.modelType} model) async {');
      _w.write('final Insert insert = inserter');
      _w.writeln('.setMany(toSetColumns(model));');
      _w.writeln('return execInsert(insert);');
      _w.writeln('}');
      return;
    }

    if (_b.primary.length == 1 && _b.primary.first.auto) {
      _w.writeln('Future<dynamic> insert(${_b
              .modelType} model, {bool cascade: false}) async {');
      _w.write('final Insert insert = inserter');
      _w.writeln(
          '.setMany(toSetColumns(model))..id(${_b.primary.first.colName});');
      _w.writeln('final ret = await execInsert(insert);');

      _w.writeln('if(cascade) {');
      _w.writeln('${_b.modelType} newModel;');
      for (Preload p in _b.preloads) {
        _w.writeln('if(model.${p.property} != null) {');
        _w.writeln('newModel ??= await find(ret);');

        if (!p.hasMany) {
          _write(_uncap(p.beanInstanceName));
          _writeln(
              '.associate${_b.modelType}(model.' + p.property + ', newModel);');
          _write('await ' +
              _uncap(p.beanInstanceName) +
              '.insert(model.' +
              p.property +
              ');');
        } else {
          if (p is PreloadOneToX) {
            _write('model.' + p.property + '.forEach((x) => ');
            _write(_uncap(p.beanInstanceName));
            _writeln('.associate${_b.modelType}(x, newModel));');
            _writeln('for(final child in model.${p.property}) {');
            _writeln('await ' + _uncap(p.beanInstanceName) + '.insert(child);');
            _writeln('}');
          } else if (p is PreloadManyToMany) {
            _writeln('for(final child in model.${p.property}) {');
            _writeln('await ${p.targetBeanInstanceName}.insert(child);');
            if (_b.modelType.compareTo(p.targetInfo.modelType) > 0) {
              _writeln('await ${p.beanInstanceName}.attach(model, child);');
            } else {
              _writeln('await ${p.beanInstanceName}.attach(child, model);');
            }
            _writeln('}');
          }
        }
        _w.writeln('}');
      }
      _w.writeln('}');

      _w.writeln('return ret;');
      _w.writeln('}');
      return;
    }

    _w.writeln('Future<Null> insert(${_b
              .modelType} model, {bool cascade: false}) async {');
    _w.write('final Insert insert = inserter');
    _w.writeln('.setMany(toSetColumns(model));');
    _w.writeln('await execInsert(insert);');

    _w.writeln('if(cascade) {');
    _w.writeln('${_b.modelType} newModel;');
    for (Preload p in _b.preloads) {
      _w.writeln('if(model.${p.property} != null) {');
      _w.writeln('newModel ??= await find(');
      _write(_b.primary.map((f) {
        return 'model.${f.field}';
      }).join(','));
      _writeln(');');

      if (!p.hasMany) {
        _write(_uncap(p.beanInstanceName));
        _writeln(
            '.associate${_b.modelType}(model.' + p.property + ', newModel);');
        _write('await ' +
            _uncap(p.beanInstanceName) +
            '.insert(model.' +
            p.property +
            ');');
      } else {
        if (p is PreloadOneToX) {
          _write('model.' + p.property + '.forEach((x) => ');
          _write(_uncap(p.beanInstanceName));
          _writeln('.associate${_b.modelType}(x, newModel));');
          _writeln('for(final child in model.${p.property}) {');
          _writeln('await ' + _uncap(p.beanInstanceName) + '.insert(child);');
          _writeln('}');
        } else if (p is PreloadManyToMany) {
          _writeln('for(final child in model.${p.property}) {');
          _writeln('await ${p.targetBeanInstanceName}.insert(child);');
          if (_b.modelType.compareTo(p.targetInfo.modelType) > 0) {
            _writeln('await ${p.beanInstanceName}.attach(model, child);');
          } else {
            _writeln('await ${p.beanInstanceName}.attach(child, model);');
          }
          _writeln('}');
        }
      }
      _w.writeln('}');
    }
    _w.writeln('}');
    _w.writeln('}');
  }

  void _writeUpdate() {
    if (_b.primary.length == 0) return;

    if (_b.preloads.length == 0) {
      _w.writeln('Future<int> update(${_b.modelType} model) async {');
      _w.write('final Update update = updater.');
      final String wheres = _b.primary
          .map((Field f) => 'where(this.${f.field}.eq(model.${f.field}))')
          .join('.');
      _w.write(wheres);
      _w.writeln('.setMany(toSetColumns(model));');
      _w.writeln('return execUpdate(update);');
      _w.writeln('}');
      return;
    }

    _w.writeln(
        'Future<int> update(${_b.modelType} model, {bool cascade: false, bool associate: false}) async {');
    _w.write('final Update update = updater.');
    final String wheres = _b.primary
        .map((Field f) => 'where(this.${f.field}.eq(model.${f.field}))')
        .join('.');
    _w.write(wheres);
    _w.writeln('.setMany(toSetColumns(model));');
    _w.writeln('final ret = execUpdate(update);');

    _w.writeln('if(cascade) {');
    _w.writeln('${_b.modelType} newModel;');
    for (Preload p in _b.preloads) {
      _w.writeln('if(model.${p.property} != null) {');
      if (p is PreloadOneToX) {
        _writeln('if(associate) {');
        _w.writeln('newModel ??= await find(');
        _write(_b.primary.map((f) {
          return 'model.${f.field}';
        }).join(','));
        _writeln(');');

        if (!p.hasMany) {
          _write(_uncap(p.beanInstanceName));
          _writeln(
              '.associate${_b.modelType}(model.' + p.property + ', newModel);');
        } else {
          _write('model.' + p.property + '.forEach((x) => ');
          _write(_uncap(p.beanInstanceName));
          _writeln('.associate${_b.modelType}(x, newModel));');
        }
        _writeln('}');
      }

      if (!p.hasMany) {
        _write('await ' +
            _uncap(p.beanInstanceName) +
            '.update(model.' +
            p.property +
            ');');
      } else {
        _writeln('for(final child in model.${p.property}) {');
        if (p is PreloadOneToX) {
          _writeln('await ' + _uncap(p.beanInstanceName) + '.update(child);');
        } else if (p is PreloadManyToMany) {
          _writeln('await ');
          _writeln('await ${p.targetBeanInstanceName}.update(child);');
        }
        _writeln('}');
      }
      _w.writeln('}');
    }
    _w.writeln('}');

    _w.writeln('return ret;');
    _w.writeln('}');
  }

  void _writeFind() {
    if (_b.primary.length == 0) return;

    _write('Future<${_b.modelType}> find(');
    final String args =
        _b.primary.map((Field f) => '${f.type} ${f.field}').join(',');
    _write(args);
    _write(', {bool preload: false, bool cascade: false}');
    _writeln(') async {');
    _writeln('final Find find = finder.');
    final String wheres = _b.primary
        .map((Field f) => 'where(this.${f.field}.eq(${f.field}))')
        .join('.');
    _write(wheres);
    _writeln(';');

    if (_b.preloads.length > 0) {
      _writeln('final ${_b.modelType} model = await execFindOne(find);');
      _writeln('if (preload) {');
      _writeln('await this.preload(model, cascade: cascade);');
      _writeln('}');
      _writeln('return model;');
    } else {
      _writeln('return await execFindOne(find);');
    }
    _writeln('}');
  }

  void _writeFindWhere() {
    _writeln('Future<List<${_b.modelType}>> findWhere(Expression exp) async {');
    _writeln('final Find find = finder.where(exp);');
    _writeln('return await(await execFind(find)).toList();');
    _writeln('}');
  }

  void _writeRemove() {
    if (_b.primary.length == 0) return;

    if (_b.preloads.length == 0) {
      _w.writeln('Future<int> remove(');
      final String args =
          _b.primary.map((Field f) => '${f.type} ${f.field}').join(',');
      _w.write(args);
      _w.writeln(') async {');
      _w.writeln('final Remove remove = remover.');
      final String wheres = _b.primary
          .map((Field f) => 'where(this.${f.field}.eq(${f.field}))')
          .join('.');
      _w.write(wheres);
      _w.writeln(';');
      _w.writeln('return execRemove(remove);');
      _w.writeln('}');
      return;
    }

    _w.writeln('Future<int> remove(');
    final String args =
        _b.primary.map((Field f) => '${f.type} ${f.field}').join(',');
    _w.write(args);
    _w.writeln(', [bool cascade = false]) async {');

    _writeln('if (cascade) {');
    _w.writeln('${_b.modelType} newModel;');
    for (Preload p in _b.preloads) {
      if (p is PreloadOneToX) {
        _write(
            'await ' + p.beanInstanceName + '.removeBy' + _b.modelType + '(');
        _write(p.fields.map((f) => f.field).join(', '));
        _writeln(');');
      } else if (p is PreloadManyToMany) {
        _w.writeln('newModel ??= await find(');
        _write(_b.primary.map((f) {
          return '${f.field}';
        }).join(','));
        _writeln(');');
        _write('await ${p.beanInstanceName}.detach${_b.modelType}(newModel);');
      }
    }
    _writeln('}');

    _w.writeln('final Remove remove = remover.');
    final String wheres = _b.primary
        .map((Field f) => 'where(this.${f.field}.eq(${f.field}))')
        .join('.');
    _w.write(wheres);
    _w.writeln(';');
    _w.writeln('return execRemove(remove);');
    _w.writeln('}');
  }

  void _writeGetOneByForeign(FindByForeignBean m) {
    if (!m.isMany) {
      _w.write('Future<${_b.modelType}>');
    } else {
      _w.write('Future<List<${_b.modelType}>>');
    }
    _w.write(' findBy${_cap(m.modelName)}(');
    final String args =
        m.fields.map((Field f) => '${f.type} ${f.field}').join(',');
    _w.write(args);
    _write(', {bool preload: false, bool cascade: false}');
    _w.writeln(') async {');

    _w.writeln('final Find find = finder.');
    final String wheres = m.fields
        .map((Field f) => 'where(this.${f.field}.eq(${f.field}))')
        .join('.');
    _w.write(wheres);
    _w.writeln(';');

    if (_b.preloads.length > 0) {
      if (!m.isMany) {
        _write('final ${_b.modelType} model = await ');
        _writeln('execFindOne(find);');

        _writeln('if (preload) {');
        _writeln('await this.preload(model, cascade: cascade);');
        _writeln('}');

        _writeln('return model;');
      } else {
        _write('final List<${_b.modelType}> models = await ');
        _writeln('( await execFind(find)).toList();');

        _writeln('if (preload) {');
        _writeln('await this.preloadAll(models, cascade: cascade);');
        _writeln('}');

        _writeln('return models;');
      }
    } else {
      _write('return await ');
      if (!m.isMany) {
        _writeln('execFindOne(find);');
      } else {
        _writeln('( await execFind(find)).toList();');
      }
    }

    _w.writeln('}');
  }

  void _writeRemoveMany() {
    if (_b.primary.length == 0) return;

    _w.writeln('Future<int> removeMany(List<${_b.modelType}> models) async {');
    _w.writeln('final Remove remove = remover;');
    _writeln('for(final model in models) {');
    _write('remove.or(');
    final String wheres = _b.primary
        .map((Field f) => 'this.${f.field}.eq(model.${f.field})')
        .join('|');
    _w.write(wheres);
    _writeln(');');
    _w.writeln('}');
    _w.writeln('return execRemove(remove);');
    _w.writeln('}');
    return;
  }

  void _writeRemoveWhere() {
    _w.writeln('Future<int> removeWhere(Expression exp) async {');
    _w.writeln('return execRemove(remover.where(exp));');
    _w.writeln('}');
    return;
  }

  void _removeByForeign(FindByForeignBean m) {
    _w.write('Future<int>');
    _w.write(' removeBy${_cap(m.modelName)}(');
    final String args =
        m.fields.map((Field f) => '${f.type} ${f.field}').join(',');
    _w.write(args);
    _w.writeln(') async {');

    _w.writeln('final Remove rm = remover.');
    final String wheres = m.fields
        .map((Field f) => 'where(this.${f.field}.eq(${f.field}))')
        .join('.');
    _w.write(wheres);
    _w.writeln(';');

    _write('return await execRemove(rm);');
    _w.writeln('}');
  }

  void _writeFindByForeignList(FindByForeignBean m) {
    _write('Future<List<${_b.modelType}>> findBy${_cap(m.modelName)}List(');
    _write('List<${m.modelName}> models');
    _write(', {bool preload: false, bool cascade: false}');
    _writeln(') async {');

    _writeln('final Find find = finder;');
    _writeln('for (${m.modelName} model in models) {');
    _write('find.or(');
    final wheres = <String>[];
    for (int i = 0; i < m.fields.length; i++) {
      wheres.add(
          'this.${m.fields[i].field}.eq(model.${m.foreignFields[i].field})');
    }
    _w.write(wheres.join(' & '));
    _writeln(');');
    _writeln('}');

    if (_b.preloads.length > 0) {
      _writeln(
          'final List<${_b.modelType}> retModels = await (await execFind(find)).toList();');
      _writeln('if (preload) {');
      _writeln('await this.preloadAll(retModels, cascade: cascade);');
      _writeln('}');
      _writeln('return retModels;');
    } else {
      _writeln('return await (await execFind(find)).toList();');
    }

    _w.writeln('}');
  }

  void _writePreload() {
    if (_b.preloads.length == 0) return;

    _writeln(
        'Future preload(${_b.modelType} model, {bool cascade: false}) async {');
    for (Preload p in _b.preloads) {
      _write('model.');
      _write(p.property);
      _write(' = await ');

      if (p is PreloadOneToX) {
        _write(_uncap(p.beanInstanceName));
        _write('.findBy');
        _write(_b.modelType);
        _write('(');
        final String args = p.foreignFields
            .map((Field f) => f.foreign.refCol)
            .map(_b.fieldByColName)
            .map((Field f) => 'model.${f.field}')
            .join(',');
        _write(args);
        _write(', preload: cascade, cascade: cascade');
        _writeln(');');
      } else if (p is PreloadManyToMany) {
        _write('${p.beanInstanceName}.fetchBy${_b.modelType}(model);');
      }
    }
    _writeln('}');
  }

  void _writePreloadAll() {
    if (_b.preloads.length == 0) return;

    _writeln(
        'Future preloadAll(List<${_b.modelType}> models, {bool cascade: false}) async {');
    for (Preload p in _b.preloads) {
      if (p is PreloadOneToX) {
        if (p.hasMany) {
          _writeln('models.forEach((${_b.modelType} model) => model.${p
                  .property} ??= []);');
        }

        _write('await PreloadHelper.');
        // Arg1: models
        _write('preload<${_b.modelType}, ${p.modelName}>(models, ');
        // Arg2: ParentGetter
        _write('(${_b.modelType} model) => [');
        {
          final String args = p.foreignFields
              .map((Field f) => f.foreign.refCol)
              .map(_b.fieldByColName)
              .map((Field f) => 'model.${f.field}')
              .join(',');
          _write(args);
        }
        _write('], ');
        //Arg3: function
        _write(_uncap(p.beanInstanceName));
        _write('.findBy');
        _write(_b.modelType);
        _write('List, ');
        //Arg4: ChildGetter
        _write('(${p.modelName} model) => [');
        {
          final String args =
              p.foreignFields.map((Field f) => 'model.${f.field}').join(',');
          _write(args);
        }
        _write('], ');
        //Arg5: Setter
        if (!p.hasMany) {
          _write('(${_b.modelType} model, ${p.modelName} child) => model.${p
              .property} = child, ');
        } else {
          _write('(${_b.modelType} model, ${p.modelName} child) => model.${p
                  .property}.add(child), ');
        }
        _writeln('cascade: cascade);');
      }
    }
    _writeln('}');
  }

  void _writePreloadBeans() {
    for (Preload p in _b.preloads) {
      _write(p.beanName);
      _write(' get ');
      _write(p.beanInstanceName);
      _writeln(';');
      if (p is PreloadManyToMany) {
        _writeln('');
        _write(p.targetBeanName);
        _write(' get ');
        _write(p.targetBeanInstanceName);
        _writeln(';');
      }
    }

    for (FindByForeignBean f in _b.getByForeign.values) {
      if (f.belongsToMany) {
        _write(f.beanName);
        _write(' get ');
        _write(f.beanInstanceName);
        _writeln(';');
      }
    }
  }

  void _writeAssociate(FindByForeignBean m) {
    _write('void associate${_cap(m.modelName)}(');
    _write('${_b.modelType} child, ');
    _write('${m.modelName} parent');
    _writeln(') {');

    for (int i = 0; i < m.fields.length; i++) {
      _writeln(
          'child.${m.fields[i].field} = parent.${m.foreignFields[i].field};');
    }

    _writeln('}');
  }

  void _writeDetach(FindByForeignBean m) {
    _writeln(
        'Future<int> detach${_cap(m.modelName)}(${_cap(m.modelName)} model) async {');
    _write('final dels = await findBy${_cap(m.modelName)}(');
    _write(m.foreignFields.map((f) => 'model.' + f.field).join(', '));
    _writeln(');');
    _write('await removeBy${_cap(m.modelName)}(');
    _write(m.foreignFields.map((f) => 'model.' + f.field).join(', '));
    _writeln(');');
    final String beanName =
        (m.other as PreloadManyToMany).targetBeanInstanceName;
    _writeln('final exp = new Or();');
    _writeln('for(final t in dels) {');
    _write('exp.or(');
    FindByForeignBean o = _b.getMatchingManyToMany(m);
    for (int i = 0; i < o.fields.length; i++) {
      _write(
          '$beanName.${o.foreignFields[i].field}.eq(t.${o.fields[i].field}),');
    }
    _writeln(');');
    _writeln('}');

    _write('return await $beanName.removeWhere(exp);');
    _writeln('}');
  }

  void _writeFetchOther(FindByForeignBean m) {
    final String beanName =
        (m.other as PreloadManyToMany).targetBeanInstanceName;
    final String targetModel = (m.other as PreloadManyToMany).targetModelName;
    _writeln(
        'Future<List<$targetModel>> fetchBy${_cap(m.modelName)}(${_cap(m.modelName)} model) async {');
    _write('final pivots = await findBy${_cap(m.modelName)}(');
    _write(m.foreignFields.map((f) => 'model.' + f.field).join(', '));
    _writeln(');');
    _writeln('final exp = new Or();');
    _writeln('for(final t in pivots) {');
    _write('exp.or(');
    FindByForeignBean o = _b.getMatchingManyToMany(m);
    for (int i = 0; i < o.fields.length; i++) {
      _write(
          '$beanName.${o.foreignFields[i].field}.eq(t.${o.fields[i].field}),');
    }
    _writeln(');');
    _writeln('}');

    _write('return await $beanName.findWhere(exp);');
    _writeln('}');
  }

  void _writeAttach() {
    final FindByForeignBean m = _b.getByForeign.values.firstWhere(
        (FindByForeign f) => f is FindByForeignBean && f.belongsToMany,
        orElse: () => null);
    if (m == null) return;

    final FindByForeignBean m1 = _b.getMatchingManyToMany(m);

    _writeln('Future<dynamic> attach(');
    if (m.modelName.compareTo(m1.modelName) > 0) {
      _write('${m.modelName} one, ${m1.modelName} two');
    } else {
      _write('${m1.modelName} one, ${_cap(m.modelName)} two');
    }
    _writeln(') async {');
    _writeln('final ret = new ${_b.modelType}();');

    if (m.modelName.compareTo(m1.modelName) > 0) {
      for (int i = 0; i < m.fields.length; i++) {
        _writeln('ret.${m.fields[i].field} = one.${m.foreignFields[i].field};');
      }
      for (int i = 0; i < m1.fields.length; i++) {
        _writeln(
            'ret.${m1.fields[i].field} = two.${m1.foreignFields[i].field};');
      }
    } else {
      for (int i = 0; i < m1.fields.length; i++) {
        _writeln(
            'ret.${m1.fields[i].field} = one.${m1.foreignFields[i].field};');
      }
      for (int i = 0; i < m.fields.length; i++) {
        _writeln('ret.${m.fields[i].field} = two.${m.foreignFields[i].field};');
      }
    }
    _writeln('return insert(ret);');
    _writeln('}');
  }

  void _write(String str) => _w.write(str);

  void _writeln(String str) => _w.writeln(str);
}

String _cap(String str) => str.substring(0, 1).toUpperCase() + str.substring(1);

String _uncap(String str) =>
    str.substring(0, 1).toLowerCase() + str.substring(1);
