import 'package:flutter/material.dart';

class FloatingSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(String) onFilterChanged;

  const FloatingSearchBar({
    Key? key,
    required this.onSearch,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  _FloatingSearchBarState createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Members';
  Offset _position = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newPosition = _position + details.delta;
            final size = MediaQuery.of(context).size;
            final width = 300.0; // Width of the search bar
            final height = 100.0; // Approximate height of the search bar

            // Ensure the search bar stays within the screen boundaries
            _position = Offset(
              newPosition.dx.clamp(0, size.width - width),
              newPosition.dy.clamp(0, size.height - height),
            );
          });
        },
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                        ),
                        onChanged: widget.onSearch,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        widget.onSearch('');
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterChip('Members'),
                    _buildFilterChip('Tasks'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == label,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? label : '';
        });
        widget.onFilterChanged(_selectedFilter);
      },
    );
  }
}
