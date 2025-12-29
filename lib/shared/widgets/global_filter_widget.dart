import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data_provider.dart';

class GlobalFilterButton extends StatelessWidget {
  const GlobalFilterButton({Key? key}) : super(key: key);

  void _showGlobalFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GlobalFilterDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final hasFilters = dataProvider.globalSelectedAfdeling != null ||
            dataProvider.globalSelectedBlok != null ||
            dataProvider.globalDateFrom != null ||
            dataProvider.globalDateTo != null;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasFilters
                  ? [Colors.green[400]!, Colors.green[600]!]
                  : [Colors.grey[400]!, Colors.grey[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (hasFilters ? Colors.green : Colors.grey).withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showGlobalFilterDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasFilters ? Icons.filter_alt : Icons.filter_list,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasFilters ? 'Filter Global (aktif)' : 'Filter Global',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (hasFilters) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AKTIF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlobalFilterDialog extends StatefulWidget {
  @override
  State<GlobalFilterDialog> createState() => _GlobalFilterDialogState();
}

class _GlobalFilterDialogState extends State<GlobalFilterDialog> {
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  
  String? _selectedAfdeling;
  String? _selectedBlok;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    final dataProvider = context.read<DataProvider>();
    _selectedAfdeling = dataProvider.globalSelectedAfdeling;
    _selectedBlok = dataProvider.globalSelectedBlok;
    _dateFromController.text = dataProvider.globalDateFrom ?? '';
    _dateToController.text = dataProvider.globalDateTo ?? '';
  }

  void _applyFilters() {
    final dataProvider = context.read<DataProvider>();
    dataProvider.setGlobalFilters(
      afdeling: _selectedAfdeling,
      blok: _selectedBlok,
      dateFrom: _dateFromController.text.isEmpty ? null : _dateFromController.text,
      dateTo: _dateToController.text.isEmpty ? null : _dateToController.text,
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedAfdeling = null;
      _selectedBlok = null;
      _dateFromController.clear();
      _dateToController.clear();
    });
    
    final dataProvider = context.read<DataProvider>();
    dataProvider.clearGlobalFilters();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Filter Global',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Filter ini akan diterapkan ke semua tab (Panen, Pengiriman, Monitoring Restan)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Afdeling Filter
                    _buildFilterSection(
                      'Afdeling',
                      Icons.location_city,
                      Consumer<DataProvider>(
                        builder: (context, dataProvider, child) {
                          List<String> afdelingOptions = [];
                          try {
                            afdelingOptions = dataProvider.getPanenAfdelings();
                            if (afdelingOptions.isEmpty) {
                              afdelingOptions = dataProvider.getPengirimanAfdelings();
                            }
                          } catch (e) {
                            print('Error getting afdeling options: $e');
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedAfdeling,
                            decoration: InputDecoration(
                              labelText: 'Pilih Afdeling',
                              prefixIcon: Icon(Icons.location_city, color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Semua Afdeling'),
                              ),
                              ...afdelingOptions.map((String afdeling) {
                                return DropdownMenuItem<String>(
                                  value: afdeling,
                                  child: Text(afdeling),
                                );
                              }).toList(),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                _selectedAfdeling = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Blok Filter
                    _buildFilterSection(
                      'Blok',
                      Icons.grid_view,
                      Consumer<DataProvider>(
                        builder: (context, dataProvider, child) {
                          List<String> blokOptions = [];
                          try {
                            blokOptions = dataProvider.getPanenBloks();
                            if (blokOptions.isEmpty) {
                              blokOptions = dataProvider.getPengirimanBloks();
                            }
                          } catch (e) {
                            print('Error getting blok options: $e');
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedBlok,
                            decoration: InputDecoration(
                              labelText: 'Pilih Blok',
                              prefixIcon: Icon(Icons.grid_view, color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Semua Blok'),
                              ),
                              ...blokOptions.map((String blok) {
                                return DropdownMenuItem<String>(
                                  value: blok,
                                  child: Text(blok),
                                );
                              }).toList(),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                _selectedBlok = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date range filters
                    _buildFilterSection(
                      'Rentang Tanggal',
                      Icons.calendar_today,
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dateFromController,
                              decoration: InputDecoration(
                                labelText: 'Dari',
                                prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Colors.green[600]!,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dateFromController.text = 
                                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _dateToController,
                              decoration: InputDecoration(
                                labelText: 'Sampai',
                                prefixIcon: Icon(Icons.event, color: Colors.grey[600], size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Colors.green[600]!,
                                          onPrimary: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dateToController.text = 
                                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer dengan buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.check),
                      label: const Text('Terapkan Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}