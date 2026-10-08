#!/usr/bin/env python3
"""Capture the complete cold-start transition; never infer stability from the final PID."""
import argparse
import datetime as dt
import json
import re
import subprocess
import time
import uuid
from pathlib import Path

PACKAGE = 'com.agustin.rpgpremium'
FOCUS = re.compile(r'(?:topResumedActivity|mResumedActivity|ResumedActivity):?\s*=?.*')
KEY_LOGS = re.compile(r'AndroidRuntime|ActivityManager|ActivityTaskManager|Godot|godot|libc|DEBUG|DEBUGGERD|crash_dump|vulkan|Vulkan|OpenGL|SurfaceFlinger|wm_|am_proc_|StartupAudit')


def analyze(log, samples, package=PACKAGE, require_boot=True):
    """Analyze only the post-LAUNCH interval. Keep raw prelaunch data in the artifact."""
    errors = []
    if 'StartupAudit' not in log or 'LAUNCH ' not in log:
        errors.append('Missing prelaunch capture marker')
    launched = log.split('LAUNCH ', 1)[-1]
    lines = launched.splitlines()
    starts = []
    for line in lines:
        event = re.search(r'am_proc_start\s*:\s*\[\d+,(\d+),\d+,' + re.escape(package) + r',', line)
        if event:
            starts.append({'pid': event[1], 'event': line})
    # All buffers include the events buffer. Its absence must not silently pass.
    if len(starts) != 1:
        errors.append(f'Expected exactly one am_proc_start for app, found {len(starts)}')
    observed = {s['pid'] for s in samples if s.get('pid')}
    initial_pid = starts[0]['pid'] if starts else None
    if initial_pid:
        observed.add(initial_pid)
    if len(observed) != 1:
        errors.append(f'PID changed or unavailable: {sorted(observed)}')
    seen_pid = False
    for sample in samples:
        if sample.get('pid'):
            seen_pid = True
        elif seen_pid:
            errors.append('App process disappeared during sampling')
            break
    if not samples or not samples[-1].get('pid'):
        errors.append('App is not alive at end of observation')
    engine = [line for line in lines if re.search(r'godot\s*:\s*Godot Engine v', line, re.I)]
    creates = [line for line in lines if 'GodotActivity' in line and 'Launch intent ' in line]
    boot = [line for line in lines if '[BOOT 01]' in line]
    first_frame = [line for line in lines if '[BOOT 09]' in line]
    if len(engine) != 1:
        errors.append(f'Expected one Godot initialization, found {len(engine)}')
    if len(creates) != 1:
        errors.append(f'Expected one Activity onCreate launch log, found {len(creates)}')
    if require_boot:
        if len(boot) != 1 or len(first_frame) != 1:
            errors.append(f'Main must enter/render once: entered={len(boot)}, first_frame={len(first_frame)}')
        if not any('landscape=true' in line for line in first_frame):
            errors.append('Game viewport did not report landscape')
        if not any('[BOOT 10]' in line and 'first rendered frame' in line for line in lines):
            errors.append('No completed rendered frame')
    relevant = [line for line in lines if package in line or any(re.search(r'\s' + re.escape(pid) + r'\s', line) for pid in observed)]
    forbidden = re.compile(r'FATAL EXCEPTION|Fatal signal|SIGSEGV|SIGABRT|ANR in |am_anr|am_crash|am_proc_died|am_kill|wm_relaunch|wm_destroy_activity|wm_on_destroy_called|wm_finish_activity|wm_pause_activity|wm_on_paused_called|wm_stop_activity|wm_on_stop_called|Restarting Godot|restarting\.\.|ProcessPhoenix|SCRIPT ERROR|Parse Error|ERROR:')
    bad = [line for line in relevant if forbidden.search(line)]
    if bad:
        errors.append('Crash, exit, pause, destruction, relaunch or runtime error observed')
    app_focused = False
    tasks = set()
    for sample in samples:
        focus = sample.get('focus', '')
        if package in focus:
            app_focused = True
            tasks.update(re.findall(r'\bt(\d+)\b', focus))
        elif app_focused and focus:
            errors.append('Foreground left the app after it became resumed')
            break
    if not app_focused or package not in samples[-1].get('focus', ''):
        errors.append('Game Activity is not resumed at end of observation')
    if len(tasks) != 1:
        errors.append(f'Task changed or missing: {sorted(tasks)}')
    return {
        'pass': not errors, 'errors': errors, 'initial_pid': initial_pid,
        'final_pid': samples[-1].get('pid') if samples else None,
        'observed_pids': sorted(observed), 'task_ids': sorted(tasks),
        'final_activity': samples[-1].get('focus') if samples else None,
        'godot_initializations': len(engine), 'activity_creations': len(creates),
        'main_initializations': len(boot), 'process_start_events': starts,
        'failure_events': bad, 'engine_events': engine,
    }


class Device:
    def __init__(self, serial):
        self.command = ['adb'] + (['-s', serial] if serial else [])

    def run(self, *args, check=True, timeout=30):
        result = subprocess.run(self.command + list(args), capture_output=True, text=True, timeout=timeout)
        if check and result.returncode:
            raise RuntimeError(f'adb {args}: {result.stderr or result.stdout}')
        return result.stdout.strip()


