@echo off
bundler\SqlBundler.exe ..\..\..\ "db/SQL Server/2.1.update" false
copy purchase-2.1.update.sql ..\purchase-2.1.update.sql