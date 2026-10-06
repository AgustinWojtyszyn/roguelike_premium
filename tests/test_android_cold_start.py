import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('cold_start', Path(__file__).resolve().parents[1] / 'tools/android_cold_start.py')
cold_start = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cold_start)
PKG = cold_start.PACKAGE
PREFIX = '10-06 12:00:00.000'


def event(tag, text, pid=111):
    return f'{PREFIX} {pid:5} {pid:5} I {tag}: {text}\n'


def healthy():
    return (
        event('StartupAudit', 'CAPTURE test', 900)
        + event('StartupAudit', 'LAUNCH test', 900)
        + event('am_proc_start', f'[0,111,10200,{PKG},top-activity,com.godot.game.GodotAppLauncher]', 500)
        + event('GodotActivity', f'Launch intent Intent {{ cmp={PKG}/com.godot.game.GodotAppLauncher }} with parameters []')
        + event('godot', 'Godot Engine v4.7.2.stable.official')
        + event('godot', '[BOOT 01] PID=111 OS=Android ticks=123 main entered')
        + event('godot', '[BOOT 09] PID=111 OS=Android ticks=500 first frame viewport=(1280, 720) landscape=true')
        + event('godot', '[BOOT 10] PID=111 first rendered frame')
    )


def samples(pid='111', task=8):
    return [{'pid': pid, 'focus': f'topResumedActivity=ActivityRecord{{abcd u0 {PKG}/com.godot.game.GodotAppLauncher t{task}}}'}]


class ColdStartRegressionTests(unittest.TestCase):
    def test_single_start(self):
        self.assertTrue(cold_start.analyze(healthy(), samples())['pass'])

    def test_early_death_and_relaunch_before_first_poll(self):
        log = healthy() + event('am_proc_died', f'[0,111,{PKG},0,0]', 500)
        log += event('am_proc_start', f'[0,222,10200,{PKG},top-activity,GodotAppLauncher]', 500)
        # The old CI sees only the stable second PID at seconds 2 and 10.
        result = cold_start.analyze(log, samples('222') * 2)
        self.assertFalse(result['pass'])
        self.assertEqual(result['observed_pids'], ['111', '222'])

    def test_same_pid_activity_recreation(self):
        log = healthy() + event('wm_relaunch_resume_activity', f'[0,abcd,8,{PKG}/com.godot.game.GodotAppLauncher]', 500)
        log += event('GodotActivity', f'Launch intent Intent {{ cmp={PKG}/com.godot.game.GodotAppLauncher }} with parameters []')
        self.assertFalse(cold_start.analyze(log, samples())['pass'])

    def test_same_pid_engine_restart(self):
        log = healthy() + event('godot', 'Godot Engine v4.7.2.stable.official')
        self.assertFalse(cold_start.analyze(log, samples())['pass'])

    def test_launcher_flash_between_polls(self):
        log = healthy() + event('wm_pause_activity', f'[0,abcd,{PKG}/com.godot.game.GodotAppLauncher,userLeaving=false]', 500)
        self.assertFalse(cold_start.analyze(log, samples() * 2)['pass'])

    def test_native_crash_after_start(self):
        log = healthy() + event('libc', 'Fatal signal 11 (SIGSEGV), pid 111')
        self.assertFalse(cold_start.analyze(log, samples())['pass'])

    def test_java_crash(self):
        self.assertFalse(cold_start.analyze(healthy() + event('AndroidRuntime', 'FATAL EXCEPTION: main'), samples())['pass'])

    def test_script_failure_is_not_alive_pass(self):
        self.assertFalse(cold_start.analyze(healthy() + event('godot', 'SCRIPT ERROR: Invalid call'), samples())['pass'])

    def test_missing_game_frame_is_failure(self):
        log = '\n'.join(line for line in healthy().splitlines() if '[BOOT 09]' not in line)
        self.assertFalse(cold_start.analyze(log, samples())['pass'])

    def test_missing_capture_evidence_is_failure(self):
        self.assertFalse(cold_start.analyze('', samples())['pass'])

    def test_process_disappears_after_being_observed(self):
        self.assertFalse(cold_start.analyze(healthy(), samples() + [{'pid': '', 'focus': 'launcher'}] + samples())['pass'])

    def test_task_changes(self):
        self.assertFalse(cold_start.analyze(healthy(), samples() + samples(task=9))['pass'])

    def test_prelaunch_force_stop_is_not_a_regression(self):
        log = event('am_kill', f'[0,111,{PKG},force-stop]', 500) + healthy()
        self.assertTrue(cold_start.analyze(log, samples())['pass'])

    def test_unrelated_background_crash_is_preserved_but_not_app_failure(self):
        log = healthy() + event('AndroidRuntime', 'FATAL EXCEPTION: background app', 333)
        self.assertTrue(cold_start.analyze(log, samples())['pass'])


if __name__ == '__main__':
    unittest.main()
