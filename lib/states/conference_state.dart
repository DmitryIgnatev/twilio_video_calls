import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'dart:async';
import 'package:twilio_video_calls/conference/participant_widget.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:uuid/uuid.dart';
part 'conference_state.g.dart'; //This will automatically generated after: flutter pub run build_runner build

@singleton
class ConferenceState = ConferenceStateBase with _$ConferenceState;

enum ConferenceMode {
  /// Изначальное состояние
  conferenceInitial,

  /// Состояние, когда загружена конференция
  conferenceLoaded,
}

abstract class ConferenceStateBase with Store {
  @observable
  String name = "";
  @observable
  String token = "";
  @observable
  String identity = "";

  @observable
  ObservableList<ParticipantWidget> participantsList =
      ObservableList<ParticipantWidget>();

  @observable
  VideoCapturer? _cameraCapturer;
  @observable
  Room? _room;
  @observable
  String? trackId;

  @observable
  List<StreamSubscription> streamSubscriptions = [];

  @observable
  ConferenceMode? mode;

  @observable
  bool isMicrophoneOn = true;

  @action
  void setMode(ConferenceMode value) {
    mode = value;
  }

  @action
  void changeMicrophoneStatus() {
    debugPrint('[ APPDEBUG ] isMicropfoneOn = $isMicrophoneOn');
    isMicrophoneOn = !isMicrophoneOn;
  }

  @action
  ParticipantWidget _buildParticipant({
    required Widget child,
    required String? id,
  }) {
    return ParticipantWidget(
      id: id,
      child: child,
    );
  }

  @action
  connect() async {
    setMode(ConferenceMode.conferenceInitial);
    debugPrint('[ APPDEBUG ] ConferenceRoom.connect()');
    try {
      await TwilioProgrammableVideo.setAudioSettings(
          speakerphoneEnabled: true, bluetoothPreferred: false);

      var sources = await CameraSource.getSources();
      _cameraCapturer = CameraCapturer(
        sources.firstWhere((source) => source.isFrontFacing),
      );
      trackId = const Uuid().v4();

      var connectOptions = ConnectOptions(
        token,
        roomName: name,
        preferredAudioCodecs: [OpusCodec()],
        audioTracks: [LocalAudioTrack(isMicrophoneOn, 'audio_track-$trackId')],
        dataTracks: [
          LocalDataTrack(
            DataTrackOptions(name: 'data_track-$trackId'),
          )
        ],
        videoTracks: [LocalVideoTrack(true, _cameraCapturer!)],
        enableNetworkQuality: true,
        networkQualityConfiguration: NetworkQualityConfiguration(
          remote: NetworkQualityVerbosity.NETWORK_QUALITY_VERBOSITY_MINIMAL,
        ),
        enableDominantSpeaker: true,
      );

      _room = await TwilioProgrammableVideo.connect(connectOptions);
      if (_room != null) {
        streamSubscriptions.add(_room!.onConnected.listen(_onConnected));
        streamSubscriptions.add(_room!.onDisconnected.listen(_onDisconnected));
        streamSubscriptions.add(_room!.onReconnecting.listen(_onReconnecting));
        streamSubscriptions
            .add(_room!.onConnectFailure.listen(_onConnectFailure));
      }
    } catch (err) {
      debugPrint('[ APPDEBUG ] $err');
      rethrow;
    }
  }

  @action
  Future<void> disconnect() async {
    debugPrint('[ APPDEBUG ] ConferenceRoom.disconnect()');
    if (_room != null) {
      await _room!.disconnect();
    }
  }

  @action
  void _onConnected(Room room) {
    debugPrint(
        '[ APPDEBUG ] ConferenceRoom._onConnected => state: ${room.state}');

    // When connected for the first time, add remote participant listeners
    streamSubscriptions
        .add(_room!.onParticipantConnected.listen(_onParticipantConnected));
    streamSubscriptions.add(
        _room!.onParticipantDisconnected.listen(_onParticipantDisconnected));
    var localParticipant = room.localParticipant;
    if (localParticipant == null) {
      debugPrint(
          '[ APPDEBUG ] ConferenceRoom._onConnected => localParticipant is null');
      return;
    }

    // Only add ourselves when connected for the first time too.
    participantsList.add(_buildParticipant(
        child: localParticipant.localVideoTracks[0].localVideoTrack.widget(),
        id: identity));

    for (final remoteParticipant in room.remoteParticipants) {
      var participant = participantsList.firstWhereOrNull(
          (participant) => participant.id == remoteParticipant.sid);
      if (participant == null) {
        debugPrint(
            '[ APPDEBUG ] Adding participant that was already present in the room ${remoteParticipant.sid}, before I connected');
        _addRemoteParticipantListeners(remoteParticipant);
      }
    }
    reload();
  }

  @action
  void _onParticipantConnected(RoomParticipantConnectedEvent event) {
    debugPrint(
        '[ APPDEBUG ] ConferenceRoom._onParticipantConnected, ${event.remoteParticipant.sid}');
    _addRemoteParticipantListeners(event.remoteParticipant);
    reload();
  }

  @action
  void _onParticipantDisconnected(RoomParticipantDisconnectedEvent event) {
    debugPrint(
        '[ APPDEBUG ] ConferenceRoom._onParticipantDisconnected: ${event.remoteParticipant.sid}');
    participantsList.removeWhere(
        (ParticipantWidget p) => p.id == event.remoteParticipant.sid);
    reload();
  }

  @action
  void _addRemoteParticipantListeners(RemoteParticipant remoteParticipant) {
    streamSubscriptions.add(remoteParticipant.onVideoTrackSubscribed
        .listen(_addOrUpdateParticipant));
    streamSubscriptions.add(remoteParticipant.onAudioTrackSubscribed
        .listen(_addOrUpdateParticipant));
  }

  @action
  void _addOrUpdateParticipant(RemoteParticipantEvent event) {
    debugPrint(
        '[ APPDEBUG ] ConferenceRoom._addOrUpdateParticipant(), ${event.remoteParticipant.sid}');
    var participant = participantsList.firstWhereOrNull(
      (ParticipantWidget participant) =>
          participant.id == event.remoteParticipant.sid,
    );

    if (participant != null) {
      debugPrint(
          '[ APPDEBUG ] Participant found: ${participant.id}, updating A/V enabled values');
    } else {
      if (event is RemoteVideoTrackSubscriptionEvent) {
        debugPrint(
            '[ APPDEBUG ] New participant, adding: ${event.remoteParticipant.sid}');
        participantsList.insert(
          0,
          _buildParticipant(
            child: event.remoteVideoTrack.widget(),
            id: event.remoteParticipant.sid,
          ),
        );
        reload();
      }
    }
  }

  @action
  reload() {
    setMode(ConferenceMode.conferenceInitial);
    setMode(ConferenceMode.conferenceLoaded);
  }

  void _onConnectFailure(RoomConnectFailureEvent event) {
    debugPrint(
        '[ APPDEBUG ] ConferenceRoom._onConnectFailure: ${event.exception}');
  }

  void _onDisconnected(RoomDisconnectedEvent event) {
    debugPrint('[ APPDEBUG ] ConferenceRoom._onDisconnected');
  }

  void _onReconnecting(RoomReconnectingEvent room) {
    debugPrint('[ APPDEBUG ] ConferenceRoom._onReconnecting');
  }
}
