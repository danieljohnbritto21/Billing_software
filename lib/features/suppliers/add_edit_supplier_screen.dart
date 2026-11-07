import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import 'supplier_repository.dart';

class AddEditSupplierScreen extends ConsumerStatefulWidget {
  final String? supplierId;

  const AddEditSupplierScreen({super.key, this.supplierId});

  @override
  ConsumerState<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends ConsumerState<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _paymentTermsController = TextEditingController(text: 'Net 30');
  final _notesController = TextEditingController();

  // Portal Credentials (only for new suppliers)
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createPortalAccount = false;
  bool _obscurePassword = true;

  bool _isLoading = false;
  SupplierEntry? _existingSupplier;

  @override
  void initState() {
    super.initState();
    if (widget.supplierId != null) {
      _loadSupplier();
    }
  }

  Future<void> _loadSupplier() async {
    setState(() => _isLoading = true);
    final s = await ref.read(supplierRepositoryProvider).getSupplierById(widget.supplierId!);
    if (s != null && mounted) {
      setState(() {
        _existingSupplier = s;
        _nameController.text = s.name;
        _contactPersonController.text = s.contactPerson ?? '';
        _phoneController.text = s.phone ?? '';
        _emailController.text = s.email ?? '';
        _addressController.text = s.address ?? '';
        _gstinController.text = s.gstin ?? '';
        _panController.text = s.pan ?? '';
        _paymentTermsController.text = s.paymentTerms ?? 'Net 30';
        _notesController.text = s.notes ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final repo = ref.read(supplierRepositoryProvider);

    try {
      if (_existingSupplier != null) {
        await repo.updateSupplier(
          id: _existingSupplier!.id,
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          gstin: _gstinController.text.trim().toUpperCase(),
          pan: _panController.text.trim().toUpperCase(),
          paymentTerms: _paymentTermsController.text.trim(),
          notes: _notesController.text.trim(),
        );
      } else {
        await repo.createSupplier(
          name: _nameController.text.trim(),
          contactPerson: _contactPersonController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          gstin: _gstinController.text.trim().toUpperCase(),
          pan: _panController.text.trim().toUpperCase(),
          paymentTerms: _paymentTermsController.text.trim(),
          notes: _notesController.text.trim(),
          username: _createPortalAccount ? _usernameController.text.trim() : null,
          password: _createPortalAccount ? _passwordController.text : null,
        );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existingSupplier != null
                ? 'Supplier updated successfully'
                : 'Supplier created successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save supplier: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingSupplier != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Supplier' : 'Add New Supplier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Business Details
                    _buildSectionHeader('Business Information'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Company Name *',
                        hintText: 'e.g. Apex Food Ingredients Pvt Ltd',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Company name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person Name',
                        hintText: 'e.g. Rahul Sharma',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '+91 9876543210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'orders@vendor.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Registered Address / Warehouse',
                        hintText: 'Plot 42, Industrial Area, Bangalore',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Tax & Financial Terms
                    _buildSectionHeader('Tax & Payment Terms'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _gstinController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'GSTIN (15 chars)',
                              hintText: '29ABCDE1234F1Z5',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _panController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'PAN Number (10 chars)',
                              hintText: 'ABCDE1234F',
                              prefixIcon: Icon(Icons.credit_card_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _paymentTermsController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Terms',
                        hintText: 'e.g. Net 15, Net 30, Due on Receipt',
                        prefixIcon: Icon(Icons.handshake_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Internal Notes',
                        hintText: 'Bank details, delivery cutoffs, minimum order quantities...',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Portal Login Account (when creating)
                    if (!isEditing) ...[
                      _buildSectionHeader('Supplier Portal Access'),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Create Supplier Portal Login Account',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                            'Enables the supplier to login and view purchase orders, submit invoices, and track payments'),
                        value: _createPortalAccount,
                        activeColor: AppTheme.primaryGreen,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _createPortalAccount = val),
                      ),
                      if (_createPortalAccount) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Portal Username *',
                            hintText: 'e.g. apexfoods',
                            prefixIcon: Icon(Icons.account_circle_outlined),
                          ),
                          validator: (v) {
                            if (_createPortalAccount && (v == null || v.trim().isEmpty)) {
                              return 'Username required for portal account';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Portal Password *',
                            hintText: 'Minimum 6 characters',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (_createPortalAccount && (v == null || v.length < 6)) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    // Save Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleSave,
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Supplier',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }
}
