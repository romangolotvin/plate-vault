@echo off
set Path=E:\dev\flutter\bin;%Path%
set PUB_CACHE=E:\dev\pub-cache
set GRADLE_USER_HOME=E:\dev\gradle
set TMP=E:\dev\tmp
set TEMP=E:\dev\tmp
if not exist E:\dev\pub-cache mkdir E:\dev\pub-cache
if not exist E:\dev\gradle mkdir E:\dev\gradle
if not exist E:\dev\tmp mkdir E:\dev\tmp
if not exist E:\dev\builds mkdir E:\dev\builds
cd /d E:\dev\plate-vault
echo === flutter version === > E:\dev\builds\log.txt
call flutter --version >> E:\dev\builds\log.txt 2>&1
echo === pub get === >> E:\dev\builds\log.txt
call flutter pub get >> E:\dev\builds\log.txt 2>&1
echo PUB_EXIT=%ERRORLEVEL% >> E:\dev\builds\log.txt
echo === build apk === >> E:\dev\builds\log.txt
call flutter build apk --release >> E:\dev\builds\log.txt 2>&1
echo BUILD_EXIT=%ERRORLEVEL% >> E:\dev\builds\log.txt
if exist build\app\outputs\flutter-apk\app-release.apk (
  copy /Y build\app\outputs\flutter-apk\app-release.apk E:\dev\builds\plate-vault-release.apk >> E:\dev\builds\log.txt 2>&1
  echo APK_OK >> E:\dev\builds\log.txt
) else (
  echo APK_MISSING >> E:\dev\builds\log.txt
)
echo DONE >> E:\dev\builds\log.txt
