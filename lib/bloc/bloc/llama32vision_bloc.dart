import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meta/meta.dart';
import 'package:dio/dio.dart';
part 'llama32vision_event.dart';
part 'llama32vision_state.dart';

class Llama32visionBloc extends Bloc<Llama32visionEvent, Llama32visionState> {
  Llama32visionBloc() : super(Llama32visionInitial()) {
    on<FetchResponseFromPrompt>((event, emit) async {
      emit(Llama32visionLoading());

      final token = await getAccessToken();

      try {
        const image_url = ("https://raw.githubusercontent.com/meta-llama/"
            "llama-models/refs/heads/main/Llama_Repo.jpeg");
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              // Add a custom header to the request
              options.headers['Content-Type'] = 'application/json';
              options.headers['Authorization'] = 'Bearer $token';
              return handler.next(options);
            },
          ),
        );

        //  "content": [
        //         {"type": "text", "text": "describe the image in one sentence"},
        //         {
        //           "type": "image_url",
        //           "image_url": {"url": image_url}
        //         }
        //       ]

        final response = await dio.post(
          'https://api.groq.com/openai/v1/chat/completions',
          data: {
            // 'messages': [
            //   {"role": "user", "content": event.promptText}
            // ],
            'messages': [
              {
                "role": "user",
                "content": [
                  {"type": "text", "text": event.promptText},
                  {
                    "type": "image_url",
                    "image_url": {"url": event.imageURL}
                  }
                ]
              }
            ],
            'model': "llama-3.2-11b-vision-preview",
            'temperature': 1,
            'max_tokens': 1024,
            'top_p': 1,
            'stream': false,
            'stop': null
          },
        );

        //Chain the response and use light weight llama
        final finalResponse = await dio.post(
          'https://api.groq.com/openai/v1/chat/completions',
          data: {
            'messages': [
              {"role": "user", "content": 'Suggest 4-5 alternatives medicines of ${response.data['choices'][0]['message']['content']}'}
            ],
            'model': "llama-3.2-3b-preview",
            'temperature': 1,
            'max_tokens': 1024,
            'top_p': 1,
            'stream': false,
            'stop': null
          },
        );

        //print('Response is ${finalResponse.data['choices'][0]['message']['content']}');
        //Emit the final response

        emit(Llama32visionSuccess(finalResponse.data['choices'][0]['message']['content'] ?? ""));
      } catch (e) {
        emit(Llama32visionFailure());
      }
    });
  }

  Future<String> getAccessToken() async {
    final token = '${dotenv.env['GROQ_API_KEY']}';
    return token;
  }
}
