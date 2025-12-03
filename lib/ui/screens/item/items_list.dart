import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/item/fetch_item_from_category_cubit.dart';
import 'package:eClassify/data/model/item/item_filter_model.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:eClassify/ui/screens/home/widgets/item_horizontal_card.dart';
import 'package:eClassify/ui/screens/main_activity.dart';
import 'package:eClassify/ui/screens/native_ads_screen.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_silver_grid_delegate.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ItemsList extends StatefulWidget {
  final String categoryId, categoryName;
  final List<String> categoryIds;

  const ItemsList({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIds,
  });

  @override
  ItemsListState createState() => ItemsListState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      builder: (_) => ItemsList(
        categoryId: arguments?['catID'] as String,
        categoryName: arguments?['catName'],
        categoryIds: arguments?['categoryIds'],
      ),
    );
  }
}

class ItemsListState extends State<ItemsList> {
  late ScrollController controller;
  static TextEditingController searchController = TextEditingController();
  bool isFocused = false;
  bool isList = true;
  String previousSearchQuery = "";
  Timer? _searchDelay;
  String? sortBy;
  ItemFilterModel? filter;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    searchBody = {};
    Constant.itemFilter = null;
    searchController = TextEditingController();
    searchController.addListener(searchItemListener);
    controller = ScrollController()..addListener(_loadMore);

