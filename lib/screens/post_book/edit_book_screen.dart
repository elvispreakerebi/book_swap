import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../models/book_listing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';
import 'package:permission_handler/permission_handler.dart';

class EditBookScreen extends StatefulWidget {
  final String listingId;
  final BookListing? listing;
  const EditBookScreen({super.key, required this.listingId, this.listing});
  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _swapForController;
  late TextEditingController _descriptionController;
  BookCondition? _selectedCondition;
  File? _coverFile;
  bool _saving = false;
  final CloudinaryService _cloudinary = CloudinaryService();
  XFile? _pickedXFile;
  String? _originalCoverUrl;

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _titleController = TextEditingController(text: listing?.title ?? '');
    _authorController = TextEditingController(text: listing?.author ?? '');
    _swapForController = TextEditingController(text: listing?.swapFor ?? '');
    _descriptionController = TextEditingController(
      text: listing?.description ?? '',
    );
    _selectedCondition = listing?.condition;
    _originalCoverUrl = listing?.coverUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    PermissionStatus status;
    if (Theme.of(context).platform == TargetPlatform.android) {
      if (await Permission.photos.isGranted ||
          await Permission.storage.isGranted) {
        status = PermissionStatus.granted;
      } else {
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
        const SnackBar(content: Text('Permission denied to access gallery.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsProvider = Provider.of<BookListingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book Listing'),
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
                        'Update your book listing details. All fields are editable.',
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
                        if (_coverFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _coverFile!,
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (_originalCoverUrl != null &&
                            _originalCoverUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _originalCoverUrl!,
                              width: 60,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image, color: Colors.pink),
                            label: Text(
                              _coverFile == null
                                  ? 'Change Cover Image'
                                  : 'Replace Cover',
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
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _saving = true);
                          String? coverUrl = _originalCoverUrl;
                          try {
                            if (_pickedXFile != null) {
                              final imageBytes = await _pickedXFile!
                                  .readAsBytes();
                              final uploadedUrl = await _cloudinary
                                  .uploadImageBytes(
                                    imageBytes,
                                    name: _pickedXFile!.name,
                                  );
                              if (uploadedUrl != null) coverUrl = uploadedUrl;
                            }
                            await listingsProvider.updateListing(
                              id: widget.listingId,
                              title: _titleController.text.trim(),
                              author: _authorController.text.trim(),
                              swapFor: _swapForController.text.trim(),
                              condition: _selectedCondition!,
                              coverUrl: coverUrl ?? '',
                              description: _descriptionController.text.trim(),
                            );
                            if (mounted) {
                              context.go(
                                '/listing/${widget.listingId}',
                                extra: {'edited': true},
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save changes: $e'),
                              ),
                            );
                          } finally {
                            setState(() => _saving = false);
                          }
                        },
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
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
