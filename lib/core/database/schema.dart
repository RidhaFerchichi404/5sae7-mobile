import 'package:sqflite/sqflite.dart';

/// Version 1 schema. A later version requires a team migration.
Future<void> createSchema(Database db) async {
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      currency TEXT NOT NULL DEFAULT 'TND',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK (type IN ('EXPENSE', 'INCOME')),
      icon TEXT NOT NULL,
      created_at TEXT NOT NULL,
      UNIQUE (user_id, name, type),
      FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      amount REAL NOT NULL CHECK (amount > 0),
      type TEXT NOT NULL CHECK (type IN ('EXPENSE', 'INCOME')),
      description TEXT,
      transaction_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      amount_limit REAL NOT NULL CHECK (amount_limit > 0),
      period TEXT NOT NULL CHECK (period IN ('MONTHLY', 'CUSTOM')),
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL CHECK (end_date >= start_date),
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
    )
  ''');

  await db.execute(
    'CREATE INDEX idx_transactions_user_date ON transactions (user_id, transaction_date)',
  );
  await db.execute(
    'CREATE INDEX idx_transactions_category ON transactions (category_id)',
  );
  await db.execute(
    'CREATE INDEX idx_transactions_user_type ON transactions (user_id, type)',
  );
  await db.execute(
    'CREATE INDEX idx_budgets_user_category ON budgets (user_id, category_id)',
  );
}
