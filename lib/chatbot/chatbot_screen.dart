import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_model.dart';
import 'chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  final String cid;
  final String uid;
  final String name;
  final String branchName;

  const ChatbotScreen({
    super.key,
    required this.cid,
    required this.uid,
    required this.name,
    required this.branchName,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  Timer? timer;
  List<ChatModel> messages = [];
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 2),
          (timer) {
        loadMessages();
      },
    );
    loadMessages();
  }
  Future<void> loadMessages() async {

    messages = await ChatService.getMessages(widget.cid);

    setState(() {});
  }
  @override
  void dispose() {

    timer?.cancel();

    messageController.dispose();

    scrollController.dispose();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icon color
        ),
        backgroundColor: Colors.blue,
        title: const Text("Group Chat",style: TextStyle(
            color: Colors.white,
            fontSize: 18,fontFamily: 'impact')),
      ),
      body: SafeArea(
        child: Column(
          children: [

            /// Message List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  bool isMe = msg.uid == widget.uid;
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(
                        maxWidth:
                        MediaQuery.of(context).size.width * .75,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.green.shade200
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          /// Username Top Right
                          Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              "${msg.username} (${msg.branchname})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 11,
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            msg.message,
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 5),

                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              msg.createdAt,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// Bottom Message Box
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type message...",
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.send),
                        onPressed: () async {

                          if(messageController.text.trim().isEmpty){
                            return;
                          }

                          bool success = await ChatService.sendMessage(

                            cid: widget.cid,
                            uid: widget.uid,
                            username: widget.name,
                            branchname: widget.branchName,
                            message: messageController.text.trim(),

                          );

                          if(success){

                            messageController.clear();

                            await loadMessages();

                          }

                        }
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}