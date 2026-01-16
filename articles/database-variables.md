# Database Variables

## Variables

This table lists all variables present in .motus SQLite databases.

**Notes:**

- `Variable Name` refers to the name of a variable (column/field) in a
  table
- `Table Name` reflects the tables (actual database tables) where that
  variable can be found
- `View`s refer to the database ‘views’ where that variable can be found
  (views do not contain data themselves, but show data collected and
  arranged from various tables)
- `Variable Name in View` reflects the name of the variable in a view.
  Variables often are given new names in views
  - e.g., `alt` is a variable in the `gps` table, but when put into the
    `alltagsGPS` view, it is called `gpsAlt`
- `Creation Comments` are specific comments about how a particular
  variable was created. This applies mostly to variables which are
  created on the fly, or, might come for different tables.

> Use the Search bar to narrow results down to a particular variable
> (e.g., `latitude`), table (e.g., `recvDeps`), or view (e.g.,
> `alltags`)

> **What Next?** [Explore all
> articles](https://motuswts.github.io/motus/articles/index.md)