def capture(device, out, package, duration, require_boot):
    out.mkdir(parents=True, exist_ok=True)
    device.run('shell', 'am', 'force-stop', package)
    device.run('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    if device.run('shell', 'pidof', package, check=False):
        raise RuntimeError('force-stop did not stop the app')
    component = device.run('shell', 'cmd', 'package', 'resolve-activity', '--brief', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.LAUNCHER', package).splitlines()[-1]
    if not component.startswith(package + '/'):
        raise RuntimeError('Launcher alias could not be resolved: ' + component)
    token = uuid.uuid4().hex
    samples = []
    log_path = out / 'logcat-all.txt'
    launch = None
    with log_path.open('w') as output, (out / 'logcat-stderr.txt').open('w') as stderr:
        reader = subprocess.Popen(device.command + ['logcat', '-b', 'all', '-v', 'threadtime', '-T', '1'], stdout=output, stderr=stderr)
        try:
            time.sleep(3)  # let the reader attach before the marker, otherwise -T 1 skips it
            device.run('shell', 'log', '-t', 'StartupAudit', 'CAPTURE ' + token)
            time.sleep(3)
            if reader.poll() is not None or token not in log_path.read_text(errors='replace'):
                raise RuntimeError('Logcat was not recording before launch')
            device.run('shell', 'log', '-t', 'StartupAudit', 'LAUNCH ' + token)
            started = time.monotonic()
            with (out / 'launch.txt').open('w') as launch_output:
                launch = subprocess.Popen(device.command + ['shell', 'am', 'start', '-W', '-a', 'android.intent.action.MAIN', '-c', 'android.intent.category.LAUNCHER', '-n', component], stdout=launch_output, stderr=subprocess.STDOUT)
                with (out / 'samples.jsonl').open('w') as sample_file:
                    while time.monotonic() - started < duration:
                        pid = device.run('shell', 'pidof', package, check=False, timeout=10)
                        activity = device.run('shell', 'dumpsys', 'activity', 'activities', timeout=10)
                        focused = '\n'.join(line.strip() for line in activity.splitlines() if FOCUS.search(line))
                        sample = {'utc': dt.datetime.now(dt.timezone.utc).isoformat(), 'seconds': round(time.monotonic() - started, 3), 'pid': pid, 'focus': focused}
                        samples.append(sample)
                        sample_file.write(json.dumps(sample) + '\n')
                        sample_file.flush()
                        time.sleep(0.2)
                launch.wait(timeout=15)
            for name, command in {
                'activity.txt': ['shell', 'dumpsys', 'activity', 'activities'],
                'activity-top.txt': ['shell', 'dumpsys', 'activity', 'top'],
                'exit-info.txt': ['shell', 'dumpsys', 'activity', 'exit-info', package],
                'memory.txt': ['shell', 'dumpsys', 'meminfo', package],
                'window.txt': ['shell', 'dumpsys', 'window'],
            }.items():
                (out / name).write_text(device.run(*command, check=False))
            shot = subprocess.run(device.command + ['exec-out', 'screencap', '-p'], capture_output=True, timeout=15)
            (out / 'screen.png').write_bytes(shot.stdout)
            device.run('shell', 'log', '-t', 'StartupAudit', 'END ' + token)
            time.sleep(0.5)
        finally:
            reader.terminate()
            reader.wait(timeout=10)
            if launch is not None and launch.poll() is None:
                launch.terminate()
    log = log_path.read_text(errors='replace')
    (out / 'logcat-filtered.txt').write_text('\n'.join(line for line in log.splitlines() if KEY_LOGS.search(line)) + '\n')
    result = analyze(log, samples, package, require_boot)
    result.update({'launcher_component': component, 'duration_seconds': duration, 'capture_id': token})
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial')
    parser.add_argument('--apk', type=Path)
    parser.add_argument('--package', default=PACKAGE)
    parser.add_argument('--runs', type=int, default=5)
    parser.add_argument('--seconds', type=float, default=20)
    parser.add_argument('--out', type=Path, default=Path('build/android-cold-start'))
    parser.add_argument('--without-boot-markers', action='store_true', help='For an uninstrumented baseline; still checks process and Activity lifecycle')
    args = parser.parse_args()
    if args.seconds < 15 or args.runs < 1:
        parser.error('Observe at least 15 seconds per cold start')
    device = Device(args.serial)
    args.out.mkdir(parents=True, exist_ok=True)
    metadata = device.run('shell', 'getprop')
    (args.out / 'device-properties.txt').write_text(metadata)
    if args.apk:
        device.run('install', '-r', str(args.apk.resolve()), timeout=180)
    failures = 0
    results = []
    for run in range(1, args.runs + 1):
        result = capture(device, args.out / f'cold-start-{run}', args.package, args.seconds, not args.without_boot_markers)
        results.append(result)
        failures += int(not result['pass'])
        print(f"cold start {run}: {'PASS' if result['pass'] else 'FAIL'} PID={result['initial_pid']}->{result['final_pid']} task={result['task_ids']} Godot={result['godot_initializations']}", flush=True)
        for error in result['errors']:
            print('  ' + error, flush=True)
    (args.out / 'summary.json').write_text(json.dumps(results, indent=2) + '\n')
    raise SystemExit(1 if failures else 0)


if __name__ == '__main__':
    main()
