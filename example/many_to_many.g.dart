// GENERATED CODE - DO NOT MODIFY BY HAND

part of example.many_to_many;

// **************************************************************************
// Generator: BeanGenerator
// **************************************************************************

abstract class _TodoListBean implements Bean<TodoList> {
  String get tableName => TodoList.tableName;

  final StrField todid = new StrField('todid');

  final StrField name = new StrField('name');

  final StrField description = new StrField('description');

  TodoList fromMap(Map map) {
    TodoList model = new TodoList();

    model.todid = map['todid'];
    model.name = map['name'];
    model.description = map['description'];

    return model;
  }

  List<SetColumn> toSetColumns(TodoList model, [bool update = false]) {
    List<SetColumn> ret = [];

    ret.add(todid.set(model.todid));
    ret.add(name.set(model.name));
    ret.add(description.set(model.description));

    return ret;
  }

  Future<Null> insert(TodoList model, {bool cascade: false}) async {
    final Insert insert = inserter.setMany(toSetColumns(model));
    await execInsert(insert);
    if (cascade) {
      TodoList newModel;
      if (model.categories != null) {
        newModel ??= await find(model.todid);
        for (final child in model.categories) {
          await categoryBean.insert(child);
          await categoryTodolistBean.attach(model, child);
        }
      }
    }
  }

  Future<int> update(TodoList model,
      {bool cascade: false, bool associate: false}) async {
    final Update update =
        updater.where(this.todid.eq(model.todid)).setMany(toSetColumns(model));
    final ret = execUpdate(update);
    if (cascade) {
      TodoList newModel;
      if (model.categories != null) {
        for (final child in model.categories) {
          await await categoryBean.update(child);
        }
      }
    }
    return ret;
  }

  Future<TodoList> find(String todid,
      {bool preload: false, bool cascade: false}) async {
    final Find find = finder.where(this.todid.eq(todid));
    final TodoList model = await execFindOne(find);
    if (preload) {
      await this.preload(model, cascade: cascade);
    }
    return model;
  }

  Future<List<TodoList>> findWhere(Expression exp) async {
    final Find find = finder.where(exp);
    return await (await execFind(find)).toList();
  }

  Future<int> remove(String todid, [bool cascade = false]) async {
    if (cascade) {
      TodoList newModel;
      newModel ??= await find(todid);
      await categoryTodolistBean.detachTodoList(newModel);
    }
    final Remove remove = remover.where(this.todid.eq(todid));
    return execRemove(remove);
  }

  Future<int> removeMany(List<TodoList> models) async {
    final Remove remove = remover;
    for (final model in models) {
      remove.or(this.todid.eq(model.todid));
    }
    return execRemove(remove);
  }

  Future<int> removeWhere(Expression exp) async {
    return execRemove(remover.where(exp));
  }

  Future preload(TodoList model, {bool cascade: false}) async {
    model.categories = await categoryTodolistBean.fetchByTodoList(model);
  }

  Future preloadAll(List<TodoList> models, {bool cascade: false}) async {}
  CategoryTodolistBean get categoryTodolistBean;

  CategoryBean get categoryBean;
}

abstract class _CategoryBean implements Bean<Category> {
  String get tableName => Category.tableName;

  final StrField catid = new StrField('catid');

  final StrField name = new StrField('name');

  Category fromMap(Map map) {
    Category model = new Category();

    model.catid = map['catid'];
    model.name = map['name'];

    return model;
  }

  List<SetColumn> toSetColumns(Category model, [bool update = false]) {
    List<SetColumn> ret = [];

    ret.add(catid.set(model.catid));
    ret.add(name.set(model.name));

    return ret;
  }

  Future<Null> insert(Category model, {bool cascade: false}) async {
    final Insert insert = inserter.setMany(toSetColumns(model));
    await execInsert(insert);
    if (cascade) {
      Category newModel;
      if (model.todolists != null) {
        newModel ??= await find(model.catid);
        for (final child in model.todolists) {
          await todoListBean.insert(child);
          await categoryTodolistBean.attach(child, model);
        }
      }
    }
  }

  Future<int> update(Category model,
      {bool cascade: false, bool associate: false}) async {
    final Update update =
        updater.where(this.catid.eq(model.catid)).setMany(toSetColumns(model));
    final ret = execUpdate(update);
    if (cascade) {
      Category newModel;
      if (model.todolists != null) {
        for (final child in model.todolists) {
          await await todoListBean.update(child);
        }
      }
    }
    return ret;
  }

  Future<Category> find(String catid,
      {bool preload: false, bool cascade: false}) async {
    final Find find = finder.where(this.catid.eq(catid));
    final Category model = await execFindOne(find);
    if (preload) {
      await this.preload(model, cascade: cascade);
    }
    return model;
  }

  Future<List<Category>> findWhere(Expression exp) async {
    final Find find = finder.where(exp);
    return await (await execFind(find)).toList();
  }

  Future<int> remove(String catid, [bool cascade = false]) async {
    if (cascade) {
      Category newModel;
      newModel ??= await find(catid);
      await categoryTodolistBean.detachCategory(newModel);
    }
    final Remove remove = remover.where(this.catid.eq(catid));
    return execRemove(remove);
  }

