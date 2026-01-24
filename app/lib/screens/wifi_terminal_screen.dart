import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WiFiTerminalScreen extends StatefulWidget {
  final String deviceIp;

  const WiFiTerminalScreen({super.key, required this.deviceIp});

  @override
  State<WiFiTerminalScreen> createState() => _WiFiTerminalScreenState();
}

class _WiFiTerminalScreenState extends State<WiFiTerminalScreen> {
  late String _espIp;
  final TextEditingController _commandController = TextEditingController();
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _espIp = widget.deviceIp; // Using the IP passed from the previous screen
  }

  Future<void> _sendCustomCommand() async {
    String command = _commandController.text.trim();
    if (command.isEmpty) return;

    // Assumes your ESP handles queries like: http://192.168.x.x/cmd?query=your_command
    // OR simply: http://192.168.x.x/your_command
    // Adjust based on your ESP code. Below uses the simple path method.
    final url = Uri.parse('http://$_espIp/$command');

    setState(() {
      _logs.add("> $command");
      _commandController.clear();
    });

    try {
      final response = await http.get(url);
      setState(() {
        _logs.add("< Response [${response.statusCode}]: ${response.body}");
      });
    } catch (e) {
      setState(() {
        _logs.add("< Error: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WiFi Terminal"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logs[index],
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'Courier',
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      labelText: "Enter Command",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _sendCustomCommand,
                  icon: const Icon(Icons.send, color: Colors.purple),
                  iconSize: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
