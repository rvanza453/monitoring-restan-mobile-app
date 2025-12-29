import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/panen.dart';
import '../models/pengiriman.dart';
import '../utils/normalization_helper.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance ??= DatabaseHelper._internal();
  }

  Future<Database> get database async {
    // 1. Jika database sudah ada DAN dalam keadaan terbuka, pakai itu.
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    
    // 2. Jika database null ATAU sudah tertutup, inisialisasi ulang.
    print('🔄 Database connection was closed or null, re-initializing...');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'monitoring_restan.db');

    return await openDatabase(
      path,
      version: 5, // Increased version for koreksi fields
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabel untuk data panen
    await db.execute('''
      CREATE TABLE panen (
        id INTEGER PRIMARY KEY,
        upload_id INTEGER,
        nama_kerani TEXT NOT NULL,
        tanggal_pemeriksaan TEXT NOT NULL,
        afdeling TEXT NOT NULL,
        nama_pemanen TEXT NOT NULL,
        nik_pemanen TEXT NOT NULL,
        blok TEXT NOT NULL,
        no_ancak TEXT NOT NULL,
        no_tph TEXT NOT NULL,
        jam TEXT NOT NULL,
        last_modified TEXT NOT NULL,
        koordinat_lat REAL,
        koordinat_lng REAL,
        jumlah_janjang INTEGER NOT NULL,
        bjr REAL,
        kg_total REAL,
        kg_brd REAL DEFAULT 0.0,
        koreksi_panen INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // Tabel untuk data pengiriman
    await db.execute('''
      CREATE TABLE pengiriman (
        id INTEGER PRIMARY KEY,
        upload_id INTEGER,
        tipe_aplikasi TEXT,
        nama_kerani TEXT NOT NULL,
        nik_kerani TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        afdeling TEXT NOT NULL,
        nopol TEXT NOT NULL,
        nomor_kendaraan TEXT NOT NULL,
        blok TEXT NOT NULL,
        no_tph TEXT NOT NULL,
        jumlah_janjang INTEGER NOT NULL,
        waktu TEXT NOT NULL,
        koordinat_lat REAL,
        koordinat_lng REAL,
        kg_total REAL NOT NULL,
        bjr REAL,
        kg_brd REAL DEFAULT 0.0, -- Added kg_brd column for calculation
        koreksi_kirim INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // Tabel untuk metadata sync
    await db.execute('''
      CREATE TABLE sync_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        last_sync TEXT NOT NULL,
        total_records INTEGER DEFAULT 0
      )
    ''');

    // Insert initial sync metadata
    await db.insert('sync_metadata', {
      'table_name': 'panen',
      'last_sync': DateTime.now().toIso8601String(),
      'total_records': 0,
    });

    await db.insert('sync_metadata', {
      'table_name': 'pengiriman',
      'last_sync': DateTime.now().toIso8601String(),
      'total_records': 0,
    });

    print('📊 Database tables created successfully');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('🔄 Database upgrade from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Add BJR column to pengiriman table
      try {
        await db.execute('ALTER TABLE pengiriman ADD COLUMN bjr REAL');
        print('✅ Added BJR column to pengiriman table');
      } catch (e) {
        print('⚠️  BJR column might already exist: $e');
      }
    }

    if (oldVersion < 3) {
      // Add kg_brd column to pengiriman table
      try {
        await db.execute(
          'ALTER TABLE pengiriman ADD COLUMN kg_brd REAL DEFAULT 0.0',
        );
        print('✅ Added kg_brd column to pengiriman table');
      } catch (e) {
        print('⚠️  kg_brd column might already exist: $e');
      }

      // Add new columns to panen table
      try {
        await db.execute('ALTER TABLE panen ADD COLUMN bjr REAL');
        await db.execute('ALTER TABLE panen ADD COLUMN kg_total REAL');
        await db.execute(
          'ALTER TABLE panen ADD COLUMN kg_brd REAL DEFAULT 0.0',
        );
        print('✅ Added bjr, kg_total, kg_brd columns to panen table');
      } catch (e) {
        print('⚠️  New panen columns might already exist: $e');
      }

      // Rename kg column to kg_total in pengiriman table if needed
      try {
        // Check if we need to rename kg to kg_total
        var tableInfo = await db.rawQuery('PRAGMA table_info(pengiriman)');
        bool hasKgColumn = tableInfo.any((col) => col['name'] == 'kg');
        bool hasKgTotalColumn = tableInfo.any(
          (col) => col['name'] == 'kg_total',
        );

        if (hasKgColumn && !hasKgTotalColumn) {
          // Create new table with correct structure
          await db.execute('''
            CREATE TABLE pengiriman_new (
              id INTEGER PRIMARY KEY,
              upload_id INTEGER,
              tipe_aplikasi TEXT,
              nama_kerani TEXT NOT NULL,
              nik_kerani TEXT NOT NULL,
              tanggal TEXT NOT NULL,
              afdeling TEXT NOT NULL,
              nopol TEXT NOT NULL,
              nomor_kendaraan TEXT NOT NULL,
              blok TEXT NOT NULL,
              no_tph TEXT NOT NULL,
              jumlah_janjang INTEGER NOT NULL,
              waktu TEXT NOT NULL,
              koordinat_lat REAL,
              koordinat_lng REAL,
              kg_total REAL NOT NULL,
              bjr REAL,
              kg_brd REAL DEFAULT 0.0,
              created_at TEXT NOT NULL,
              synced_at TEXT
            )
          ''');

          // Copy data from old table to new table
          await db.execute('''
            INSERT INTO pengiriman_new 
            SELECT id, upload_id, tipe_aplikasi, nama_kerani, nik_kerani, tanggal, 
                   afdeling, nopol, nomor_kendaraan, blok, no_tph, jumlah_janjang, 
                   waktu, koordinat_lat, koordinat_lng, kg as kg_total, bjr, kg_brd, 
                   created_at, synced_at
            FROM pengiriman
          ''');

          // Drop old table and rename new table
          await db.execute('DROP TABLE pengiriman');
          await db.execute('ALTER TABLE pengiriman_new RENAME TO pengiriman');

          print('✅ Renamed kg column to kg_total in pengiriman table');
        }
      } catch (e) {
        print('⚠️  Error during kg to kg_total migration: $e');
      }
    }

    if (oldVersion < 5) {
      // Add koreksi columns to both tables
      try {
        await db.execute('ALTER TABLE panen ADD COLUMN koreksi_panen INTEGER DEFAULT 0');
        print('✅ Added koreksi_panen column to panen table');
      } catch (e) {
        print('⚠️  koreksi_panen column might already exist: $e');
      }

      try {
        await db.execute('ALTER TABLE pengiriman ADD COLUMN koreksi_kirim INTEGER DEFAULT 0');
        print('✅ Added koreksi_kirim column to pengiriman table');
      } catch (e) {
        print('⚠️  koreksi_kirim column might already exist: $e');
      }
    }
  }

  // Method to clear database and force recreation
  Future<void> clearDatabaseAndRecreate() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'monitoring_restan.db');

    // Close current database
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the database file
    await deleteDatabase(path);
    print('🗑️  Database deleted and will be recreated');

    // Next database call will recreate it
  }



  // PANEN CRUD Operations

  Future<int> insertPanen(Panen panen) async {
    final db = await database;
    final map = panen.toMap();
    map['synced_at'] = DateTime.now().toIso8601String();

    return await db.insert(
      'panen',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> insertMultiplePanen(List<Panen> panenList) async {
    final db = await database;
    final batch = db.batch();
    final syncedAt = DateTime.now().toIso8601String();

    for (final panen in panenList) {
      final map = panen.toMap();
      map['synced_at'] = syncedAt;
      batch.insert('panen', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    final results = await batch.commit();
    await _updateSyncMetadata('panen', panenList.length);
    return results.cast<int>();
  }

  Future<List<Panen>> getAllPanen({
    String? search,
    String? afdeling,
    String? blok,
    String? pemanen,
    String? kerani,
    String? dateFrom,
    String? dateTo,
    int? limit,
    int? offset,
    String sortBy = 'tanggal_pemeriksaan',
    String sortDirection = 'DESC',
  }) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    // Build WHERE clause
    List<String> conditions = [];

    if (search != null && search.isNotEmpty) {
      conditions.add(
        '(nama_kerani LIKE ? OR nama_pemanen LIKE ? OR blok LIKE ? OR no_tph LIKE ?)',
      );
      final searchTerm = '%$search%';
      whereArgs.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
    }

    if (afdeling != null && afdeling.isNotEmpty) {
      // Normalize both stored and filter value (I -> 1)
      conditions.add(
        'LOWER(REPLACE(afdeling, "I", "1")) LIKE LOWER(REPLACE(?, "I", "1"))',
      );
      whereArgs.add('%$afdeling%');
    }

    if (blok != null && blok.isNotEmpty) {
      // Use normalization to handle A1 vs A01, B2 vs B02, etc.
      // Normalize the filter value to get the target format (e.g., "B2")
      final normalizedBlok = NormalizationHelper.normalizeBlok(blok);
      
      // Query with LIKE to catch variations, then we'll filter in Dart
      // This catches: B2, B02, B 2, b2, etc.
      final prefix = normalizedBlok.replaceAll(RegExp(r'\d+'), ''); // Extract letters
      final numberPart = normalizedBlok.replaceAll(RegExp(r'[A-Z]+'), ''); // Extract numbers
      
      if (prefix.isNotEmpty && numberPart.isNotEmpty) {
        // Match any variation: prefix followed by optional leading zeros and the number
        // Pattern: B2, B02, B002, B 2, etc.
        conditions.add('UPPER(TRIM(REPLACE(blok, " ", ""))) LIKE ?');
        whereArgs.add('$prefix%$numberPart');
      } else {
        // Fallback: exact match with normalization
        conditions.add('UPPER(TRIM(REPLACE(blok, " ", ""))) = ?');
        whereArgs.add(normalizedBlok);
      }
    }

    if (pemanen != null && pemanen.isNotEmpty) {
      conditions.add('LOWER(nama_pemanen) LIKE LOWER(?)');
      whereArgs.add('%$pemanen%');
    }

    if (kerani != null && kerani.isNotEmpty) {
      conditions.add('LOWER(nama_kerani) LIKE LOWER(?)');
      whereArgs.add('%$kerani%');
    }

    if (dateFrom != null) {
      conditions.add('tanggal_pemeriksaan >= ?');
      whereArgs.add(dateFrom);
    }

    if (dateTo != null) {
      conditions.add('tanggal_pemeriksaan <= ?');
      whereArgs.add(dateTo);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    String query =
        '''
      SELECT * FROM panen 
      $whereClause 
      ORDER BY $sortBy $sortDirection
    ''';

    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    var result = maps.map((map) => Panen.fromMap(map)).toList();
    
    // Apply normalization filter in Dart to handle B2 vs B02, A1 vs A01, etc.
    if (blok != null && blok.isNotEmpty) {
      final normalizedBlok = NormalizationHelper.normalizeBlok(blok);
      result = result.where((panen) {
        final normalizedPanenBlok = NormalizationHelper.normalizeBlok(panen.blok);
        return normalizedPanenBlok == normalizedBlok;
      }).toList();
      
      // Debug: Log query results for troubleshooting
      print('🔍 Query Panen with blok filter "$blok" (normalized: "$normalizedBlok"): Found ${result.length} records after normalization');
      if (result.isEmpty) {
        // Check what bloks actually exist in database
        final allBloks = await db.rawQuery('SELECT DISTINCT blok FROM panen LIMIT 20');
        final normalizedBloks = allBloks.map((r) => NormalizationHelper.normalizeBlok(r['blok'] as String?)).toSet().toList();
        print('📋 Available normalized bloks in database: $normalizedBloks');
      }
    }
    
    return result;
  }

  Future<Panen?> getPanenById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'panen',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Panen.fromMap(maps.first);
    }
    return null;
  }

  Future<int> getPanenCount({
    String? search,
    String? afdeling,
    String? dateFrom,
    String? dateTo,
  }) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    List<String> conditions = [];

    if (search != null && search.isNotEmpty) {
      conditions.add(
        '(nama_kerani LIKE ? OR nama_pemanen LIKE ? OR blok LIKE ? OR no_tph LIKE ?)',
      );
      final searchTerm = '%$search%';
      whereArgs.addAll([searchTerm, searchTerm, searchTerm, searchTerm]);
    }

    if (afdeling != null && afdeling.isNotEmpty) {
      conditions.add('afdeling LIKE ?');
      whereArgs.add('%$afdeling%');
    }

    if (dateFrom != null) {
      conditions.add('tanggal_pemeriksaan >= ?');
      whereArgs.add(dateFrom);
    }

    if (dateTo != null) {
      conditions.add('tanggal_pemeriksaan <= ?');
      whereArgs.add(dateTo);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM panen $whereClause',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  Future<int> deletePanen(int id) async {
    final db = await database;
    return await db.delete('panen', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllPanen() async {
    final db = await database;
    final result = await db.delete('panen');
    await _updateSyncMetadata('panen', 0);
    return result;
  }

  // PENGIRIMAN CRUD Operations

  Future<int> insertPengiriman(Pengiriman pengiriman) async {
    final db = await database;
    final map = pengiriman.toMap();
    map['synced_at'] = DateTime.now().toIso8601String();

    return await db.insert(
      'pengiriman',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<int>> insertMultiplePengiriman(
    List<Pengiriman> pengirimanList,
  ) async {
    final db = await database;
    final batch = db.batch();
    final syncedAt = DateTime.now().toIso8601String();

    for (final pengiriman in pengirimanList) {
      final map = pengiriman.toMap();
      map['synced_at'] = syncedAt;
      batch.insert(
        'pengiriman',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    await _updateSyncMetadata('pengiriman', pengirimanList.length);
    return results.cast<int>();
  }

  Future<List<Pengiriman>> getAllPengiriman({
    String? search,
    String? afdeling,
    String? blok,
    String? kendaraan,
    String? kerani,
    String? dateFrom,
    String? dateTo,
    int? limit,
    int? offset,
    String sortBy = 'tanggal',
    String sortDirection = 'DESC',
  }) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    List<String> conditions = [];

    if (search != null && search.isNotEmpty) {
      conditions.add(
        '(LOWER(nama_kerani) LIKE LOWER(?) OR LOWER(nopol) LIKE LOWER(?) OR LOWER(nomor_kendaraan) LIKE LOWER(?) OR LOWER(blok) LIKE LOWER(?) OR LOWER(no_tph) LIKE LOWER(?))',
      );
      final searchTerm = '%$search%';
      whereArgs.addAll([
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
      ]);
    }

    if (afdeling != null && afdeling.isNotEmpty) {
      // Normalize both stored and filter value (I -> 1)
      conditions.add(
        'LOWER(REPLACE(afdeling, "I", "1")) LIKE LOWER(REPLACE(?, "I", "1"))',
      );
      whereArgs.add('%$afdeling%');
    }

    if (blok != null && blok.isNotEmpty) {
      // Use normalization to handle A1 vs A01, B2 vs B02, etc.
      // Normalize the filter value to get the target format (e.g., "B2")
      final normalizedBlok = NormalizationHelper.normalizeBlok(blok);
      
      // Query with LIKE to catch variations, then we'll filter in Dart
      // This catches: B2, B02, B002, B 2, etc.
      final prefix = normalizedBlok.replaceAll(RegExp(r'\d+'), ''); // Extract letters
      final numberPart = normalizedBlok.replaceAll(RegExp(r'[A-Z]+'), ''); // Extract numbers
      
      if (prefix.isNotEmpty && numberPart.isNotEmpty) {
        // Match any variation: prefix followed by optional leading zeros and the number
        // Pattern: B2, B02, B002, B 2, etc.
        conditions.add('UPPER(TRIM(REPLACE(blok, " ", ""))) LIKE ?');
        whereArgs.add('$prefix%$numberPart');
      } else {
        // Fallback: exact match with normalization
        conditions.add('UPPER(TRIM(REPLACE(blok, " ", ""))) = ?');
        whereArgs.add(normalizedBlok);
      }
    }

    if (kendaraan != null && kendaraan.isNotEmpty) {
      conditions.add(
        '(LOWER(nopol) LIKE LOWER(?) OR LOWER(nomor_kendaraan) LIKE LOWER(?))',
      );
      final kendaraanTerm = '%$kendaraan%';
      whereArgs.addAll([kendaraanTerm, kendaraanTerm]);
    }

    if (kerani != null && kerani.isNotEmpty) {
      conditions.add('LOWER(nama_kerani) LIKE LOWER(?)');
      whereArgs.add('%$kerani%');
    }

    if (dateFrom != null) {
      conditions.add('tanggal >= ?');
      whereArgs.add(dateFrom);
    }

    if (dateTo != null) {
      conditions.add('tanggal <= ?');
      whereArgs.add(dateTo);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    String query =
        '''
      SELECT * FROM pengiriman 
      $whereClause 
      ORDER BY $sortBy $sortDirection
    ''';

    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
    var result = maps.map((map) => Pengiriman.fromMap(map)).toList();
    
    // Apply normalization filter in Dart to handle B2 vs B02, A1 vs A01, etc.
    if (blok != null && blok.isNotEmpty) {
      final normalizedBlok = NormalizationHelper.normalizeBlok(blok);
      result = result.where((pengiriman) {
        final normalizedPengirimanBlok = NormalizationHelper.normalizeBlok(pengiriman.blok);
        return normalizedPengirimanBlok == normalizedBlok;
      }).toList();
      
      // Debug: Log query results for troubleshooting
      print('🔍 Query Pengiriman with blok filter "$blok" (normalized: "$normalizedBlok"): Found ${result.length} records after normalization');
      if (result.isEmpty) {
        // Check what bloks actually exist in database
        final allBloks = await db.rawQuery('SELECT DISTINCT blok FROM pengiriman LIMIT 20');
        final normalizedBloks = allBloks.map((r) => NormalizationHelper.normalizeBlok(r['blok'] as String?)).toSet().toList();
        print('📋 Available normalized bloks in database: $normalizedBloks');
      }
    }
    
    return result;
  }

  Future<Pengiriman?> getPengirimanById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pengiriman',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Pengiriman.fromMap(maps.first);
    }
    return null;
  }

  Future<int> getPengirimanCount({
    String? search,
    String? afdeling,
    String? dateFrom,
    String? dateTo,
  }) async {
    final db = await database;
    String whereClause = '';
    List<String> whereArgs = [];

    List<String> conditions = [];

    if (search != null && search.isNotEmpty) {
      conditions.add(
        '(nama_kerani LIKE ? OR nopol LIKE ? OR nomor_kendaraan LIKE ? OR blok LIKE ? OR no_tph LIKE ?)',
      );
      final searchTerm = '%$search%';
      whereArgs.addAll([
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
        searchTerm,
      ]);
    }

    if (afdeling != null && afdeling.isNotEmpty) {
      conditions.add('afdeling LIKE ?');
      whereArgs.add('%$afdeling%');
    }

    if (dateFrom != null) {
      conditions.add('tanggal >= ?');
      whereArgs.add(dateFrom);
    }

    if (dateTo != null) {
      conditions.add('tanggal <= ?');
      whereArgs.add(dateTo);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pengiriman $whereClause',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  Future<int> deletePengiriman(int id) async {
    final db = await database;
    return await db.delete('pengiriman', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllPengiriman() async {
    final db = await database;
    final result = await db.delete('pengiriman');
    await _updateSyncMetadata('pengiriman', 0);
    return result;
  }

  // UTILITY Methods

  Future<void> _updateSyncMetadata(String tableName, int totalRecords) async {
    final db = await database;
    await db.update(
      'sync_metadata',
      {
        'last_sync': DateTime.now().toIso8601String(),
        'total_records': totalRecords,
      },
      where: 'table_name = ?',
      whereArgs: [tableName],
    );
  }

  Future<Map<String, dynamic>?> getSyncMetadata(String tableName) async {
    final db = await database;
    final result = await db.query(
      'sync_metadata',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final panenCount = await db.rawQuery('SELECT COUNT(*) as count FROM panen');
    final pengirimanCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pengiriman',
    );

    return {
      'panen': panenCount.first['count'] as int,
      'pengiriman': pengirimanCount.first['count'] as int,
    };
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('panen');
    await db.delete('pengiriman');
    await db.update('sync_metadata', {
      'last_sync': DateTime.now().toIso8601String(),
      'total_records': 0,
    });
  }



  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Method untuk menutup database
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