    context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
      categoryId: int.parse(widget.categoryId),
      search: "",
      filter: ItemFilterModel(
        categoryId: widget.categoryId,
        location: HiveUtils.getLocationV2(),
      ),
    );

    Future.delayed(Duration.zero, () {
      selectedCategoryId = widget.categoryId;
      selectedCategoryName = widget.categoryName;
      searchBody[Api.categoryId] = widget.categoryId;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.removeListener(_loadMore);
    controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  //this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    searchCallAfterDelay();
  }

  //This will create delay so we don't face rapid api call
  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  ///This will call api after some delay
  void itemSearch() {
    // if (searchController.text.isNotEmpty) {
    if (previousSearchQuery != searchController.text) {
      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
        categoryId: int.parse(widget.categoryId),
        search: searchController.text,
      );
      previousSearchQuery = searchController.text;
      sortBy = null;
      setState(() {});
    }
  }

  void _loadMore() async {
    if (controller.isEndReached()) {
      if (context.read<FetchItemFromCategoryCubit>().hasMoreData()) {
        context.read<FetchItemFromCategoryCubit>().fetchItemFromCategoryMore(
          catId: int.parse(widget.categoryId),
          search: searchController.text,
          sortBy: sortBy,
          filter: ItemFilterModel(
            location: HiveUtils.getLocationV2(),
            categoryId: widget.categoryId,
          ),
        );
      }
    }
  }

  Widget searchBarWidget() {
    return Container(
      height: 56,
      color: context.color.secondaryColor,
      child: LayoutBuilder(
        builder: (context, c) {
          return SizedBox(
            width: c.maxWidth,
            child: FittedBox(
              fit: BoxFit.none,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 18.0,
                ),
                child: Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 243,
                      height: 40,
                      alignment: AlignmentDirectional.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: context.color.textLightColor.withValues(
                            alpha: 0.18,
                          ),
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        color: context.color.primaryColor,
                      ),
                      child: TextFormField(
                        controller: searchController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          //OutlineInputBorder()
                          fillColor: Theme.of(context).colorScheme.primaryColor,
                          hintText: "searchHintLbl".translate(context),
                          prefixIcon: setSearchIcon(),
                          prefixIconConstraints: const BoxConstraints(
                            minHeight: 5,
                            minWidth: 5,
                          ),
                        ),
                        enableSuggestions: true,
                        onEditingComplete: () {
                          changeFocus(false);
                        },
                        onTap: () {
                          //change prefix icon color to primary
                          changeFocus(true);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isList = false;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: context.color.textLightColor.withValues(
                              alpha: 0.18,
                            ),
                          ),
                          color: context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: UiUtils.getSvg(
                            AppIcons.gridViewIcon,
                            color: !isList
                                ? context.color.textDefaultColor
                                : context.color.textDefaultColor.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isList = true;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: context.color.textLightColor.withValues(
                              alpha: 0.18,
                            ),
                          ),
                          color: context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: UiUtils.getSvg(
                            AppIcons.listViewIcon,
                            color: isList
                                ? context.color.textDefaultColor
                                : context.color.textDefaultColor.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void changeFocus(bool changeFocusVal) {
    isFocused = changeFocusVal; //set icon color to black back if flase
    if (!changeFocusVal) {
      FocusScope.of(context).unfocus(); //dismiss keyboard
    }
    setState(() {});
  }

  Widget setSearchIcon() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: UiUtils.getSvg(
        AppIcons.search,
        color: context.color.textDefaultColor,
      ),
    );
  }

  Widget setSuffixIcon() {
    return GestureDetector(
      onTap: () {
        searchController.clear();
        changeFocus(false);
      },
      child: Icon(
        Icons.close_rounded,
        color: Theme.of(context).colorScheme.blackColor,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return bodyWidget();
  }

  Widget bodyWidget() {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (isPop, result) {
          Constant.itemFilter = null;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primaryColor,
          appBar: AppBar(
            titleSpacing: 0,
            title: CustomText(widget.categoryName, maxLines: 1),
          ),
          bottomNavigationBar: bottomWidget(),
          body: Column(
            children: [
              searchBarWidget(),
              Expanded(child: fetchItems()),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomWidget() {
    return SafeArea(
      bottom: Platform.isAndroid,
      child: ColoredBox(
        color: context.color.secondaryColor,
        child: SizedBox(
          height:
              45 + (Platform.isIOS ? MediaQuery.of(context).padding.bottom : 0),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(child: filterByWidget()),
                VerticalDivider(
                  color: context.color.textLightColor.withValues(alpha: 0.3),
                  endIndent: Platform.isIOS ? 5 : null,
                  indent: Platform.isIOS ? 5 : null,
                ),
                Expanded(child: sortByWidget()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget filterByWidget() {
    return TextButton.icon(
      onPressed: () {
        Navigator.pushNamed(
          context,
          Routes.filterScreen,
          arguments: {"from": "itemsList", "categoryIds": widget.categoryIds},
        ).then((value) {
          if (value case final ItemFilterModel filterModel) {
            filter = filterModel.copyWith(categoryId: widget.categoryId);
            context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
              categoryId: int.parse(widget.categoryId),
              search: searchController.text.toString(),
              filter: filter,
            );
          }
        });
      },
      icon: UiUtils.getSvg(
        AppIcons.filterByIcon,
        color: context.color.textDefaultColor,
      ),
      label: CustomText("filterTitle".translate(context)),
    );
  }

  Widget sortByWidget() {
    return TextButton.icon(
      onPressed: showSortByBottomSheet,
      icon: UiUtils.getSvg(
        AppIcons.sortByIcon,
        color: context.color.textDefaultColor,
      ),
      label: CustomText('sortBy'.translate(context)),
    );
  }

  void showSortByBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.color.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
                child: CustomText(
                  'sortBy'.translate(context),
                  textAlign: TextAlign.start,
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
              ),

              const Divider(height: 1),
              sortByItemWidget('default', null),

              const Divider(height: 1),
              sortByItemWidget('newToOld', "new-to-old"),

              const Divider(height: 1),
              sortByItemWidget('oldToNew', "old-to-new"),

              const Divider(height: 1),
              sortByItemWidget('priceHighToLow', "price-high-to-low"),

              const Divider(height: 1),
              sortByItemWidget('priceLowToHigh', "price-low-to-high"),
            ],
          ),
        );
      },
    );
  }

  Widget fetchItems() {
    return BlocBuilder<FetchItemFromCategoryCubit, FetchItemFromCategoryState>(
      builder: (context, state) {
        if (state is FetchItemFromCategoryInProgress) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            itemCount: 10,
            itemBuilder: (context, index) {
              return buildItemsShimmer(context);
            },
          );
        }

        if (state is FetchItemFromCategoryFailure) {
          return Center(child: CustomText(state.errorMessage));
        }
        if (state is FetchItemFromCategorySuccess) {
          if (state.itemModel.isEmpty) {
            return Center(
              child: NoDataFound(
                onTap: () {
                  context
                      .read<FetchItemFromCategoryCubit>()
                      .fetchItemFromCategory(
                        categoryId: int.parse(widget.categoryId),
                        search: searchController.text.toString(),
                        filter: filter,
                      );
                },
              ),
            );
          }
          return Column(
            children: [
              Expanded(child: mainChildren(state.itemModel)),
              if (state.isLoadingMore) UiUtils.progress(),
            ],
          );
        }
        return Container();
      },
    );
  }

  Widget sortByItemWidget(String title, String? sortByVal) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      title: CustomText(title.translate(context)),
      onTap: () {
        Navigator.pop(context);
        sortBy = sortByVal;
        context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: int.parse(widget.categoryId),
          search: searchController.text.toString(),
          sortBy: sortByVal,
        );
        setState(() {
          FocusManager.instance.primaryFocus?.unfocus();
        });
      },
    );
  }

  void _navigateToDetails(BuildContext context, ItemModel item) {
    Navigator.pushNamed(
      context,
      Routes.adDetailsScreen,
      arguments: {'model': item},
    );
  }

  Widget mainChildren(List<ItemModel> items) {
    List<Widget> children = [];
    int gridCount = Constant.nativeAdsAfterItemNumber;
    int total = items.length;

    for (int i = 0; i < total; i += gridCount) {
      if (isList) {
        children.add(
          _buildListViewSection(context, i, min(gridCount, total - i), items),
        );
      } else {
        children.add(
          _buildGridViewSection(context, i, min(gridCount, total - i), items),
        );
      }

      int remainingItems = total - i - gridCount;
      if (remainingItems > 0) {
        children.add(NativeAdWidget(type: TemplateType.medium));
      }
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        // Debug log to check if onRefresh is triggered
        searchBody = {};
        Constant.itemFilter = null;

        context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: int.parse(widget.categoryId),
          search: "",
          filter: ItemFilterModel(
            location: HiveUtils.getLocationV2(),
            categoryId: widget.categoryId,
          ),
        );
      },
      color: context.color.territoryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        controller: controller,
        padding: EdgeInsetsDirectional.only(bottom: 30),
        children: children,
      ),
    );
  }

  Widget _buildListViewSection(
    BuildContext context,
    int startIndex,
    int itemCount,
    List<ItemModel> items,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        ItemModel item = items[startIndex + index];
        return GestureDetector(
          onTap: () => _navigateToDetails(context, item),
          child: ItemHorizontalCard(item: item),
        );
      },
    );
  }

  Widget _buildGridViewSection(
    BuildContext context,
    int startIndex,
    int itemCount,
    List<ItemModel> items,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
        crossAxisCount: 2,
        height: MediaQuery.of(context).size.height / 3.2,
        mainAxisSpacing: 7,
        crossAxisSpacing: 10,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        ItemModel item = items[startIndex + index];
        return GestureDetector(
          onTap: () => _navigateToDetails(context, item),
          child: ItemCard(item: item),
        );
      },
    );
  }

  Widget buildItemsShimmer(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(width: 1.5, color: context.color.borderColor),
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        spacing: 10,
        children: [
          CustomShimmer(height: 120, width: 100),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomShimmer(width: 100, height: 10, borderRadius: 7),
              CustomShimmer(width: 150, height: 10, borderRadius: 7),
              CustomShimmer(width: 120, height: 10, borderRadius: 7),
              CustomShimmer(width: 80, height: 10, borderRadius: 7),
            ],
          ),
        ],
      ),
    );
  }
}