  Future<int> removeMany(List<Category> models) async {
    final Remove remove = remover;
    for (final model in models) {
      remove.or(this.catid.eq(model.catid));
    }
    return execRemove(remove);
  }

  Future<int> removeWhere(Expression exp) async {
    return execRemove(remover.where(exp));
  }

  Future preload(Category model, {bool cascade: false}) async {
    model.todolists = await categoryTodolistBean.fetchByCategory(model);
  }

  Future preloadAll(List<Category> models, {bool cascade: false}) async {}
  CategoryTodolistBean get categoryTodolistBean;

  TodoListBean get todoListBean;
}

abstract class _CategoryTodolistBean implements Bean<CategoryTodolist> {
  String get tableName => CategoryTodolist.tableName;

  final StrField todolist_id = new StrField('todolist_id');

  final StrField category_id = new StrField('category_id');

  CategoryTodolist fromMap(Map map) {
    CategoryTodolist model = new CategoryTodolist();

    model.todolist_id = map['todolist_id'];
    model.category_id = map['category_id'];

    return model;
  }

  List<SetColumn> toSetColumns(CategoryTodolist model, [bool update = false]) {
    List<SetColumn> ret = [];

    ret.add(todolist_id.set(model.todolist_id));
    ret.add(category_id.set(model.category_id));

    return ret;
  }

  Future<dynamic> insert(CategoryTodolist model) async {
    final Insert insert = inserter.setMany(toSetColumns(model));
    return execInsert(insert);
  }

  Future<List<CategoryTodolist>> findWhere(Expression exp) async {
    final Find find = finder.where(exp);
    return await (await execFind(find)).toList();
  }

  Future<int> removeWhere(Expression exp) async {
    return execRemove(remover.where(exp));
  }

  Future<List<CategoryTodolist>> findByTodoList(String todolist_id,
      {bool preload: false, bool cascade: false}) async {
    final Find find = finder.where(this.todolist_id.eq(todolist_id));
    return await (await execFind(find)).toList();
  }

  Future<List<CategoryTodolist>> findByCategory(String category_id,
      {bool preload: false, bool cascade: false}) async {
    final Find find = finder.where(this.category_id.eq(category_id));
    return await (await execFind(find)).toList();
  }

  Future<int> removeByTodoList(String todolist_id) async {
    final Remove rm = remover.where(this.todolist_id.eq(todolist_id));
    return await execRemove(rm);
  }

  Future<int> removeByCategory(String category_id) async {
    final Remove rm = remover.where(this.category_id.eq(category_id));
    return await execRemove(rm);
  }

  Future<List<CategoryTodolist>> findByTodoListList(List<TodoList> models,
      {bool preload: false, bool cascade: false}) async {
    final Find find = finder;
    for (TodoList model in models) {
      find.or(this.todolist_id.eq(model.todid));
    }
    return await (await execFind(find)).toList();
  }

  Future<List<CategoryTodolist>> findByCategoryList(List<Category> models,
      {bool preload: false, bool cascade: false}) async {
    final Find find = finder;
    for (Category model in models) {
      find.or(this.category_id.eq(model.catid));
    }
    return await (await execFind(find)).toList();
  }

  void associateTodoList(CategoryTodolist child, TodoList parent) {
    child.todolist_id = parent.todid;
  }

  void associateCategory(CategoryTodolist child, Category parent) {
    child.category_id = parent.catid;
  }

  Future<int> detachTodoList(TodoList model) async {
    final dels = await findByTodoList(model.todid);
    await removeByTodoList(model.todid);
    final exp = new Or();
    for (final t in dels) {
      exp.or(
        categoryBean.catid.eq(t.category_id),
      );
    }
    return await categoryBean.removeWhere(exp);
  }

  Future<int> detachCategory(Category model) async {
    final dels = await findByCategory(model.catid);
    await removeByCategory(model.catid);
    final exp = new Or();
    for (final t in dels) {
      exp.or(
        todoListBean.todid.eq(t.todolist_id),
      );
    }
    return await todoListBean.removeWhere(exp);
  }

  Future<List<Category>> fetchByTodoList(TodoList model) async {
    final pivots = await findByTodoList(model.todid);
    final exp = new Or();
    for (final t in pivots) {
      exp.or(
        categoryBean.catid.eq(t.category_id),
      );
    }
    return await categoryBean.findWhere(exp);
  }

  Future<List<TodoList>> fetchByCategory(Category model) async {
    final pivots = await findByCategory(model.catid);
    final exp = new Or();
    for (final t in pivots) {
      exp.or(
        todoListBean.todid.eq(t.todolist_id),
      );
    }
    return await todoListBean.findWhere(exp);
  }

  Future<dynamic> attach(TodoList one, Category two) async {
    final ret = new CategoryTodolist();
    ret.todolist_id = one.todid;
    ret.category_id = two.catid;
    return insert(ret);
  }

  TodoListBean get todoListBean;
  CategoryBean get categoryBean;
}
