### Customizing the .motus database ###

The `motusClient` package is intended to be a minimal, stable layer for
fetching runs of tag detections in incremental batches from a provider
via the [upstream API](https://github.com/jbrzusto/motusClient/blob/master/inst/doc/upstream_api.md);
e.g. a server running the [motusServer](https://github.com/jbrzusto/motusServer) package.

The API includes entries for obtaining some metadata, but users of
motusClient will likely want to fetch metadata from elsewhere.  Also,
the structure and semantics of these need to be more flexible to
accomodate changing user needs.  So packages using `motusClient` will
sometimes need to make changes to the schema of .motus files, by
adding new columns, tables and views, and populating them.

### Hook functions ###

`motusClient` supports extending the .motus schema by a set of
function hooks, which can be used by packages to have their own
functions called at key points in the operation of the `motusClient`
functions.  A package can install a hook function at load-time by
including a line like:

``` R
    addHook("ensureDBTables", f)  ## `f` is the function in your package
```

to the `onLoad()` function of their own package. (For obscure R
packaging reasons, `onLoad` has to be defined in a source file
called z.onLoad.R)

More than one function can be installed on a hook; they will be
called in order of installation by the `motusClient` function.

The hook function `f` will be called just before the `motusClient`
package function returns, and `f` will be passed the same parameters
as were received by the `motusClient` function, but with a new first
parameter called `rv`, which is the return value the `motusClient` function
would have provided if there were no hook function.  The return value of `f`
becomes the return value of the `motusClient` function, so normally `f`
should simply return its `rv` parameter.  However, if the user package needs
to modify the return value, it can do so, and return the modified value.

Only a few `motusClient` functions have hooks so far, but more can
be added to support user needs.

### Hook example;  add a new table to .motus files ###


In user package file **`z.onload.R`**:

```R
   onLoad = function() {
      ...
      addHook("ensureDBTables", ensureMyTables)
      ...
   }
```

In user package file **`ensureMyTables.R`**:

``` R
   ensureMyTables = function(rv, src, projRecv, deviceID) {
      DBI::dbExecute(src$con,
         "CREATE TABLE IF NOT EXISTS tagLabels (
            motusTagID INTEGER PRIMARY KEY NOT NULL,
            label TEXT
         )"
      )
   return(rv)
   }
```

This ensures that whenever the user calls the `ensureDBTables()` function,
that the new function `ensureMyTables()` will also be called on the
same database, so that the `tagLabels` table will be created if it
doesn't already exist.

### Hook example;  add a new column to a .motus table ###

This example shows how the user package can add a new column `ambigProjectID` to
existing database table `tagAmbig`.

In user package file **`z.onload.R`**:

```R
   onLoad = function() {
      ...
      addHook("ensureDBTables", ensureMyColumns)
      ...
   }
```

In user package file **`ensureMyColumns.R`**:

``` R
   ensureMyColumns = function(rv, src, projRecv, deviceID) {
      if (0 == nrow(DBI::dbGetQuery("select * from sqlite_master where tbl_name='tagAmbig' and sql glob '* ambigProjectID *'"))) {
         DBI::dbExecute(src$con, "ALTER TABLE tagAmbig ADD COLUMN ambigProjectID INTEGER")
         )
      )
   return(rv)
   }
```

Function `ensureMyColumns` checks for existence of the column
"ambigProjectID" by querying the `sqlite_master` table.  That is a
system table present in every sqlite database which gives the sql
schema for each table, among other things.  The code checks whether
there's a record for a table named `tagAmbig` whose sql matches `*
ambigProjectID *` (asterisks represent any number of characters).  The
spaces on either side assure we're matching only the full word.  If
the `dbGetQuery` call doesn't return any rows, that means the schema
for the table doesn't include the column `ambigProjectID`, so
`ensureMyColumns` performs an appropriate `ALTER TABLE` query to add
it.
