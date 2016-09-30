@echo off
bundler\SqlBundler.exe ..\..\..\..\ "db/PostgreSQL/2.x/2.0" true
copy purchase.sql purchase-sample.sql
del purchase.sql
copy purchase-sample.sql ..\..\purchase-sample.sql