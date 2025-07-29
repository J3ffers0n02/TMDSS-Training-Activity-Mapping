import 'package:flutter/material.dart';
import 'package:tmdss/components/Map/overlays/details/details_box.dart';
import 'package:tmdss/helpers/my_search_bar.dart';
import 'package:tmdss/components/filter/helpers/result_box.dart';

class SearchAndResults extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<Map<String, dynamic>> trainingData;
  final bool shouldShowResults;
  final bool isLoading;

  final void Function(Map<String, dynamic>) onTrainingSelected;
  final VoidCallback onBackToList;

  const SearchAndResults({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.trainingData,
    required this.shouldShowResults,
    required this.isLoading,
    required this.onTrainingSelected,
    required this.onBackToList,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MainSearchBar(),
          const SizedBox(height: 8),
          if (shouldShowResults)
            SingleChildScrollView(
              child: ResultBox(
                results: trainingData,
                shouldShow: shouldShowResults,
                isLoading: isLoading,
                onTrainingSelected: onTrainingSelected, // ✅ passed from parent
                onBackToList: onBackToList, // ✅ passed from parent
              ),
            ),
          const SizedBox(height: 8),
          if (shouldShowResults && !isLoading)
            DetailsBox(
              totalTrainings: trainingData.length,
              shouldShow: true,
            ),
        ],
      ),
    );
  }
}
