import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lazyloadinglistview/list.widget.dart';
import 'package:lazyloadinglistview/pessoa.model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loader = true;

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3)).then(
      (value) => setState(
        () {
          loader = false;
        },
      ),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// If you prefer gerenerate a especific size of itens, just change this value
    /// to deserved value;
    int? quantity = null;

    List<Pessoa> list = loader ? [] : getRandomicValueList(sizeValue: quantity);
    var currentIndex = loader ? 0 : getRandomicCurrentIndex(quantity, list);

    var listView = ListViewScrollAutomaticToIndex(
      listaItens: list,
      currentItemIndex: currentIndex,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("ListViewScrollAutomaticToIndex")),
      body: loader
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SizedBox(child: listView),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          setState(() {
            loader = true;
            Future.delayed(const Duration(seconds: 2)).then(
              (value) => setState(
                () {
                  loader = false;
                },
              ),
            );
          });
        },
      ),
    );
  }
}

int getRandomicCurrentIndex(int? quantity, List<Pessoa> list) {
  return quantity != null
      ? Random().nextInt(quantity == 0 ? 0 : (quantity))
      : Random().nextInt(list.isEmpty ? 0 : (list.length));
}

/// return a list randomic of people class
/// if you don't pass sizeValue te list will return a list with util 1000 items
List<Pessoa> getRandomicValueList({int? sizeValue}) {
  var size = sizeValue ?? Random().nextInt(1000);
  var returnList = <Pessoa>[];

  for (var id = 0; id < size; id++) {
    returnList.add(Pessoa(id: id, nome: "Alala"));
  }

  return returnList;
}
