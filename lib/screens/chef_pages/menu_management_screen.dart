import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bikex/models/menu_item.dart';
import 'package:bikex/services/menu_service.dart';

class MenuManagementScreen extends StatefulWidget {
  final String restaurantId;

  const MenuManagementScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MenuService _menuService = MenuService();
  List<String> _categories = ['All'];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final categories = await _menuService.getRestaurantCategories(widget.restaurantId);
      
      setState(() {
        _categories = ['All', ...categories];
        _tabController = TabController(length: _categories.length, vsync: this);
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddItemDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditMenuItemScreen(
          restaurantId: widget.restaurantId,
          onItemAdded: () {
            _loadCategories(); // Refresh categories after adding an item
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'Refresh menu',
          ),
        ],
        bottom: _isLoading 
          ? null 
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _categories.map((category) => Tab(text: category)).toList(),
              onTap: (index) {
                setState(() {
                  _selectedCategory = _categories[index];
                });
              },
            ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<MenuItem>>(
              stream: _selectedCategory == 'All'
                  ? _menuService.getRestaurantMenuItems(widget.restaurantId)
                  : _menuService.getMenuItemsByCategory(widget.restaurantId, _selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                final menuItems = snapshot.data ?? [];
                
                if (menuItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory == 'All'
                              ? 'No menu items found'
                              : 'No items in $_selectedCategory',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddItemDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Item'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menu item image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            child: Image.network(
                              item.imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 50),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (item.isFeatured)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Featured',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '\$${item.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: item.discountPercentage != null
                                                ? Colors.grey
                                                : Colors.black,
                                            decoration: item.discountPercentage != null
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        if (item.discountPercentage != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '\$${item.finalPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${item.discountPercentage!.toInt()}% off)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item.isAvailable ? 'Available' : 'Unavailable',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => AddEditMenuItemScreen(
                                                restaurantId: widget.restaurantId,
                                                menuItem: item,
                                                onItemAdded: () {
                                                  _loadCategories();
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          try {
                                            await _menuService.toggleItemAvailability(
                                              item.id,
                                              !item.isAvailable,
                                            );
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  item.isAvailable
                                                      ? 'Item marked as unavailable'
                                                      : 'Item marked as available',
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          item.isAvailable
                                              ? Icons.toggle_off
                                              : Icons.toggle_on,
                                        ),
                                        label: Text(
                                          item.isAvailable
                                              ? 'Mark Unavailable'
                                              : 'Mark Available',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          try {
                                            await _menuService.toggleItemFeatured(
                                              item.id,
                                              !item.isFeatured,
                                            );
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  item.isFeatured
                                                      ? 'Item removed from featured'
                                                      : 'Item added to featured',
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          item.isFeatured
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: item.isFeatured ? Colors.amber : null,
                                        ),
                                        label: Text(
                                          item.isFeatured
                                              ? 'Remove Featured'
                                              : 'Make Featured',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Item'),
                                              content: Text(
                                                'Are you sure you want to delete ${item.name}?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('CANCEL'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: const Text('DELETE'),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirm == true) {
                                            try {
                                              await _menuService.deleteMenuItem(item.id);
                                              
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Item deleted'),
                                                ),
                                              );
                                              
                                              _loadCategories();
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        label: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        tooltip: 'Add new menu item',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEditMenuItemScreen extends StatefulWidget {
  final String restaurantId;
  final MenuItem? menuItem;
  final Function onItemAdded;

  const AddEditMenuItemScreen({
    super.key,
    required this.restaurantId,
    this.menuItem,
    required this.onItemAdded,
  });

  @override
  State<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _discountController = TextEditingController();
  
  final MenuService _menuService = MenuService();
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isFeatured = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.menuItem != null) {
      _nameController.text = widget.menuItem!.name;
      _descriptionController.text = widget.menuItem!.description;
      _priceController.text = widget.menuItem!.price.toString();
      _categoryController.text = widget.menuItem!.category;
      _isFeatured = widget.menuItem!.isFeatured;
      if (widget.menuItem!.discountPercentage != null) {
        _discountController.text = widget.menuItem!.discountPercentage.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Implementation will be added when we update the pubspec.yaml
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (widget.menuItem == null && _selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        final name = _nameController.text;
        final description = _descriptionController.text;
        final price = double.parse(_priceController.text);
        final category = _categoryController.text;
        double? discount;
        
        if (_discountController.text.isNotEmpty) {
          discount = double.parse(_discountController.text);
        }
        
        if (widget.menuItem == null) {
          // Creating a new menu item
          await _menuService.addMenuItem(
            name: name,
            description: description,
            price: price,
            category: category,
            imageFile: _selectedImage!,
            restaurantId: widget.restaurantId,
            discountPercentage: discount,
            isFeatured: _isFeatured,
          );
          
          widget.onItemAdded();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item added successfully')),
          );
        } else {
          // Updating existing menu item
          await _menuService.updateMenuItem(
            itemId: widget.menuItem!.id,
            name: name,
            description: description,
            price: price,
            category: category,
            imageFile: _selectedImage,
            discountPercentage: discount,
            isFeatured: _isFeatured,
          );
          
          widget.onItemAdded();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item updated successfully')),
          );
        }
        
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuItem == null ? 'Add Menu Item' : 'Edit Menu Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image selection
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.menuItem != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              widget.menuItem!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.image_not_supported, size: 50),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.add_a_photo, size: 50),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      try {
                        final price = double.parse(value);
                        if (price <= 0) {
                          return 'Price must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final discount = double.parse(value);
                          if (discount < 0 || discount > 100) {
                            return 'Discount must be between 0-100%';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                hintText: 'e.g., Appetizers, Main Course, Desserts',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Feature this item'),
              subtitle: const Text('Featured items appear at the top of the menu'),
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : Text(widget.menuItem == null ? 'Add Item' : 'Update Item'),
            ),
          ],
        ),
      ),
    );
  }
}
