import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text("Inventory", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.green),
            onPressed: () {
              // TODO: Implement barcode scanner function
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Medicines...",
                prefixIcon: Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 10),

            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Tablets", "Syrups", "Injections"]
                    .map((category) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ChoiceChip(
                            label: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                            selected: selectedCategory == category,
                            selectedColor: Colors.green,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 10),

            // Medicine List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No medicines found"));
                  }

                  final medicines = snapshot.data!.docs;

                  // Filter medicines based on search and category
                  final filteredMedicines = medicines.where((medicine) {
                    final name = medicine['name'].toString().toLowerCase();
                    final query = _searchController.text.toLowerCase();
                    final categoryMatch = selectedCategory == "All" || medicine['category'] == selectedCategory;
                    return name.contains(query) && categoryMatch;
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = filteredMedicines[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Icon(Icons.medication, color: Colors.green, size: 30),
                          title: Text(medicine['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Stock: ${medicine['stock']} | Expiry: ${medicine['expiry']}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showEditMedicineDialog(medicine);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteMedicine(medicine);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: Icon(Icons.add),
        label: Text("Add Medicine"),
        onPressed: () {
          _showAddMedicineDialog();
        },
      ),
    );
  }

  // Function to add a new medicine
  void _showAddMedicineDialog() {
  TextEditingController nameController = TextEditingController();
  TextEditingController stockController = TextEditingController();
  TextEditingController expiryController = TextEditingController();
  TextEditingController lowStockThresholdController = TextEditingController(text: "10"); // Default value
  String selectedCategory = "Tablets";

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Add Medicine"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
          TextField(controller: stockController, decoration: InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
          TextField(controller: expiryController, decoration: InputDecoration(labelText: "Expiry (MM/YYYY)")),
          TextField(controller: lowStockThresholdController, decoration: InputDecoration(labelText: "Low Stock Threshold"), keyboardType: TextInputType.number),
          DropdownButtonFormField(
            value: selectedCategory,
            items: ["Tablets", "Syrups", "Injections"].map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              selectedCategory = value!;
            },
            decoration: InputDecoration(labelText: "Category"),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance.collection('medicines').add({
              "name": nameController.text,
              "stock": int.parse(stockController.text),
              "expiry": expiryController.text,
              "category": selectedCategory,
              "lowStockThreshold": int.parse(lowStockThresholdController.text), // Add lowStockThreshold
            });
            Navigator.pop(context);
          },
          child: Text("Add"),
        ),
      ],
    ),
  );
}

  // Function to edit a medicine
  void _showEditMedicineDialog(DocumentSnapshot medicine) {
    TextEditingController nameController = TextEditingController(text: medicine['name']);
    TextEditingController stockController = TextEditingController(text: medicine['stock'].toString());
    TextEditingController expiryController = TextEditingController(text: medicine['expiry']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Medicine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: stockController, decoration: InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
            TextField(controller: expiryController, decoration: InputDecoration(labelText: "Expiry (MM/YYYY)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await medicine.reference.update({
                "name": nameController.text,
                "stock": int.parse(stockController.text),
                "expiry": expiryController.text,
              });
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // Function to delete a medicine
  void _deleteMedicine(DocumentSnapshot medicine) async {
    await medicine.reference.delete();
  }
}