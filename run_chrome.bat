@echo off
if not exist "D:\temp" mkdir "D:\temp"
set TEMP=D:\temp
set TMP=D:\temp
flutter run -d chrome --web-port 8080 --web-hostname 127.0.0.1
