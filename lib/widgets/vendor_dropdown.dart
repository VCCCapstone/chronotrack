import 'package:flutter/material.dart';

class VendorDropdown extends StatefulWidget {
  final TextEditingController controller;
  const VendorDropdown({super.key, required this.controller});

  @override
  State<VendorDropdown> createState() => _VendorDropdownState();
}

class _VendorDropdownState extends State<VendorDropdown> {
  final Map<String, IconData> categoryIcons = {
    'Food & Beverage': Icons.fastfood,
    'Fuel & Gas': Icons.local_gas_station,
    'Retail & Grocery': Icons.shopping_cart,
    'Travel & Hotels': Icons.hotel,
    'Transport & Ride Services': Icons.local_taxi,
  };

  final Map<String, List<String>> categorizedVendors = {
    'Food & Beverage': [
      'A&W',
      'Boston Pizza',
      'Chipotle',
      "Denny's",
      "Domino's Pizza",
      'Five Guys',
      'IHOP',
      'KFC',
      "McDonald's",
      'Olive Garden',
      'Panera Bread',
      'Popeyes',
      'Red Lobster',
      'Starbucks',
      'Subway',
      'Taco Bell',
      'The Cheesecake Factory',
      'Tim Hortons',
      'Wendy\'s',
    ],
    'Fuel & Gas': [
      'Chevron',
      'Circle K',
      'Costco Gas',
      'Esso',
      'Husky',
      'Irving Oil',
      'Mobil',
      'Petro-Canada',
      'Shell',
      'Speedway',
      'Sunoco',
      'Ultramar',
      'Valero',
    ],
    'Retail & Grocery': [
      '7-Eleven',
      'Albertsons',
      'Best Buy',
      'Best Buy Canada',
      'Canada Computers',
      'CDW',
      'Dell',
      'Food Basics',
      'FreshCo',
      'Giant Tiger',
      'Google',
      'HP',
      'Kroger',
      'Lenovo',
      'Loblaws',
      'Longo\'s',
      'Memory Express',
      'Metro',
      'Microsoft',
      'Newegg',
      'No Frills',
      'Publix',
      'Real Canadian Superstore',
      'Safeway',
      'Save-On-Foods',
      'Sobeys',
      'Staples',
      'Target',
      'The Source',
      'Trader Joe\'s',
      'Walmart',
      'Whole Foods',
      'Amazon',
      'Apple',
    ],
    'Travel & Hotels': [
      'Air Canada',
      'Airbnb',
      'Avis',
      'Booking.com',
      'Budget Car Rental',
      'Choice Hotels',
      'Days Inn',
      'Delta Air Lines',
      'Enterprise Rent-A-Car',
      'Expedia',
      'Fairmont Hotels',
      'Four Seasons',
      'Hampton Inn',
      'Hilton',
      'Holiday Inn',
      'Hyatt',
      'Marriott',
      'Motel 6',
      'Ramada',
      'Travelodge',
      'Trip.com',
      'Turo',
      'United Airlines',
      'Via Rail',
      'WestJet',
    ],
    'Transport & Ride Services': [
      'Yellow Cab',
      'Beck Taxi',
      'Blue Line Taxi',
      'City Taxi',
      'RideCo',
      'U-Haul',
      'Uber',
      'Zipcar',
    ],
  };

  late final List<_GroupedVendor> groupedList;

  @override
  void initState() {
    super.initState();
    groupedList = [];
    for (var entry in categorizedVendors.entries) {
      final category = entry.key;
      final vendors = List<String>.from(entry.value)..sort();
      groupedList.addAll(
        vendors.map((v) => _GroupedVendor(name: v, category: category)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Vendor"),
        const SizedBox(height: 8),
        Autocomplete<_GroupedVendor>(
          displayStringForOption: (gv) => gv.name,
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return groupedList;
            return groupedList.where(
              (gv) => gv.name.toLowerCase().contains(value.text.toLowerCase()),
            );
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                controller.text = widget.controller.text;
                controller.selection = TextSelection.collapsed(
                  offset: controller.text.length,
                );
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  onChanged: (val) => widget.controller.text = val,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter or choose vendor',
                  ),
                );
              },
          onSelected: (gv) {
            widget.controller.text = gv.name;
          },
          optionsViewBuilder: (context, onSelected, options) {
            final Map<String, List<_GroupedVendor>> grouped = {};
            for (var option in options) {
              grouped.putIfAbsent(option.category, () => []).add(option);
            }
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    children: grouped.entries.expand((entry) {
                      final categoryIcon =
                          categoryIcons[entry.key] ?? Icons.category;
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                categoryIcon,
                                size: 18,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map(
                          (vendor) => ListTile(
                            title: Text(vendor.name),
                            onTap: () => onSelected(vendor),
                          ),
                        ),
                      ];
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GroupedVendor {
  final String name;
  final String category;
  _GroupedVendor({required this.name, required this.category});
}
