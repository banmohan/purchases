@echo off
bundler\SqlBundler.exe ..\..\..\..\ "db/PostgreSQL/2.x/2.0" false
copy purchase.sql purchase-blank.sql
del purchase.sql
copy purchase-blank.sql ..\..\purchase-blank.sql

pause