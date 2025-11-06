import 'package:flutter/material.dart';

class SearchResultList extends StatelessWidget {
  final List<String> results;
  final Function(String) onUserSelected;

  const SearchResultList({
    super.key,
    required this.results,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        children: results.map((username) {
          return GestureDetector(
            onTap: () => onUserSelected(username),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Icon(Icons.add, color: Colors.green),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
