import 'package:flutter/material.dart';

class TimesheetFormPage extends StatefulWidget {
  const TimesheetFormPage({super.key});

  @override
  State<TimesheetFormPage> createState() => _TimesheetFormPageState();
}

class _TimesheetFormPageState extends State<TimesheetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _employeeNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _startKmController = TextEditingController();
  final _endKmController = TextEditingController();
  int _totalKm = 0;

  final List<Map<String, TextEditingController>> _weeklyEntries = List.generate(
    7,
    (index) => {
      "am": TextEditingController(),
      "pm": TextEditingController(),
    },
  );

  @override
  void dispose() {
    _employeeNameController.dispose();
    _employeeIdController.dispose();
    _vehicleNumberController.dispose();
    _startKmController.dispose();
    _endKmController.dispose();
    for (var day in _weeklyEntries) {
      day["am"]!.dispose();
      day["pm"]!.dispose();
    }
    super.dispose();
  }

  void _calculateKilometers() {
    final start = int.tryParse(_startKmController.text.trim()) ?? 0;
    final end = int.tryParse(_endKmController.text.trim()) ?? 0;
    setState(() {
      _totalKm = end - start;
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Scaffold(
      appBar: AppBar(title: const Text("Fill Timesheet Form")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Submit timesheets before Saturday 23:59",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _employeeNameController,
                  decoration: const InputDecoration(labelText: 'Employee Name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(labelText: 'Employee ID'),
                ),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: const InputDecoration(labelText: 'Vehicle Number'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                const Text("Enter Working Hours (Split Shifts):"),
                const SizedBox(height: 8),
                const Text(
                  "Format: HH:mm-HH:mm (e.g. 08:00-12:00)",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < 7; i++)
                  Row(
                    children: [
                      SizedBox(width: 50, child: Text(days[i])),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _weeklyEntries[i]["am"],
                          decoration: const InputDecoration(labelText: 'AM Shift'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _weeklyEntries[i]["pm"],
                          decoration: const InputDecoration(labelText: 'PM Shift'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                const Text("Weekly Vehicle Kilometers:"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startKmController,
                        decoration: const InputDecoration(labelText: 'Start KM'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateKilometers(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _endKmController,
                        decoration: const InputDecoration(labelText: 'End KM'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateKilometers(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Total: $_totalKm KM"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Form Submitted!")),
                      );
                    }
                  },
                  child: const Text("Submit Timesheet"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
