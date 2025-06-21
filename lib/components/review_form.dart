import 'package:flutter/material.dart';
import 'package:bikex/services/review_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ReviewForm extends StatefulWidget {
  final String restaurantId;
  final String? foodId;
  final Function? onReviewSubmitted;

  const ReviewForm({
    super.key,
    required this.restaurantId,
    this.foodId,
    this.onReviewSubmitted,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final ReviewService _reviewService = ReviewService();
  final _picker = ImagePicker();
  
  double _rating = 5.0;
  String _comment = '';
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          pickedFiles.map((e) => File(e.path)).toList(),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    
    for (var image in _selectedImages) {
      final fileName = path.basename(image.path);
      final destination = 'reviews/${widget.restaurantId}/$fileName';
      
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(image);
      
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
    }
    
    return imageUrls;
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          imageUrls = await _uploadImages();
        }
        
        await _reviewService.addReview(
          restaurantId: widget.restaurantId,
          foodId: widget.foodId,
          rating: _rating,
          comment: _comment,
          imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        );
        
        if (widget.onReviewSubmitted != null) {
          widget.onReviewSubmitted!();
        }
        
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Write a Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rating',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Star rating selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Your feedback',
                border: OutlineInputBorder(),
                hintText: 'Share your experience...',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your feedback';
                }
                if (value.trim().length < 5) {
                  return 'Review must be at least 5 characters';
                }
                return null;
              },
              onSaved: (value) {
                _comment = value!;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text('${_selectedImages.length} photos selected'),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
