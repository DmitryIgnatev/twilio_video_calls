import 'package:twilio_video_calls/conference/conference_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twilio_video_calls/di.dart';
import 'package:twilio_video_calls/room/join_room_cubit.dart';
import 'package:twilio_video_calls/shared/twilio_service.dart';
import 'package:twilio_video_calls/states/conference_state.dart';

class JoinRoomPage extends StatelessWidget {
  final conferenceState = serviceLocator<ConferenceState>();
  final TextEditingController _nameController = TextEditingController();

  JoinRoomPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: BlocProvider(
            create: (context) =>
                RoomCubit(backendService: TwilioFunctionsService.instance),
            child: BlocConsumer<RoomCubit, RoomState>(
                listener: (context, state) async {
              if (state is RoomLoaded) {
                await Navigator.of(context).push(
                  MaterialPageRoute<ConferencePage>(
                      fullscreenDialog: true,
                      builder: (BuildContext context) {
                        conferenceState.name = state.name;
                        conferenceState.identity = state.identity;
                        conferenceState.token = state.token;
                        conferenceState.connect();
                        return ConferencePage();
                      }),
                );
              }
            }, builder: (context, state) {
              var isLoading = false;
              RoomCubit bloc = context.read<RoomCubit>();
              if (state is RoomLoading) {
                isLoading = true;
              }

              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              key: const Key('enter-name'),
                              decoration: InputDecoration(
                                labelText: 'Enter your name',
                                enabled: !isLoading,
                              ),
                              controller: _nameController,
                              onChanged: (newValue) =>
                                  context.read<RoomCubit>().name = newValue,
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                            (isLoading == true)
                                ? const LinearProgressIndicator()
                                : ElevatedButton(
                                    onPressed: () async {
                                      await bloc.submit();
                                    },
                                    child: const Text('Enter the room')),
                            (state is RoomError)
                                ? Text(
                                    state.error,
                                    style: const TextStyle(color: Colors.red),
                                  )
                                : Container(),
                            const SizedBox(
                              height: 16,
                            ),
                          ],
                        ),
                      )
                    ]),
              );
            }),
          ),
        ),
      ),
    );
  }
}
