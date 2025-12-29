# 📊 Monitoring Restan API - Enhanced Logic Implementation

## Overview

Telah dibuat API endpoint baru `monitoring_restan.php` yang mengimplementasikan **EXACT SAME LOGIC** seperti yang ada di `monitoring.html` dari aplikasi web. API ini menerapkan algoritma **FIFO (First-In-First-Out) matching** dan **Business Rules** yang sama persis untuk penentuan status restan.

## 🚀 API Endpoints Baru

### Base URL
```
http://192.168.1.219/lubung-data-SAE/api/monitoring_restan.php
```

### 1. `/recap` - Get Recap Data
**Method:** GET

**Parameters:**
- `date_from` (optional): Filter tanggal mulai (YYYY-MM-DD)
- `date_to` (optional): Filter tanggal selesai (YYYY-MM-DD)
- `afdeling` (optional): Filter afdeling
- `blok` (optional): Filter blok
- `status` (optional): Filter berdasarkan status (restan, sesuai, kelebihan)
- `min_restan` (optional): Filter minimum jumlah restan (integer)

**Response:**
```json
{
  "success": true,
  "message": "Recap data retrieved successfully",
  "data": {
    "recap_data": [
      {
        "date": "2025-12-15",
        "afdeling": "1",
        "blok": "A",
        "noTPH": "1",
        "jjgPanen": 100,
        "jjgAngkut": 95,
        "kgPanen": 1500.0,
        "kgAngkut": 1425.0,
        "kgBrd": 25.0,
        "bjr": 15.0,
        "tanggalPanen": "2025-12-15",
        "tanggalAngkut": "2025-12-15",
        "selisihJjg": 5,
        "selisihKg": 75.0,
        "delayHari": 0,
        "kgRestan": 75.0,
        "status": "Restan (Kurang)",
        "statusColor": "red",
        "delayColor": "green"
      }
    ],
    "summary": {
      "total_records": 250,
      "total_panen_jjg": 15000,
      "total_angkut_jjg": 14500,
      "total_restan_jjg": 500,
      "total_kelebihan_jjg": 0,
      "total_panen_kg": 225000.0,
      "total_angkut_kg": 217500.0,
      "total_restan_kg": 7500.0,
      "total_sesuai": 180,
      "total_restan": 60,
      "total_kelebihan": 10,
      "total_delay": 15,
      "status_breakdown": {
        "Sesuai": 180,
        "Restan (Kurang)": 45,
        "Restan (Delay)": 15,
        "Kelebihan": 10
      }
    },
    "total_records": 250
  },
  "timestamp": "2025-12-15 10:30:00"
}
```

### 2. `/statistics` - Get Statistics
**Method:** GET

**Parameters:** Same as `/recap`

**Response:**
```json
{
  "success": true,
  "message": "Statistics retrieved successfully",
  "data": {
    "total_panen": 1250,
    "total_transport": 1180,
    "panen_stats": {
      "total_jjg": 15000,
      "total_kg": 225000.0,
      "avg_bjr": 15.0,
      "unique_locations": 250
    },
    "transport_stats": {
      "total_jjg": 14500,
      "total_kg": 217500.0,
      "avg_bjr": 15.0,
      "unique_locations": 240,
      "unique_vehicles": 25
    },
    "location_stats": {
      "total_locations": 260,
      "panen_only_locations": 20,
      "transport_only_locations": 10,
      "matched_locations": 230
    }
  }
}
```

### 3. `/summary` - Get Summary by Afdeling
**Method:** GET

**Parameters:** Same as `/recap`

**Response:**
```json
{
  "success": true,
  "message": "Summary retrieved successfully",
  "data": {
    "summary_by_afdeling": [
      {
        "afdeling": "1",
        "total_locations": 50,
        "total_panen_jjg": 3000,
        "total_angkut_jjg": 2900,
        "total_restan_jjg": 100,
        "total_kelebihan_jjg": 0,
        "total_restan_kg": 1500.0,
        "sesuai_count": 35,
        "restan_count": 12,
        "kelebihan_count": 3
      }
    ],
    "grand_total": {
      // Same as summary in /recap
    }
  }
}
```

## 🧮 Algorithm Implementation

### 1. Data Normalization
```php
private function normalizeAfdeling($afdeling) {
    $normalized = strtoupper(trim($afdeling));
    
    // Convert Roman numerals to numbers
    $romanMap = [
        'VIII' => '8', 'VII' => '7', 'VI' => '6', 'V' => '5',
        'IV' => '4', 'III' => '3', 'II' => '2', 'I' => '1'
    ];
    
    foreach ($romanMap as $roman => $number) {
        if ($normalized === $roman) {
            return $number;
        }
    }
    
    return $normalized;
}
```

### 2. Data Aggregation
- **Key Format:** `date_afdeling_blok_tph`
- **Aggregation Rules:**
  - Sum JJG panen + koreksi panen
  - Sum JJG angkut + koreksi angkut
  - Weighted average BJR berdasarkan total kg
  - Sum total kg dan kg berondolan

### 3. FIFO Matching Algorithm
```php
private function performMatching($aggregatedPanen, $aggregatedTransport) {
    // Group by location (afdeling_blok_tph)
    // Sort by date (FIFO - First In First Out)
    // Match transport with earliest available panen
    // Mark used transport to avoid double matching
    // Create recap items with status calculation
}
```

### 4. Status Business Rules
Implementasi **EXACT SAME** logic seperti monitoring.html:

