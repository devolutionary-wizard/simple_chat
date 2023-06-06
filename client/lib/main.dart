import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyWidget(),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late io.Socket socket;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String username = "";
  String message = "";
  @override
  void initState() {
    init();
    super.initState();
  }

  init() {
    socket = io.io('http://192.168.0.131:3000',
        io.OptionBuilder().setTransports(['websocket']).build());
    socket.connect();
    socket.onConnect((_) {
      openUsernameDialog();
      debugPrint('connection established');
    });

    socket.on("messages", (messages) {
      List<Widget> chatMessages = [];
      for (var message in messages) {
        debugPrint(message);

        chatMessages.add(MessageWidget(
            username: message['username'],
            message: message['message'],
            timestamp: convertTimeStamp(message['created'])));
      }
      setState(() {
        chatMessages = chatMessages;
      });
    });

    socket.on("message", (message) {
      debugPrint('$message');
      setState(() {
        chatMessages = [
          ...chatMessages,
          MessageWidget(
              username: message['username'],
              message: message['message'],
              timestamp: convertTimeStamp(message['created']))
        ];
      });
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            curve: Curves.easeOut, duration: const Duration(milliseconds: 50));
      });
    });
  }

  List<Widget> chatMessages = [
    const Card(
      child: ListTile(
        leading: Text("23 Feb, 2023"),
        title: Text("SEANGLAY"),
        subtitle: Text(
          "Hello world, today is good day",
          style: TextStyle(fontSize: 14),
        ),
        isThreeLine: true,
      ),
    )
  ];
  String convertTimeStamp(int timestamp) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String convertedDateTime =
        "${dateTime.year.toString()}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}-${dateTime.minute.toString().padLeft(2, '0')}";
    return convertedDateTime;
  }

  Future openUsernameDialog() => showDialog(
      context: context,
      builder: ((context) => AlertDialog(
            title: const Text("Enter your name to Join Chat"),
            content: TextField(
              onChanged: (value) => username = value,
              decoration: const InputDecoration(hintText: "Enter your name"),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Join Chat"))
            ],
          )));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Real-Time Chat",
                          style: TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text("Dead Simple Chat",
                            style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: ListView(
                      controller: _scrollController, children: chatMessages),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 16),
                      child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: 'Chat Message',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  // Handle clear
                                  _textController.clear();
                                },
                              ))),
                    )),
                    GestureDetector(
                      onTap: () {
                        String message = _textController.text;
                        socket.emit("message",
                            {"username": username, "message": message});
                        _textController.clear();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget(
      {required this.username,
      required this.message,
      required this.timestamp,
      super.key});

  final String username;
  final String message;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(timestamp),
        title: Text(username),
        subtitle: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        isThreeLine: true,
      ),
    );
  }
}
