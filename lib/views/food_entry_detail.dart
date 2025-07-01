import 'package:flutter/material.dart';

class FoodEntryDetailPage extends StatefulWidget {
  final Map<String, dynamic> entry;

  const FoodEntryDetailPage({Key? key, required this.entry}) : super(key: key);

  @override
  State<FoodEntryDetailPage> createState() => _FoodEntryDetailPageState();
}

class _FoodEntryDetailPageState extends State<FoodEntryDetailPage> {
  late String? imageUrl;

  @override
  void initState() {
    super.initState();
    imageUrl = widget.entry['imageUrl'];
    print('imageUrl: $imageUrl');
  }

  void _editImageUrl() async {
    final controller = TextEditingController(text: imageUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter image URL'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        imageUrl = result;
        widget.entry['imageUrl'] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Food Detail', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 160,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Icon(Icons.image, size: 60, color: Colors.grey[400]),
                              );
                            },
                          )
                        : Container(
                            height: 160,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 60, color: Colors.grey[400]),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _editImageUrl,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.edit, size: 20, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.entry['name'] ?? 'Food Name',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Nutrition value:', style: TextStyle(color: Colors.black38)),
                  const SizedBox(width: 8),
                  const Text('100g', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  Text('${widget.entry['kcal']} kcal', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 18),
              _NutritionBar(
                icon: Icons.eco,
                label: 'Protein',
                value: widget.entry['protein']?.toDouble() ?? 0,
                max: 30,
                color: Colors.green,
                unit: 'g',
              ),
              const SizedBox(height: 12),
              _NutritionBar(
                icon: Icons.shopping_basket,
                label: 'Carbs',
                value: widget.entry['carbs']?.toDouble() ?? 0,
                max: 30,
                color: Colors.orange,
                unit: 'g',
              ),
              const SizedBox(height: 12),
              _NutritionBar(
                icon: Icons.bubble_chart,
                label: 'Fat',
                value: widget.entry['fats']?.toDouble() ?? 0,
                max: 30,
                color: Colors.purple,
                unit: 'g',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.black),
                  const SizedBox(width: 8),
                  Text('Edit Entry', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Note: Calorie estimation by camera could not be accurate, double-check amounts.',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double max;
  final Color color;
  final String unit;

  const _NutritionBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: (value / max).clamp(0.0, 1.0) * MediaQuery.of(context).size.width * 0.55,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('${value.toStringAsFixed(1)}$unit', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}