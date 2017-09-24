// Copyright (c) 2017, teja. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library example.many_to_many;

import 'dart:async';
import 'package:jaguar_query/jaguar_query.dart';
import 'package:jaguar_orm/jaguar_orm.dart';
import 'package:jaguar_orm/src/relations/relations.dart';

part 'many_to_many.g.dart';

class Category {
  @PrimaryKey()
  String catid;

  String name;

  @ManyToMany(CategoryTodolistBean, TodoListBean)
  List<TodoList> todolists;

  static const String tableName = 'category';

  String toString() => "Category($catid, $name, $todolists)";
}

class TodoList {
  @PrimaryKey()
  String todid;

  String name;

  String description;

  @ManyToMany(CategoryTodolistBean, CategoryBean)
  List<Category> categories;

  static String tableName = 'todolist';

  String toString() => "Post($todid, $name, $description, $categories)";
}

class CategoryTodolist {
  @BelongsToMany(TodoListBean, refCol: 'todid')
  String todolist_id;

  @BelongsToMany(CategoryBean, refCol: 'catid')
  String category_id;

  static String tableName = 'category_todolist';
}

@GenBean()
class TodoListBean extends Bean<TodoList> with _TodoListBean {
  final CategoryTodolistBean categoryTodolistBean;

  final CategoryBean categoryBean;

  TodoListBean(Adapter adapter)
      : categoryTodolistBean = new CategoryTodolistBean(adapter),
        categoryBean = new CategoryBean(adapter),
        super(adapter);

  Future createTable() {
    final st = Sql
        .create(tableName)
        .addStr('id', primary: true, length: 50)
        .addStr('name', length: 50);
    return execCreateTable(st);
  }
}

@GenBean()
class CategoryBean extends Bean<Category> with _CategoryBean {
  final CategoryTodolistBean categoryTodolistBean;

  final TodoListBean todoListBean;

  CategoryBean(Adapter adapter)
      : categoryTodolistBean = new CategoryTodolistBean(adapter),
        todoListBean = new TodoListBean(adapter),
        super(adapter);

  Future createTable() {
    final st = Sql
        .create(tableName)
        .addStr('id', primary: true, length: 50)
        .addStr('street', length: 150)
        .addStr('userid', length: 50, foreignTable: '_user', foreignCol: 'id');
    return execCreateTable(st);
  }
}

@GenBean()
class CategoryTodolistBean extends Bean<CategoryTodolist>
    with _CategoryTodolistBean {
  final CategoryBean categoryBean;

  final TodoListBean todoListBean;

  CategoryTodolistBean(Adapter adapter)
      : categoryBean = new CategoryBean(adapter),
        todoListBean = new TodoListBean(adapter),
        super(adapter);

  Future createTable() {
    final st = Sql
        .create(tableName)
        .addStr('id', primary: true, length: 50)
        .addStr('street', length: 150)
        .addStr('userid', length: 50, foreignTable: '_user', foreignCol: 'id');
    return execCreateTable(st);
  }
}
