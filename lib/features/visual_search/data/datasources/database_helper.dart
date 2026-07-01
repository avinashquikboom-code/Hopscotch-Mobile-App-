import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database helper for visual search local storage
/// Manages SQLite database for products, images, signatures, and search history
class VisualSearchDatabaseHelper {
  static final VisualSearchDatabaseHelper instance = VisualSearchDatabaseHelper._init();
  static Database? _database;

  VisualSearchDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('visual_search.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        sizes TEXT NOT NULL,
        colors TEXT NOT NULL,
        rating REAL DEFAULT 0,
        rating_count INTEGER DEFAULT 0,
        stock INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Product images table
    await db.execute('''
      CREATE TABLE product_images (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        asset_path TEXT NOT NULL,
        is_primary INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Product image signatures table
    await db.execute('''
      CREATE TABLE product_image_signatures (
        image_id TEXT PRIMARY KEY,
        d_hash TEXT NOT NULL,
        hsv_histogram TEXT NOT NULL,
        computed_at TEXT NOT NULL,
        FOREIGN KEY (image_id) REFERENCES product_images(id) ON DELETE CASCADE
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id TEXT PRIMARY KEY,
        query_image_path TEXT NOT NULL,
        result_type TEXT NOT NULL,
        matched_product_id TEXT,
        top_score REAL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (matched_product_id) REFERENCES products(id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_product_images_product_id ON product_images(product_id)');
    await db.execute('CREATE INDEX idx_search_history_created_at ON search_history(created_at)');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
