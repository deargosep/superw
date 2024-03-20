import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

String baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';

Dio createDio() {
  return Dio(BaseOptions(
    baseUrl: baseUrl,
  ));
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MenuController _menuController = MenuController();
  final TextEditingController _textEditingController = TextEditingController();
  late FocusNode focusNode;
  List<Definition> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  Future<void> fetchData(String text) async {
    Completer completer = Completer();
    Response? response;
    response = await createDio().get(text);
    List<Definition> list = [];
    String originalWord = response.data[0]["word"];
    List? responseList = response.data[0]["meanings"] as List;

    await Future.forEach(responseList, (element) {
      list.add(toDefinition(element, originalWord));
    });

    if (list.length != responseList.length) {
      return completer.completeError("Couldn't get data!");
    }
    setState(() {
      _data = list;
    });
    return completer.complete();
  }

  void onSubmitted(String text) async {
    if (text == '') {
      setState(() {
        _loading = false;
        _data = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _data = [];
    });
    try {
      await fetchData(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.teal,
      home: GestureDetector(
        onTap: () {
          focusNode.unfocus();
        },
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (focusNode.hasFocus) {
                onSubmitted(_textEditingController.value.text);
                focusNode.unfocus();
              } else {
                focusNode.requestFocus();
              }
            },
            child: const Icon(Icons.search),
          ),
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: const Text(
              'superw.',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              MenuAnchor(
                  controller: _menuController,
                  menuChildren: [
                    MenuItemButton(
                        onPressed: () async {
                          var uri =
                              Uri.parse('https://github.com/deargosep/superw');
                          launchUrl(uri);
                        },
                        child: const Text('GitHub')),
                    MenuItemButton(
                        onPressed: () async {
                          var uri = Uri.parse('https://dictionaryapi.dev/');
                          launchUrl(uri);
                        },
                        child: const Text('Dictionary')),
                  ],
                  child: IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _menuController.open();
                    },
                  ))
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Content(_textEditingController, focusNode, onSubmitted,
                _data, _loading),
          ),
        ),
      ),
    );
  }
}

class Content extends StatefulWidget {
  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final Function(String) onSubmitted;
  final List<Definition> _data;
  final bool _loading;

  const Content(this.textEditingController, this.focusNode, this.onSubmitted,
      this._data, this._loading,
      {super.key});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  void share(Definition thing) async {
    await Share.share('''
    "${thing.originalWord}"
    ${thing.meaning != null ? 'Meaning: ${thing.meaning}' : ''}
    ${thing.example != null ? 'Example: ${thing.example}' : ''}
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 20),
          child: TextField(
            autofocus: true,
            focusNode: widget.focusNode,
            inputFormatters: [
              FilteringTextInputFormatter(RegExp(r'^[a-zA-Z]+$'), allow: true)
            ],
            onSubmitted: widget.onSubmitted,
            controller: widget.textEditingController,
            decoration: const InputDecoration(labelText: 'Type a word'),
          ),
        ),
        if (widget._loading)
          const LinearProgressIndicator()
        else
          Expanded(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget._data.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int index) =>
                      buildCard(index)))
      ],
    );
  }

  Card buildCard(int index) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget._data[index].meaning != null)
                    const Text(
                      'Meaning:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  if (widget._data[index].meaning != null)
                    const SizedBox(
                      height: 10,
                    ),
                  if (widget._data[index].meaning != null)
                    Text(
                      widget._data[index].meaning ?? "empty",
                    ),
                  if (widget._data[index].example != null)
                    const Divider(
                      height: 20,
                    ),
                  if (widget._data[index].example != null)
                    const Text(
                      'Example:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  if (widget._data[index].example != null)
                    const SizedBox(
                      height: 10,
                    ),
                  if (widget._data[index].example != null)
                    Text(widget._data[index].example!),
                  // const Divider(
                  //   height: 20,
                  // )
                ],
              ),
            ),
            IconButton(
                onPressed: () {
                  share(widget._data[index]);
                },
                icon: const Icon(Icons.share))
          ],
        ),
      ),
    );
  }
}

class Definition {
  Definition({required this.originalWord, this.meaning, this.example});
  String? meaning;
  String? example;
  String originalWord;
}

Definition toDefinition(Map<String, dynamic> el, String originalWord) {
  late Definition newEl = Definition(originalWord: originalWord);

  newEl.meaning = el["definitions"][0]["definition"];
  newEl.example = el["definitions"][0]["example"];

  return newEl;
}
