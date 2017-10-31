@echo off
bundler\SqlBundler.exe ..\..\..\ "db/PostgreSQL/2.1.update" false
copy purchase-2.1.update.sql ..\purchase-2.1.update.sql