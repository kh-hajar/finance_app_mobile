// Formulaire d'ajout et de modification d'une transaction

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class TransactionFormView extends StatefulWidget {
  const TransactionFormView({super.key});

  @override
  State<TransactionFormView> createState() => _TransactionFormViewState();
}

class _TransactionFormViewState extends State<TransactionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'expense';
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isEdit = false;
  TransactionModel? _existingTransaction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer la transaction si édition
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is TransactionModel && !_isEdit) {
      _isEdit = true;
      _existingTransaction = arg;
      _titleCtrl.text = arg.title;
      _amountCtrl.text = arg.amount.toString();
      _noteCtrl.text = arg.note ?? '';
      _type = arg.type;
      _selectedDate = arg.date;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final txCtrl = context.read<TransactionController>();
    final userId = auth.currentUser!.id!;

    final transaction = TransactionModel(
      id: _existingTransaction?.id,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
      type: _type,
      categoryId: _selectedCategory!.id!,
      categoryName: _selectedCategory!.name,
      categoryColor: _selectedCategory!.color,
      categoryIcon: _selectedCategory!.icon,
      date: _selectedDate,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      userId: userId,
    );

    bool success;
    if (_isEdit) {
      success = await txCtrl.updateTransaction(transaction);
    } else {
      success = await txCtrl.addTransaction(transaction);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEdit ? 'Transaction modifiée !' : 'Transaction ajoutée !'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final txCtrl = context.watch<TransactionController>();
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDarkMode;

    final categories = txCtrl.getCategoriesByType(_type);

    // Auto-sélectionner la catégorie si édition
    if (_isEdit && _selectedCategory == null && categories.isNotEmpty) {
      final match = categories.where(
          (c) => c.id == _existingTransaction?.categoryId);
      if (match.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => setState(() => _selectedCategory = match.first));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier' : 'Nouvelle transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text(
              _isEdit ? 'Modifier' : 'Ajouter',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélecteur type (revenu / dépense)
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surfaceDark
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _typeButton('expense', 'Dépense',
                          Icons.arrow_upward_rounded, AppTheme.expenseColor,
                          isDark),
                      _typeButton('income', 'Revenu',
                          Icons.arrow_downward_rounded, AppTheme.incomeColor,
                          isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Titre
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Titre / Description',
                    prefixIcon: Icon(Icons.title_rounded, size: 20),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Titre requis' : null,
                ),

                const SizedBox(height: 14),

                // Montant
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Montant',
                    prefixIcon:
                        const Icon(Icons.attach_money_rounded, size: 20),
                    suffixText: theme.currency,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Montant requis';
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Montant invalide';
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Date
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon:
                            const Icon(Icons.calendar_today_rounded, size: 20),
                        hintText: AppHelpers.formatDateShort(_selectedDate),
                      ),
                      controller: TextEditingController(
                          text: AppHelpers.formatDateShort(_selectedDate)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Catégorie
                Text(
                  'Catégorie',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 10),

                if (categories.isEmpty)
                  Text(
                    'Aucune catégorie disponible',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map((cat) => _categoryChip(cat, isDark))
                        .toList(),
                  ),

                const SizedBox(height: 20),

                // Note (optionnelle)
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optionnelle)',
                    prefixIcon: Icon(Icons.note_outlined, size: 20),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isEdit ? 'Modifier' : 'Ajouter la transaction'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String type, String label, IconData icon, Color color,
      bool isDark) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategory = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(isDark ? 0.25 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? color
                      : (isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(CategoryModel cat, bool isDark) {
    final isSelected = _selectedCategory?.id == cat.id;
    final color = AppHelpers.colorFromHex(cat.color);
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark
                  ? AppTheme.surfaceDark
                  : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppHelpers.getCategoryIcon(cat.icon),
              size: 14,
              color: isSelected
                  ? color
                  : (isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? color
                    : (isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}