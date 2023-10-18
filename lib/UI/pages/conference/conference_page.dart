import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:twilio_video_calls/utils/di.dart';
import 'package:twilio_video_calls/states/conference_state.dart';

class ConferencePage extends StatelessWidget {
  ConferencePage({super.key});

  final conferenceState = serviceLocator<ConferenceState>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Observer(builder: (_) {
        if (conferenceState.mode == ConferenceMode.conferenceInitial) {
          debugPrint("\x1B[33mSTATE IS INITIAL\x1B[0m");
          return showProgress();
        }
        if (conferenceState.mode == ConferenceMode.conferenceLoaded) {
          debugPrint("\x1B[33mSTATE IS LOADED\x1B[0m");
          return Stack(
            children: <Widget>[
              const BuildParticipants(),
              Positioned(
                  bottom: 60,
                  child: SizedBox(
                    width: width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.call_end_sharp,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            conferenceState.disconnect();
                            Navigator.of(context).pop();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            conferenceState.isMicrophoneOn
                                ? Icons.mic
                                : Icons.mic_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            conferenceState.toggleAudioEnabled();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            conferenceState.isCameraOn
                                ? Icons.videocam
                                : Icons.videocam_off,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            conferenceState.toggleVideoEnabled();
                          },
                        ),
                      ],
                    ),
                  ))
            ],
          );
        }
        return Container();
      }),
    );
  }

  Widget showProgress() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Center(child: CircularProgressIndicator()),
        SizedBox(
          height: 10,
        ),
        Text(
          'Connecting to the room...',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

class BuildParticipants extends StatelessWidget {
  const BuildParticipants({super.key});

  @override
  Widget build(BuildContext context) {
    final conferenceState = serviceLocator<ConferenceState>();
    return Observer(builder: (_) {
      return Stack(children: [
        GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1),
            itemCount: conferenceState.participantsList.length,
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                children: [
                  conferenceState.participantsList[index].child,
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!conferenceState
                            .participantsList[index].videoEnabled)
                          const CircleAvatar(
                            maxRadius: 40,
                            backgroundColor: Colors.transparent,
                            child: FittedBox(
                              child: Icon(
                                Icons.videocam_off,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (!conferenceState
                            .participantsList[index].audioEnabled)
                          const CircleAvatar(
                            maxRadius: 40,
                            backgroundColor: Colors.transparent,
                            child: FittedBox(
                              child: Icon(
                                Icons.mic_off,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            })
      ]);
    });
  }
}