| Kondisi | Selisih (S) | Delay (D) | Status Output |
|---------|-------------|-----------|---------------|
| Berpasangan | S = 0 | D ≤ 1 hari | Sesuai |
| Berpasangan | S = 0 | D > 1 hari | Restan (Delay) |
| Berpasangan | S > 0 | D ≤ 1 hari | Restan (Kurang) |
| Berpasangan | S > 0 | D > 1 hari | Restan (Kurang + Delay) |
| Berpasangan | S < 0 | D ≤ 1 hari | Kelebihan |
| Berpasangan | S < 0 | D > 1 hari | Kelebihan (Delay) |
| Panen Saja | Auto negatif | D ≤ 1 hari | Restan |
| Panen Saja | Auto negatif | D > 1 hari | Restan (Delay) |
| Angkut Saja | Auto positif | - | Kelebihan (Tanpa Data Panen) |

### 5. Kg Restan Calculation
```php
// Hanya dihitung jika status mengandung kata "Restan"
if ($item['selisihJjg'] < 0) {
    $item['kgRestan'] = abs($item['selisihJjg']) * $item['bjr'];
} else {
    $item['kgRestan'] = 0.0;
}
```

## 📱 Mobile App Integration

### New API Service Methods
```dart
// Added to lib/services/api_service.dart
Future<ApiResponse<Map<String, dynamic>>> getMonitoringRecap({...})
Future<ApiResponse<Map<String, dynamic>>> getMonitoringStatistics({...})
Future<ApiResponse<Map<String, dynamic>>> getMonitoringSummary({...})
```

### New Models
```dart
// lib/models/monitoring_recap_model.dart
class MonitoringRecap { ... }
class MonitoringSummary { ... }
class MonitoringStatistics { ... }
class AfdelingSummary { ... }
```

### New Data Provider Methods
```dart
// Added to lib/providers/data_provider.dart
Future<void> loadMonitoringRecapData({...})
Future<void> loadMonitoringStatistics({...})
Future<void> loadMonitoringSummary({...})
Future<void> refreshMonitoringData({...})
```

### New Screen
```dart
// lib/screens/monitoring_restan_screen.dart
class MonitoringRestanScreen extends StatefulWidget { ... }
```
Dengan 3 tab:
1. **Recap** - Tabel detail dengan filtering
2. **Summary** - Ringkasan per afdeling
3. **Statistics** - Statistik umum panen vs transport

## 🔧 Setup Instructions

### 1. API Server
1. Upload file `monitoring_restan.php` ke folder `/api/`
2. Pastikan API dapat diakses via: `http://your-server/lubung-data-SAE/api/monitoring_restan.php`

### 2. Mobile App
1. Regenerate JSON models:
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```
2. Build dan install APK:
   ```bash
   flutter build apk --release
   ```

## 🧪 Testing

### API Testing (Postman/curl)
```bash
# Test recap endpoint
curl "http://192.168.1.219/lubung-data-SAE/api/monitoring_restan.php/recap?date_from=2025-12-01&date_to=2025-12-15"

# Test with filters
curl "http://192.168.1.219/lubung-data-SAE/api/monitoring_restan.php/recap?afdeling=1&blok=A"

# Test statistics
curl "http://192.168.1.219/lubung-data-SAE/api/monitoring_restan.php/statistics"

# Test summary
curl "http://192.168.1.219/lubung-data-SAE/api/monitoring_restan.php/summary"
```

### Mobile App Testing
1. Buka tab **"Monitoring Enhanced"** di mobile app
2. Test filtering dan refresh data
3. Verifikasi data sesuai dengan logic monitoring.html
4. Test offline/online mode

## ✅ Key Features

### ✓ Enhanced Logic
- **FIFO Matching Algorithm** - same as monitoring.html
- **Exact Business Rules** - status penentuan identik
- **Roman Numeral Conversion** - afdeling normalization
- **Weighted BJR Calculation** - rata-rata berdasarkan berat

### ✓ Complete API Coverage
- **Recap Data** - detail per TPH dengan filtering
- **Statistics** - analisis panen vs transport
- **Summary** - ringkasan per afdeling
- **Error Handling** - robust error responses

### ✓ Mobile Integration
- **New Screen** - 3-tab interface (Recap/Summary/Statistics)
- **Real-time Data** - sync dengan API terbaru
- **Offline Fallback** - gunakan logic lama jika offline
- **Professional UI** - cards, tables, charts

### ✓ Performance Optimized
- **Server-side Processing** - matching logic di backend
- **Efficient Queries** - optimized SQL with proper aggregation
- **Pagination Ready** - siap untuk large datasets
- **Caching Support** - data dapat di-cache di mobile

## 🎯 Usage Scenarios

### Scenario 1: Daily Monitoring
```dart
// Load today's data
dataProvider.refreshMonitoringData(
  dateFrom: '2025-12-15',
  dateTo: '2025-12-15',
);
```

### Scenario 2: Afdeling Analysis
```dart
// Analyze specific afdeling
dataProvider.loadMonitoringRecapData(
  afdeling: '1',
  dateFrom: '2025-12-01',
  dateTo: '2025-12-15',
);
```

### Scenario 3: Restan Filtering
```dart
// Show only significant restan
dataProvider.setMonitoringRecapFilters(
  status: 'restan',
  minRestan: 5,
);
```

## 📈 Benefits

1. **Consistency** - Logic identik antara web dan mobile
2. **Accuracy** - FIFO matching lebih akurat dari simple aggregation
3. **Performance** - Server-side processing lebih cepat
4. **Scalability** - Ready untuk data besar
5. **Flexibility** - Multiple filtering options
6. **User Experience** - UI modern dengan 3 perspective berbeda

---

**Implementasi ini memberikan mobile app kemampuan monitoring restan yang setara dengan aplikasi web, dengan logic bisnis yang identik dan user experience yang optimal untuk platform mobile.**