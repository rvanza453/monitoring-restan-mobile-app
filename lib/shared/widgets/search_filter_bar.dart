import 'package:flutter/material.dart';

class SearchFilterBar extends StatefulWidget {
  final String hintText;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  const SearchFilterBar({
    Key? key,
    required this.hintText,
    required this.onSearchChanged,
    required this.onFilterPressed,
    this.hasActiveFilters = false,
  }) : super(key: key);

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                widget.onSearchChanged(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: widget.hasActiveFilters 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.hasActiveFilters 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
              ),
            ),
            child: IconButton(
              onPressed: widget.onFilterPressed,
              icon: Icon(
                Icons.filter_list,
                color: widget.hasActiveFilters 
                    ? Colors.white 
                    : Colors.grey[600],
              ),
              tooltip: 'Filter',
            ),
          ),
        ],
      ),
    );
  }
}