import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../models/book_listing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PostBookScreen extends StatefulWidget {
  const PostBookScreen({super.key});
  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _swapForController = TextEditingController();
  final _descriptionController = TextEditingController();
  BookCondition? _selectedCondition;
  File? _coverFile;
  bool _posting = false;
  final CloudinaryService _cloudinary = CloudinaryService();
  XFile? _pickedXFile;

  Future<void> _pickImage() async {
    // Request permission before picking image
    PermissionStatus status;
    if (Theme.of(context).platform == TargetPlatform.android) {
      if (await Permission.photos.isGranted ||
          await Permission.storage.isGranted) {
        status = PermissionStatus.granted;
      } else {
        // On API 33+ use photos, else use storage
        status = await Permission.photos.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }
    } else {
      status = await Permission.photos.request();
    }
    if (status.isGranted) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _pickedXFile = picked;
          _coverFile = File(picked.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permission denied to access gallery. Please enable permission to pick images.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsProvider = Provider.of<BookListingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Complete the form below to list your book. Better info and images help your book get noticed.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please enter a book title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Please enter the author'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _swapForController,
                      decoration: const InputDecoration(
                        labelText: 'Swap For',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Enter what book/item you’d like to swap for'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BookCondition>(
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCondition,
                      items: BookCondition.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.name.replaceAll('LikeNew', 'Like New'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCondition = val),
                      validator: (val) =>
                          val == null ? 'Select a condition' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_coverFile != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _coverFile!,
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 18),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image, color: Colors.pink),
                            label: Text(
                              _coverFile == null
                                  ? 'Upload Cover Image'
                                  : 'Change Cover',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _posting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate() ||
                              _pickedXFile == null) {
                            if (_pickedXFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please upload a cover image for your book.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          // CHECK FILE EXISTENCE
                          bool exists = false;
                          try {
                            exists = await File(_pickedXFile!.path).exists();
                          } catch (e) {
                            exists = false;
                          }
                          if (!exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Selected image could not be found. Please pick an image again.',
                                ),
                              ),
                            );
                            setState(() => _posting = false);
                            return;
                          }
                          setState(() => _posting = true);
                          try {
                            // Use bytes for Cloudinary upload to support new Android OS
                            final imageBytes = await _pickedXFile!
                                .readAsBytes();
                            final coverUrl = await _cloudinary.uploadImageBytes(
                              imageBytes,
                              name: _pickedXFile!.name,
                            );
                            if (coverUrl == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to upload image to Cloudinary.',
                                  ),
                                ),
                              );
                              setState(() => _posting = false);
                              return;
                            }
                            final userId = '';
                            await listingsProvider.postListing(
                              title: _titleController.text.trim(),
                              author: _authorController.text.trim(),
                              swapFor: _swapForController.text.trim(),
                              condition: _selectedCondition!,
                              coverUrl: coverUrl,
                              description: _descriptionController.text.trim(),
                              ownerId: userId,
                            );
                            if (mounted) {
                              context.go('/home');
                            }
                          } catch (e, s) {
                            debugPrint('Cloudinary upload exception: $e');
                            debugPrint('Stack: $s');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to post: $e')),
                            );
                          } finally {
                            setState(() => _posting = false);
                          }
                        },
                  child: _posting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Post',
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
