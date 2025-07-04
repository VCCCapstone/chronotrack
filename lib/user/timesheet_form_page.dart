// ignore_for_file: use_build_context_synchronously, avoid_function_literals_in_foreach_calls
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;

class TimesheetFormPage extends StatefulWidget {
  const TimesheetFormPage({super.key});

  @override
  State<TimesheetFormPage> createState() => _TimesheetFormPageState();
}

class _TimesheetFormPageState extends State<TimesheetFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _weekId;
  final _vehicleController = TextEditingController();
  final _startKmController = TextEditingController(text: '0');
  final _endKmController = TextEditingController(text: '0');
  final _specialNotesController = TextEditingController();
  int _totalKm = 0;
  double _totalWeeklyHours = 0;

  final List<Map<String, TextEditingController>> _weeklyEntries = List.generate(
    7,
    (_) => {
      "am": TextEditingController(text: '0.0'),
      "pm": TextEditingController(text: '0.0'),
      "extra": TextEditingController(text: '0.0'),
    },
  );

  @override
  void initState() {
    super.initState();
    _loadUserAndGenerateWeekId();
  }

  Future<void> _loadUserAndGenerateWeekId() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final emailAttr = attributes.firstWhere(
        (a) => a.userAttributeKey.key == 'email',
      );
      final email = emailAttr.value;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // Find the first Sunday of the month
      int daysUntilSunday = (7 - monthStart.weekday % 7) % 7;
      final firstSunday = monthStart.add(Duration(days: daysUntilSunday));

      // Calculate the number of weeks since the first Sunday
      int weekOfMonth = ((now.difference(firstSunday).inDays) ~/ 7) + 1;

      // Pad week number to 2 digits
      final weekNum = weekOfMonth.toString().padLeft(2, '0');
      final monthAbbr = DateFormat('MMM').format(now).toUpperCase();
      final year = now.year;
      final weekId = "$email-WEEK$weekNum-$monthAbbr-$year";

      setState(() {
        _email = email;
        _weekId = weekId;
      });
    } catch (e) {
      debugPrint("Error generating week ID: $e");
    }
  }

  void _calculateKmAndHours() {
    final start = int.tryParse(_startKmController.text) ?? 0;
    final end = int.tryParse(_endKmController.text) ?? 0;
    _totalKm = end - start;

    double total = 0;
    for (var day in _weeklyEntries) {
      final am = double.tryParse(day["am"]!.text) ?? 0;
      final pm = double.tryParse(day["pm"]!.text) ?? 0;
      final extra = double.tryParse(day["extra"]!.text) ?? 0;
      total += am + pm + extra;
    }
    setState(() {
      _totalWeeklyHours = total;
    });
  }

  Widget _hourField(TextEditingController controller, String label) {
    final List<double> hourOptions = List.generate(
      41,
      (index) => (index * 0.25),
    );

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: (val) {
            controller.text = val;
          },
          itemBuilder: (context) => hourOptions
              .map(
                (e) => PopupMenuItem<String>(
                  value: e.toStringAsFixed(2),
                  child: Text(e.toStringAsFixed(2)),
                ),
              )
              .toList(),
        ),
      ),
      onTap: () {
        if (controller.text == '0.0') controller.clear();
      },
      onChanged: (_) => _calculateKmAndHours(),
      validator: (val) {
        final parsed = double.tryParse(val ?? '');
        if (parsed == null || parsed < 0 || parsed > 10) {
          return '0.0 – 10.0 only';
        }
        return null;
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "email": _email,
      "weekId": _weekId,
      "vehicleNumber": _vehicleController.text.trim(),
      "weeklyKmStart": int.tryParse(_startKmController.text) ?? 0,
      "weeklyKmEnd": int.tryParse(_endKmController.text) ?? 0,
      "weeklyKmTotal": _totalKm,
      "totalWeeklyHours": _totalWeeklyHours.toStringAsFixed(2),
      "specialNotes": _specialNotesController.text.trim(),
      "webform": true,
    };

    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    for (int i = 0; i < 7; i++) {
      data["${days[i]}Shift1TotalHours"] = _weeklyEntries[i]["am"]!.text.trim();
      data["${days[i]}Shift2TotalHours"] = _weeklyEntries[i]["pm"]!.text.trim();
      data["${days[i]}ExtraHours"] = _weeklyEntries[i]["extra"]!.text.trim();
    }

    try {
      final uri = Uri.parse(
        'https://52jvcflcuc.execute-api.ca-central-1.amazonaws.com/production/timesheet/submit',
      );
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Timesheet submitted successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _startKmController.dispose();
    _endKmController.dispose();
    _specialNotesController.dispose();
    for (var day in _weeklyEntries) {
      day.values.forEach((ctrl) => ctrl.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fill Timesheet Form"),
        backgroundColor: const Color(0xFF6A0DAD),
        foregroundColor: Colors.white,
      ),
      body: _weekId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  onChanged: _calculateKmAndHours,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Submit timesheets before Saturday 23:59",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Week ID: $_weekId",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Email: $_email"),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text("Enter Working Hours:"),
                      const SizedBox(height: 10),
                      for (int i = 0; i < 7; i++)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(days[i]),
                            Row(
                              children: [
                                Expanded(
                                  child: _hourField(
                                    _weeklyEntries[i]["am"]!,
                                    "AM Hours",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _hourField(
                                    _weeklyEntries[i]["pm"]!,
                                    "PM Hours",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _hourField(
                                    _weeklyEntries[i]["extra"]!,
                                    "Additional Hours",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startKmController,
                              decoration: const InputDecoration(
                                labelText: 'Start KM',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _endKmController,
                              decoration: const InputDecoration(
                                labelText: 'End KM',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Total KM: $_totalKm"),
                      const SizedBox(height: 10),
                      Text("Total Weekly Hours: $_totalWeeklyHours"),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Special Notes',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text("Submit Timesheet"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
