import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/data_provider.dart';

enum FilterType { restan, panen, pengiriman }

class FilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onApplyFilters;
  final VoidCallback onClearFilters;
  final FilterType filterType;
  final Map<String, dynamic> currentFilters;

  const FilterDialog({
    Key? key,
    required this.onApplyFilters,
    required this.onClearFilters,
    required this.filterType,
    required this.currentFilters,
  }) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Map<String, dynamic> _filters;
  late TextEditingController _dateFromController;
  late TextEditingController _dateToController;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
    _dateFromController = TextEditingController(
        text: _filters['startDate'] != null 
            ? _filters['startDate'].toString().split(' ')[0] 
            : '');
    _dateToController = TextEditingController(
        text: _filters['endDate'] != null 
            ? _filters['endDate'].toString().split(' ')[0] 
            : '');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Filter Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Note: Afdeling, Blok, dan Tanggal sekarang di Global Filter
                      if (widget.filterType != FilterType.restan) 
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, 
                                   size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filter Afdeling, Blok, dan Tanggal tersedia di Filter Global di atas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.filterType != FilterType.restan) 
                        const SizedBox(height: 16),
                      
                      if (widget.filterType == FilterType.panen) ...[
                        _buildPemanenFilter(),
                        const SizedBox(height: 16),
                        _buildKeraniFilter(),
                        const SizedBox(height: 16),
                      ],
                      if (widget.filterType == FilterType.pengiriman) ...[
                        _buildKendaraanFilter(),
                        const SizedBox(height: 16),
                        _buildKeraniFilter(),
                        const SizedBox(height: 16),
                      ],
                      if (widget.filterType == FilterType.restan) ...[
                        _buildAfdelingFilter(),
                        const SizedBox(height: 16),
                        _buildBlokFilter(),
                        const SizedBox(height: 16),
                        _buildDateRangeFilter(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAfdelingFilter() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        List<String> availableAfdelings = [];
        
        switch (widget.filterType) {
          case FilterType.panen:
            availableAfdelings = dataProvider.getPanenAfdelings();
            break;
          case FilterType.pengiriman:
            availableAfdelings = dataProvider.getPengirimanAfdelings();
            break;
          case FilterType.restan:
            availableAfdelings = dataProvider.getRestanAfdelings();
            break;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Afdeling',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _filters['afdeling'],
              decoration: const InputDecoration(
                hintText: 'Pilih afdeling',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Semua Afdeling'),
                ),
                ...availableAfdelings.map((afdeling) => DropdownMenuItem<String>(
                  value: afdeling,
                  child: Text(afdeling),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filters['afdeling'] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlokFilter() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        List<String> availableBloks = [];
        
        switch (widget.filterType) {
          case FilterType.panen:
            availableBloks = dataProvider.getPanenBloks();
            break;
          case FilterType.pengiriman:
            availableBloks = dataProvider.getPengirimanBloks();
            break;
          case FilterType.restan:
            availableBloks = dataProvider.getRestanBloks();
            break;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blok',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _filters['blok'],
              decoration: const InputDecoration(
                hintText: 'Pilih blok',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grid_view),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Semua Blok'),
                ),
                ...availableBloks.map((blok) => DropdownMenuItem<String>(
                  value: blok,
                  child: Text(blok),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filters['blok'] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPemanenFilter() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final availablePemanen = dataProvider.getPanenPemanen();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pemanen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _filters['pemanen'],
              decoration: const InputDecoration(
                hintText: 'Pilih nama pemanen',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Semua Pemanen'),
                ),
                ...availablePemanen.map((pemanen) => DropdownMenuItem<String>(
                  value: pemanen,
                  child: Text(pemanen),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filters['pemanen'] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildKendaraanFilter() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final availableKendaraan = dataProvider.getPengirimanKendaraan();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nomor Kendaraan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _filters['kendaraan'],
              decoration: const InputDecoration(
                hintText: 'Pilih nomor kendaraan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Semua Kendaraan'),
                ),
                ...availableKendaraan.map((kendaraan) => DropdownMenuItem<String>(
                  value: kendaraan,
                  child: Text(kendaraan),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filters['kendaraan'] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rentang Tanggal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _dateFromController,
                decoration: const InputDecoration(
                  hintText: 'Dari tanggal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dateToController,
                decoration: const InputDecoration(
                  hintText: 'Sampai tanggal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        final dateStr = picked.toIso8601String().split('T')[0];
        if (isStartDate) {
          _dateFromController.text = dateStr;
          _filters['startDate'] = picked;
        } else {
          _dateToController.text = dateStr;
          _filters['endDate'] = picked;
        }
      });
    }
  }

  Widget _buildKeraniFilter() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        List<String> availableKerani = [];
        
        switch (widget.filterType) {
          case FilterType.panen:
            availableKerani = dataProvider.getPanenKerani();
            break;
          case FilterType.pengiriman:
            availableKerani = dataProvider.getPengirimanKerani();
            break;
          case FilterType.restan:
            // Restan tidak memiliki filter kerani
            availableKerani = [];
            break;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kerani',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _filters['kerani'],
              decoration: const InputDecoration(
                hintText: 'Pilih nama kerani',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Semua Kerani'),
                ),
                ...availableKerani.map((kerani) => DropdownMenuItem<String>(
                  value: kerani,
                  child: Text(kerani),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _filters['kerani'] = value;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    widget.onApplyFilters(_filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _filters.clear();
      _dateFromController.clear();
      _dateToController.clear();
    });
    widget.onClearFilters();
    Navigator.pop(context);
  }
}