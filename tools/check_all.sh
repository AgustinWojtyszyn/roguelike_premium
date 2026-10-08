#!/usr/bin/env bash
# Verificacion local completa SIN dispositivo Android ni ADB:
#   importa, corre las pruebas (GDScript + Python) y hace una partida de humo por capitulo con el bot.
set -u
cd "$(dirname "$0")/.."
fail=0
echo "== import"; godot --headless --path . --import 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR:" && fail=1
echo "== pruebas GDScript"; godot --headless --path . --script tests/run_tests.gd 2>&1 | tail -4 | tee /tmp/check_tests.log
grep -q " 0 FALLOS" /tmp/check_tests.log || fail=1
echo "== regresion Android (sin dispositivo)"; python3 -m unittest tests.test_android_cold_start 2>&1 | tail -2 || fail=1
for ch in ch1 ch2 ch3 ch4; do
  echo "== partida de humo $ch"
  out=$(timeout 480 godot --headless --path . scenes/run.tscn -- --bot --god --speed=8 --quit=1800 --seed=11 --chapter=$ch --fresh 2>&1)
  echo "$out" | grep -E "RESULTADO|SCRIPT ERROR|ERROR:" | head -3
  echo "$out" | grep -q "RESULTADO: victoria=true" || fail=1
done
echo "== modos alternativos (humo)"
out=$(timeout 240 godot --headless --path . scenes/run.tscn -- --bot --god --speed=8 --quit=240 --seed=11 --mode=survival --fresh 2>&1)
echo "$out" | grep -E "FPS medio|SCRIPT ERROR|ERROR:" | head -3
echo "$out" | grep -q "SCRIPT ERROR" && fail=1
out=$(timeout 600 godot --headless --path . scenes/run.tscn -- --bot --god --speed=8 --quit=1500 --seed=11 --mode=bossrush --fresh 2>&1)
echo "$out" | grep -E "RESULTADO|SCRIPT ERROR|ERROR:" | head -3
echo "$out" | grep -q "jefes=4" || fail=1
out=$(timeout 300 godot --headless --path . scenes/run.tscn -- --bot --god --speed=8 --quit=900 --seed=11 --mode=challenge --challenge=glass --chapter=ch1 --fresh 2>&1)
echo "$out" | grep -E "RESULTADO|SCRIPT ERROR|ERROR:" | head -3
echo "$out" | grep -q "RESULTADO" || fail=1
[ $fail -eq 0 ] && echo "TODO OK" || echo "HAY FALLOS"
exit $fail
