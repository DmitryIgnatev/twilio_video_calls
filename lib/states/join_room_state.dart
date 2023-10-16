import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
part 'join_room_state.g.dart'; //This will automatically generated after: flutter pub run build_runner build

@singleton
class JoinRoomState = JoinRoomStateBase with _$JoinRoomState;

abstract class JoinRoomStateBase with Store {
  @observable
  String name = '';
  @observable
  String token = '';
  @observable
  String identity = '';
}
