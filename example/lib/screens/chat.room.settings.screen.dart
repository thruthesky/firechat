import 'package:firechat/firechat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatRoomSettingsScreen extends StatefulWidget {
  ChatRoomSettingsScreen({
    this.chatRoom,
    Key key,
  }) : super(key: key);

  final ChatGlobalRoom chatRoom;

  @override
  _ChatRoomSettingsScreenState createState() => _ChatRoomSettingsScreenState();
}

class _ChatRoomSettingsScreenState extends State<ChatRoomSettingsScreen> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textController.text = widget.chatRoom.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ChatRoom Settings'),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text('Chat Room Title'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: "Please enter room title.",
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    print('Save Title');
                    print(textController.text);
                    try {
                      await ChatRoom.instance.updateTitle(textController.text);
                    } catch (e) {
                      print('updating title failed');
                      print(e);
                    }
                  },
                  icon: Icon(Icons.save),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
