import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/popular_categories_cubit.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/home/widgets/category_home_card.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PopularCategoryWidget extends StatelessWidget {
  const PopularCategoryWidget({super.key});

  final int maxLimit = 10;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PopularCategoriesCubit, PopularCategoriesState>(
      builder: (context, state) {
        if (state is PopularCategoriesSuccess) {
          if (state.categories.isEmpty) return const SizedBox.shrink();

          final length =
              state.categories.length > maxLimit ? maxLimit : state.categories.length;

          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                  child: Text(
                    "popularCategories".translate(context),
                    style: TextStyle(
                      fontSize: context.font.large,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 103,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                    scrollDirection: Axis.horizontal,
                    itemCount: length,
                    itemBuilder: (context, index) {
                      final category = state.categories[index];

                      return CategoryHomeCard(
                        title: category.name ?? "",
                        url: category.url ?? "",
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Routes.itemsList,
                            arguments: {
                              'catID': category.id.toString(),
                              'catName': category.name,
                              "categoryIds": [
                                category.id.toString(),
                              ],
                            },
                          );
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const SizedBox(width: 12);
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
