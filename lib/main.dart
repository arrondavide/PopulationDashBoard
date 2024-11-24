import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'floating_search_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wgimgdkrfbblkuivjtks.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndnaW1nZGtyZmJibGt1aXZqdGtzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjQ3Nzc5OTIsImV4cCI6MjA0MDM1Mzk5Mn0.oSCIEOAL-_dmQVxVpkGqaIcTvHx9Z-zupHX4XMggnd0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNP Portal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String selectedDivision = 'Provinces';
  bool isEditMode = false;

  final List<String> divisions = [
    'Provinces',
    'Districts',
    'Divisional Secretariats (DS Divisions)',
    'Grama Niladhari Divisions (GN Divisions)',
    'Villages',
  ];

  Map<String, List<Location>> locations = {
    'Provinces': [],
    'Districts': [],
    'Divisional Secretariats (DS Divisions)': [],
    'Grama Niladhari Divisions (GN Divisions)': [],
    'Villages': [],
  };

  MapController mapController = MapController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final response = await supabase
          .from('segments')
          .select()
          .order('segment_type', ascending: true)
          .order('segment_name', ascending: true);

      final allLocations = (response as List)
          .map((item) => Location(
                id: item['segment_id'],
                name: item['segment_name'],
                description: item['description'] ?? '',
                latLng: LatLng(item['latitude'], item['longitude']),
                parentId: item['parent_segment_id'],
                segmentType: item['segment_type'],
                population: item['population'],
              ))
          .toList();

      setState(() {
        for (var division in divisions) {
          locations[division] =
              allLocations.where((loc) => loc.segmentType == division).toList();
        }
      });
    } catch (error) {
      print('Error loading locations: $error');
    }
  }

  String? getParentName(int? parentId) {
    if (parentId == null) return null;
    for (var locationList in locations.values) {
      for (var location in locationList) {
        if (location.id == parentId) {
          return location.name;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: LatLng(8.062493, 83.303999),
              zoom: 7.5,
              onTap: isEditMode
                  ? (tapPosition, latLng) => _handleTap(latLng)
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: locations[selectedDivision]!.map((location) {
                  return Marker(
                    width: 80.0,
                    height: 80.0,
                    point: location.latLng,
                    child: Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 40),
                        Container(
                          color: Colors.white,
                          child: Text(location.name),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          FloatingSearchBar(
            onSearch: (query) {
              // Implement your search logic here
              print('Searching for: $query');
            },
            onFilterChanged: (filter) {
              // Implement your filter logic here
              print('Filter changed to: $filter');
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NavbarItem(icon: Icons.map, label: 'Map'),
                    NavbarItem(
                        icon: Icons.list,
                        label: 'Locations',
                        onTap: _showLocations),
                    NavbarItem(
                      icon: Icons.person_add, // Icon for adding members
                      label: 'Members',
                      onTap: _showAddMemberDialog, // Function to add members
                    ),
                    NavbarItem(
                      icon: Icons.assignment, // Icon for tasks
                      label: 'Tasks',
                      onTap: _showAssignTaskDialog, // Function to assign tasks
                    ),
                    NavbarItem(icon: Icons.settings, label: 'Settings'),
                    Switch(
                      value: isEditMode,
                      onChanged: (value) {
                        setState(() {
                          isEditMode = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Center(child: Text('Edit Mode')),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10.0,
                  children: divisions.map((division) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDivision = division;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: selectedDivision == division
                              ? const Color.fromARGB(255, 3, 117, 52)
                                  .withOpacity(0.5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          division,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: selectedDivision == division
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = '';
        String email = '';
        String nicNumber = '';
        int? roleId;
        int? segmentId;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add New Member'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (value) => name = value,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      onChanged: (value) => email = value,
                    ),
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'NIC Number'),
                      onChanged: (value) => nicNumber = value,
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Role'),
                      value: roleId,
                      items: [
                        // Add dropdown items for roles here
                        DropdownMenuItem(
                          value: 1,
                          child: const Text('Role 1'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: const Text('Role 2'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        roleId = value;
                      }),
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Segment'),
                      value: segmentId,
                      items: locations['Provinces']!.map((segment) {
                        return DropdownMenuItem(
                          value: segment.id,
                          child: Text(segment.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        segmentId = value;
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    try {
                      final response = await supabase.from('members').insert({
                        'name': name,
                        'email': email,
                        'nic_number': nicNumber,
                        'role_id': roleId,
                        'segment_id': segmentId,
                        'created_at': DateTime.now(),
                      }).select();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Member added successfully')),
                      );
                      Navigator.of(context).pop();
                    } catch (error) {
                      print('Error adding member: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add member')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAssignTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String taskDescription = '';
        int? assignedBy;
        int? assignedTo;
        int? segmentId;
        String status = 'Pending';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Assign Task'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Task Description'),
                      onChanged: (value) => taskDescription = value,
                    ),
                    DropdownButtonFormField<int>(
                      decoration:
                          const InputDecoration(labelText: 'Assigned By'),
                      value: assignedBy,
                      items: [
                        // Add dropdown items for members here
                        DropdownMenuItem(
                          value: 1,
                          child: const Text('Member 1'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: const Text('Member 2'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        assignedBy = value;
                      }),
                    ),
                    DropdownButtonFormField<int>(
                      decoration:
                          const InputDecoration(labelText: 'Assigned To'),
                      value: assignedTo,
                      items: [
                        // Add dropdown items for members here
                        DropdownMenuItem(
                          value: 1,
                          child: const Text('Member 1'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: const Text('Member 2'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        assignedTo = value;
                      }),
                    ),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Segment'),
                      value: segmentId,
                      items: locations[selectedDivision]!.map((segment) {
                        return DropdownMenuItem(
                          value: segment.id,
                          child: Text(segment.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        segmentId = value;
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Status'),
                      value: status,
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'In Progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'Completed',
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        status = value!;
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Assign'),
                  onPressed: () async {
                    try {
                      final response = await supabase.from('tasks').insert({
                        'task_description': taskDescription,
                        'assigned_by': assignedBy,
                        'assigned_to': assignedTo,
                        'segment_id': segmentId,
                        'status': status,
                        'created_at': DateTime.now(),
                      }).select();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Task assigned successfully')),
                      );
                      Navigator.of(context).pop();
                    } catch (error) {
                      print('Error assigning task: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to assign task')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleTap(LatLng latLng) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = '';
        String description = '';
        int? parentId;
        int? population;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Location to $selectedDivision'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Name'),
                      onChanged: (value) => name = value,
                    ),
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      onChanged: (value) => description = value,
                    ),
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Population'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => population = int.tryParse(value),
                    ),
                    if (selectedDivision != 'Provinces') ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText:
                              'Parent ${_getParentDivision(selectedDivision)}',
                        ),
                        value: parentId,
                        items: _getParentLocations(selectedDivision)
                            .map((location) => DropdownMenuItem(
                                  value: location.id,
                                  child: Text(location.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            parentId = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    try {
                      final response = await supabase.from('segments').insert({
                        'segment_name': name,
                        'description': description,
                        'latitude': latLng.latitude,
                        'longitude': latLng.longitude,
                        'segment_type': selectedDivision,
                        'parent_segment_id': parentId,
                        'population': population,
                      }).select();

                      final newLocation = Location(
                        id: response[0]['segment_id'],
                        name: name,
                        description: description,
                        latLng: latLng,
                        parentId: parentId,
                        segmentType: selectedDivision,
                        population: population,
                      );

                      setState(() {
                        locations[selectedDivision]!.add(newLocation);
                        mapController.move(newLocation.latLng, 10.0);
                      });

                      Navigator.of(context).pop();
                    } catch (error) {
                      print('Error adding location: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add location')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getParentDivision(String division) {
    switch (division) {
      case 'Districts':
        return 'Province';
      case 'Divisional Secretariats (DS Divisions)':
        return 'District';
      case 'Grama Niladhari Divisions (GN Divisions)':
        return 'DS Division';
      case 'Villages':
        return 'GN Division';
      default:
        return '';
    }
  }

  List<Location> _getParentLocations(String division) {
    switch (division) {
      case 'Districts':
        return locations['Provinces']!;
      case 'Divisional Secretariats (DS Divisions)':
        return locations['Districts']!;
      case 'Grama Niladhari Divisions (GN Divisions)':
        return locations['Divisional Secretariats (DS Divisions)']!;
      case 'Villages':
        return locations['Grama Niladhari Divisions (GN Divisions)']!;
      default:
        return [];
    }
  }

  void _showLocations() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Locations in $selectedDivision'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: locations[selectedDivision]!.length,
              itemBuilder: (context, index) {
                final location = locations[selectedDivision]![index];
                final parentName = getParentName(location.parentId);
                return ListTile(
                  title: Text(location.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location.description),
                      if (parentName != null) Text('Parent: $parentName'),
                      Text('Population: ${location.population ?? "N/A"}'),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

class NavbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const NavbarItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color.fromARGB(255, 42, 42, 42)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color.fromARGB(255, 42, 42, 42))),
        ],
      ),
    );
  }
}

class Location {
  final int id;
  final String name;
  final String description;
  final LatLng latLng;
  final int? parentId;
  final String segmentType;
  final int? population;

  Location({
    required this.id,
    required this.name,
    required this.description,
    required this.latLng,
    this.parentId,
    required this.segmentType,
    this.population,
  });
}
