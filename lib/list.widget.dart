import 'package:flutter/material.dart';
import 'package:lazyloadinglistview/pessoa.model.dart';

class ListViewScrollAutomaticToIndex extends StatefulWidget {
  final List<Pessoa> listaItens;
  final int? currentItemIndex;

  const ListViewScrollAutomaticToIndex(
      {super.key, required this.listaItens, required this.currentItemIndex});

  @override
  State<ListViewScrollAutomaticToIndex> createState() =>
      _ListViewScrollAutomaticToIndexState();
}

class _ListViewScrollAutomaticToIndexState
    extends State<ListViewScrollAutomaticToIndex> {
  final scrollController = ScrollController();

  final fixedItemHeight = 76.0;

  /// Padding between loader and list
  final paddingLoaderMoreItens = 48.0;

  /// list to be desplayed
  late List<Pessoa> listaItemsDisplayed;

  /// list that receive the previously remain itens to be displayed
  late List<Pessoa> listaItemsRemainPreviously;

  /// list that receive the next remain itens to be displayed
  late List<Pessoa> listaItemsRemainNext;

  // The quantity of items will be display when scroll
  final _itemsPerLoad = 20;

  /// Index that will be go when starts this widget
  late double startIndexJumpTo;

  /// Control variable that manage the loader/list display
  bool isLoadingMoreItens = false;

  /// Control variable that manage if the loader will apear up/down the list
  bool isTopLoader = false;

  /// Variavel de controle que verifica se deve realizar o scroll para o item que estava
  /// Utilizado quando o usuario carrega itens anteriores.
  bool _shouldKeepScrollOnCurrentIndex = false;

  @override
  void initState() {
    listaItemsDisplayed = [];
    listaItemsRemainPreviously = [];
    listaItemsRemainNext = [];
    listaItemsDisplayed.addAll(_getStartsListItems());
    scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _startStateJumpTo();
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        isLoadingMoreItens
            ? Container(
                alignment: isTopLoader
                    ? AlignmentDirectional.topCenter
                    : AlignmentDirectional.bottomCenter,
                child: const CircularProgressIndicator(),
              )
            : const SizedBox(),
        Container(
          margin: _getMarginLoaderItens(),
          child: Scrollbar(
            controller: scrollController,
            trackVisibility: true,
            thumbVisibility: true,
            interactive: true,
            thickness: 8.0,
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 0,
                );
              },
              shrinkWrap: true,
              controller: scrollController,
              padding: const EdgeInsets.all(0),
              itemCount: listaItemsDisplayed.length,
              itemBuilder: (context, index) {
                var item = listaItemsDisplayed[index];
                return SizedBox(
                  height: fixedItemHeight,
                  child: ListTile(
                    title: Text("${item.id} - ${item.nome}"),
                    tileColor: isCurrent(item) ? Colors.blue : Colors.amber,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 88,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: const BorderRadius.all(
                Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text("Qty. Items: ${widget.listaItens.length.toString()}"),
                Text("Current Index: ${widget.currentItemIndex.toString()}"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Pessoa> _getStartsListItems() {
    List<Pessoa> listInicial = [];

    var index = (widget.currentItemIndex ?? 0);

    if (index == 0) {
      listInicial = widget.listaItens.take(_itemsPerLoad).toList();
      listaItemsRemainNext = widget.listaItens.skip(_itemsPerLoad).toList();
    } else if (index + _itemsPerLoad > widget.listaItens.length) {
      var indexToTakeSkip = (widget.listaItens.length - _itemsPerLoad) < 0
          ? 0
          : (widget.listaItens.length - _itemsPerLoad);

      listInicial = widget.listaItens.skip(indexToTakeSkip).toList();
      listaItemsRemainPreviously =
          widget.listaItens.take(indexToTakeSkip).toList();
    } else {
      listaItemsRemainPreviously = widget.listaItens.take((index)).toList();

      listaItemsRemainNext =
          widget.listaItens.skip(index + _itemsPerLoad).toList();

      listInicial =
          widget.listaItens.skip(index).toList().take(_itemsPerLoad).toList();
    }

    startIndexJumpTo = widget.currentItemIndex != null
        ? listInicial
            .indexWhere((element) =>
                element.id == widget.listaItens[widget.currentItemIndex!].id)
            .toDouble()
        : 0;

    return listInicial;
  }

  Future<void> _loadMoreItems({required bool isNext}) async {
    if (isNext) {
      if (listaItemsRemainNext.isNotEmpty) {
        await _openLoaderList(isUpSideLoader: false);
        List<Pessoa> nextItems =
            listaItemsRemainNext.take(_itemsPerLoad).toList();
        listaItemsDisplayed.addAll(nextItems);
        listaItemsRemainNext
            .removeWhere((element) => nextItems.contains(element));
        await _closeLoaderList();
      }
      _shouldKeepScrollOnCurrentIndex = false;
    } else {
      if (listaItemsRemainPreviously.isNotEmpty) {
        await _openLoaderList(isUpSideLoader: true);
        List<Pessoa> previewsItens = [];
        var isSkip = listaItemsRemainPreviously.length > _itemsPerLoad;
        if (isSkip) {
          previewsItens = listaItemsRemainPreviously
              .skip(listaItemsRemainPreviously.length - _itemsPerLoad)
              .toList();
        } else {
          previewsItens = listaItemsRemainPreviously
              .take(listaItemsRemainPreviously.length)
              .toList();
        }
        previewsItens.addAll(listaItemsDisplayed);
        listaItemsDisplayed.clear();
        listaItemsDisplayed.addAll(previewsItens);
        listaItemsRemainPreviously
            .removeWhere((element) => previewsItens.contains(element));
        _shouldKeepScrollOnCurrentIndex = true;
        _keepScrollOnCurrentIndex();
        await _closeLoaderList();
      }
    }
  }

  bool isCurrent(Pessoa item) => widget.currentItemIndex != null
      ? item.id == widget.listaItens[widget.currentItemIndex!].id
      : false;

  EdgeInsets _getMarginLoaderItens() {
    return isLoadingMoreItens
        ? isTopLoader
            ? EdgeInsets.only(top: paddingLoaderMoreItens)
            : EdgeInsets.only(bottom: paddingLoaderMoreItens)
        : EdgeInsets.zero;
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      _loadMoreItems(isNext: true);
    }
    if (scrollController.position.pixels ==
        scrollController.position.minScrollExtent) {
      _loadMoreItems(isNext: false);
    }
  }

  Future<void> _openLoaderList({bool isUpSideLoader = true}) async {
    setState(() {
      isTopLoader = isUpSideLoader;
      isLoadingMoreItens = true;
    });
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _closeLoaderList() async {
    setState(() {
      isLoadingMoreItens = false;
    });
    await Future.delayed(const Duration(seconds: 1));
  }

  void _startStateJumpTo() {
    if (scrollController.position.maxScrollExtent > 0) {
      scrollController.animateTo(((startIndexJumpTo * fixedItemHeight) + 5),
          duration: const Duration(seconds: 1), curve: Curves.decelerate);
    }
  }

  void _keepScrollOnCurrentIndex() async {
    if (_shouldKeepScrollOnCurrentIndex) {
      var indexJump = _getIndexItemToKeepScrollCurrentIndex();

      scrollController.jumpTo(indexJump * fixedItemHeight);
      scrollController.animateTo((((indexJump - 1) * fixedItemHeight)),
          duration: const Duration(seconds: 3),
          curve: Curves.fastLinearToSlowEaseIn);
      _shouldKeepScrollOnCurrentIndex = false;
    }
  }

  num _getIndexItemToKeepScrollCurrentIndex() =>
      (widget.currentItemIndex ?? 0) < _itemsPerLoad
          ? (widget.currentItemIndex ?? 0)
          : _itemsPerLoad;
}
