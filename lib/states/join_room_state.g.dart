// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_room_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$JoinRoomState on JoinRoomStateBase, Store {
  late final _$nameAtom =
      Atom(name: 'JoinRoomStateBase.name', context: context);

  @override
  String get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(String value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  late final _$tokenAtom =
      Atom(name: 'JoinRoomStateBase.token', context: context);

  @override
  String get token {
    _$tokenAtom.reportRead();
    return super.token;
  }

  @override
  set token(String value) {
    _$tokenAtom.reportWrite(value, super.token, () {
      super.token = value;
    });
  }

  late final _$identityAtom =
      Atom(name: 'JoinRoomStateBase.identity', context: context);

  @override
  String get identity {
    _$identityAtom.reportRead();
    return super.identity;
  }

  @override
  set identity(String value) {
    _$identityAtom.reportWrite(value, super.identity, () {
      super.identity = value;
    });
  }

  @override
  String toString() {
    return '''
name: ${name},
token: ${token},
identity: ${identity}
    ''';
  }
}
