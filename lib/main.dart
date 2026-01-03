import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MoneyTracerApp());
}

class MoneyTracerApp extends StatelessWidget {
  const MoneyTracerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracer',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const HomePage(),
    );
  }
}

class TransactionItem {
  DateTime date;
  String account;
  String type; // "in" or "out"
  int amount; // in IDR, integer
  String category;
  String note;

  TransactionItem({
    required this.date,
    required this.account,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'account': account,
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
      };

  static TransactionItem fromJson(Map<String, dynamic> j) => TransactionItem(
        date: DateTime.parse(j['date'] as String),
        account: j['account'] as String,
        type: j['type'] as String,
        amount: (j['amount'] as num).toInt(),
        category: j['category'] as String,
        note: j['note'] as String,
      );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TransactionItem> _transactions = [];
  String? _selectedAccount;
  final _prefsKey = 'transactions';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _transactions = list
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortTransactions();
      // initialize selected account to first ascending
      final accounts = _uniqueAccounts();
      if (accounts.isNotEmpty) {
        _selectedAccount ??= accounts.first;
      }
      setState(() {});
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  int get balance {
    var sum = 0;
    for (final t in _transactions) {
      if (t.type == 'in') sum += t.amount;
      else sum -= t.amount;
    }
    return sum;
  }

  String formatCurrency(int v) {
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'IDR ', decimalDigits: 0);
    return f.format(v);
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.of(context).push<TransactionItem?>(
      MaterialPageRoute(
          builder: (_) => AddTransactionPage(
                existingAccounts: _uniqueAccounts(),
                existingCategories: _uniqueCategories(),
              )),
    );
    if (result != null) {
      setState(() {
        _transactions.insert(0, result);
        _sortTransactions();
      });
      await _saveTransactions();
    }
  }

  Future<void> _editTransaction(int index) async {
    final existing = _transactions[index];
    final result = await Navigator.of(context).push<TransactionItem?>(
      MaterialPageRoute(
          builder: (_) => AddTransactionPage(
                existing: existing,
                existingAccounts: _uniqueAccounts(),
                existingCategories: _uniqueCategories(),
              )),
    );
    if (result != null) {
      setState(() {
        _transactions[index] = result;
        _sortTransactions();
      });
      await _saveTransactions();
    }
  }

  List<String> _uniqueAccounts() {
    final s = _transactions.map((t) => t.account).toSet().toList();
    s.sort((a, b) => a.compareTo(b));
    return s;
  }

  List<String> _uniqueCategories() {
    final s = _transactions.map((t) => t.category).toSet().toList();
    s.sort((a, b) => a.compareTo(b));
    return s;
  }

  Future<void> _deleteTransaction(int index) async {
    final removed = _transactions.removeAt(index);
    setState(() {});
    await _saveTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted: ${removed.category} ${formatCurrency(removed.amount)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Money Tracer')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.teal[50],
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(formatCurrency(balance), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Transaksi', style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 6),
                    Text('${_transactions.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                )
              ],
            ),
          ),
          // Account filter selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Filter Rekening: '),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(builder: (ctx) {
                    final accounts = _uniqueAccounts();
                    if (accounts.isEmpty) {
                      return const Text('Tidak ada rekening');
                    }
                    // ensure selectedAccount has default
                    _selectedAccount ??= accounts.first;
                    return DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedAccount,
                      items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _selectedAccount = v),
                    );
                  }),
                )
              ],
            ),
          ),
          Expanded(
            child: _filteredTransactions().isEmpty
                ? const Center(child: Text('Belum ada transaksi. Tekan + untuk menambah.'))
                : ListView.separated(
                    itemCount: _filteredTransactions().length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final t = _filteredTransactions()[index];
                      final realIndex = _transactions.indexOf(t);
                      return Dismissible(
                        key: ValueKey(t.date.toIso8601String() + t.amount.toString() + t.category),
                        direction: DismissDirection.endToStart,
                        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 16), child: const Icon(Icons.delete, color: Colors.white)),
                        onDismissed: (_) => _deleteTransaction(realIndex),
                        child: ListTile(
                          title: Text(t.category),
                          subtitle: Text('${t.account} • ${DateFormat.yMMMd().add_jm().format(t.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (t.type == 'in' ? '+ ' : '- ') + formatCurrency(t.amount),
                                style: TextStyle(color: t.type == 'in' ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') await _editTransaction(realIndex);
                                  if (v == 'delete') await _deleteTransaction(realIndex);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                ],
                              )
                            ],
                          ),
                          onTap: () async => await _editTransaction(realIndex),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTransactionPage extends StatefulWidget {
  final TransactionItem? existing;
  final List<String> existingAccounts;
  final List<String> existingCategories;

  const AddTransactionPage({Key? key, this.existing, this.existingAccounts = const [], this.existingCategories = const []}) : super(key: key);

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  String _account = '';
  String _type = 'out';
  String _amount = '';
  String _category = '';
  String _note = '';

  late final List<String> _accountOptions;
  late final List<String> _categoryOptions;

  @override
  void initState() {
    super.initState();
    _accountOptions = List<String>.from(widget.existingAccounts);
    _categoryOptions = List<String>.from(widget.existingCategories);
    if (widget.existing != null) {
      final e = widget.existing!;
      _date = e.date;
      _account = e.account;
      _type = e.type;
      _amount = e.amount.toString();
      _category = e.category;
      _note = e.note;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final time = TimeOfDay.fromDateTime(_date);
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked != null) {
      setState(() => _date = DateTime(_date.year, _date.month, _date.day, picked.hour, picked.minute));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final amountInt = int.tryParse(_amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final tx = TransactionItem(
      date: _date,
      account: _account,
      type: _type,
      amount: amountInt,
      category: _category,
      note: _note,
    );
    Navigator.of(context).pop(tx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _pickDate,
                      child: Text(DateFormat.yMMMd().format(_date)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _pickTime,
                      child: Text(DateFormat.Hm().format(_date)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Rekening with suggestions from previous entries
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _account),
                optionsBuilder: (textEditingValue) {
                  final q = textEditingValue.text.toLowerCase();
                  return _accountOptions.where((a) => a.toLowerCase().contains(q));
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _account;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Rekening Sumber'),
                    onSaved: (v) => _account = v?.trim() ?? '',
                    validator: (v) => (v == null || v.isEmpty) ? 'Masukkan rekening' : null,
                  );
                },
                onSelected: (s) => _account = s,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'in', child: Text('Pemasukan (in)')),
                  DropdownMenuItem(value: 'out', child: Text('Pengeluaran (out)')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'out'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nominal (IDR)', prefixText: 'IDR '),
                keyboardType: TextInputType.number,
                onSaved: (v) => _amount = v ?? '0',
                validator: (v) => (v == null || v.isEmpty) ? 'Masukkan nominal' : null,
              ),
              const SizedBox(height: 8),
              // Category with suggestions
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _category),
                optionsBuilder: (textEditingValue) {
                  final q = textEditingValue.text.toLowerCase();
                  return _categoryOptions.where((c) => c.toLowerCase().contains(q));
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _category;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Category'),
                    onSaved: (v) => _category = v?.trim() ?? '',
                    validator: (v) => (v == null || v.isEmpty) ? 'Masukkan kategori' : null,
                  );
                },
                onSelected: (s) => _category = s,
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Catatan'),
                onSaved: (v) => _note = v?.trim() ?? '',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _submit, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }
}
