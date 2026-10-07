#!/usr/bin/env bash
# Instala el APK en el telefono por ADB y lo lanza con argumentos de Godot; captura logcat filtrado.
# Uso: tools/adb_run.sh [--build] [--no-install] [--secs=N] [--out=FILE] -- <args de juego, p. ej. --bot --god --frametimes>
# En WSL usa adb.exe de Windows (el telefono esta en USB de Windows); en Linux nativo usa adb.
set -u
cd "$(dirname "$0")/.."
ADB=adb
WIN=/mnt/c/Users/Usuario/adb-win/platform-tools/adb.exe
[ -x "$WIN" ] && ADB="$WIN"
PKG=com.agustin.roguelikepremium
build=0; install=1; secs=40; out=/tmp/adb_run.log
while [ $# -gt 0 ]; do
  case "$1" in
    --build) build=1;; --no-install) install=0;; --secs=*) secs=${1#*=};; --out=*) out=${1#*=};;
    --) shift; break;;
  esac; shift
done
args="$*"
$ADB start-server >/dev/null 2>&1
$ADB devices | tr -d "\r" | grep -q "device$" || { echo "sin telefono autorizado"; exit 2; }
[ $build = 1 ] && godot --headless --path . --export-debug Android build/roguelike_premium.apk 2>&1 | grep -E "ERROR|DONE"
if [ $install = 1 ]; then
  if [ "$ADB" = "$WIN" ]; then cp build/roguelike_premium.apk /mnt/c/Users/Usuario/adb-win/rp.apk; $ADB install -r 'C:\Users\Usuario\adb-win\rp.apk' | tail -1
  else $ADB install -r build/roguelike_premium.apk | tail -1; fi
fi
$ADB shell am force-stop $PKG; $ADB logcat -c
if [ -n "$args" ]; then
  $ADB shell "echo '$args' > /data/local/tmp/ba.txt; run-as $PKG cp /data/local/tmp/ba.txt files/boot_args.txt" >/dev/null 2>&1
else
  $ADB shell "run-as $PKG rm -f files/boot_args.txt" >/dev/null 2>&1
fi
$ADB shell am start -n $PKG/com.godot.game.GodotAppLauncher >/dev/null
sleep "$secs"
PID=$($ADB shell pidof $PKG | tr -d '\r')
$ADB logcat -d ${PID:+--pid=$PID} > "$out" 2>&1
echo "pid=${PID:-MUERTO} log=$out ($(wc -l < "$out") lineas)"
grep -aE "FATAL|AndroidRuntime|signal [0-9]|SIGSEGV|ANR|ERROR:|SCRIPT ERROR|Failed|FRAMETIME|PERF|PREWARM|pico|\[BOOT|RESULTADO|FPS medio" "$out" | grep -avE "perfctl|HWUI|libmbrain|fbcNotify" | head -${LINES_MAX:-40}
