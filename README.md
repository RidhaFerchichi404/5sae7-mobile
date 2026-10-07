<p align="center">
  <img src="documentation/images/logo-esprit.png" alt="ESPRIT" width="320">
</p>

<h1 align="center">MyBudget</h1>

<p align="center"><strong>Gestion des dépenses personnelles</strong><br>5SAE7, ESPRIT School of Engineering</p>

MyBudget is an offline Android application for personal finance. A local profile records income and expenses, organises them by category, sets a spending limit, and shows the situation on a dashboard.

Profiles, categories, transactions, budgets, the dashboard, and statistics are implemented. Every figure is calculated when a screen opens. Nothing extra is stored. Behaviour is defined in the cahier des charges. The build order is defined in the development plan.

## Documentation

| Document | Role |
| --- | --- |
| [Cahier des charges](documentation/CAHIER_DES_CHARGES.md) | Scope, database, architecture, diagrams, and acceptance |
| [Development plan](documentation/DEVELOPMENT_PLAN.md) | Phases, module ownership, Git workflow, tests, and demo |
| [Screen mockups](documentation/MOCKUPS.md) | Phone screens for every feature |

## Stack

- Flutter and Dart
- SQLite through `sqflite`
- Riverpod
- Offline only

The database contains exactly four tables: `users`, `categories`, `transactions`, and `budgets`.

## Team

Four developers. Each developer owns one table and the full module around it: model, data access, business rules, screens, state, and tests.

| Developer | Module |
| --- | --- |
| Developer 1 | Users |
| Developer 2 | Categories |
| Developer 3 | Transactions |
| Developer 4 | Budgets |

The dashboard and statistics read those four modules. They do not own a table.

## Features

- A profile stores a name, an email, and a currency label. Creating one inserts 13 categories.
- Categories cover expenses and income. A category that is still in use must be reassigned before it can be deleted.
- Transactions are income or expenses. History can be searched, filtered, and sorted.
- Budgets limit an expense category for a month or a custom range. Spent, remaining, and the warning state are calculated from expenses.
- The dashboard shows balance, this month, remaining budget, warnings, category spending, and recent transactions.
- Statistics show a selected month, a six-month series, the most expensive category, and budget consumption.

## Run the app

Fetch packages, then run on an Android device or emulator:

    flutter pub get
    flutter run

The database file is created on the device. Automated tests use an in-memory database.

## Testing

    flutter analyze
    flutter test

## Known limitations

- There is no cloud sync, no notifications, and no currency conversion. Changing the currency label does not rewrite amounts already stored.
- The app is for one device. The email does not sign the person in.
- Category icons come from a fixed catalogue.
- Statistics cover six months ending on the selected month.
- Overlapping budgets for the same category are rejected in domain code.
- Android is the acceptance target.
