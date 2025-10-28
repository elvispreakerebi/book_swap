import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../models/book_listing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _coverFile = File(picked.path);
      });
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
                              _coverFile == null) {
                            if (_coverFile == null) {
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
                          setState(() => _posting = true);
                          try {
                            final userId =
                                ''; // Use actual signed-in user id in real code
                            final coverUrl = await listingsProvider.uploadCover(
                              _coverFile!,
                            );
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
                          } catch (e) {
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
