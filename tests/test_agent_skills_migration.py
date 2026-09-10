"""Migration must preserve content, host skills and repeated-run behavior."""
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1]/'bin/migrate_agent_skills.py'


class MigrationTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name).resolve()
        self.dot = self.base/'dot'
        self.dot.mkdir()
        self.dest = self.base/'agent-skills'
        self.codex = self.base/'codex'
        self.claude = self.base/'claude'
        for scope in ['codex','claude']:
            folder = self.dot/'ai'/scope/'skills'/f'{scope}-example'
            folder.mkdir(parents=True)
            (folder/'SKILL.md').write_text(f'{scope} content\n')
        system = self.dot/'ai/codex/skills/.system'
        system.mkdir()
        (system/'app-owned').write_text('keep system')
        self.codex.mkdir()
        (self.codex/'skills').symlink_to(self.dot/'ai/codex/skills',target_is_directory=True)
        plugin = self.claude/'skills/plugin-owned'
        plugin.mkdir(parents=True)
        (plugin/'SKILL.md').write_text('keep plugin')
        self.git('init','-q')
        self.git('add','ai')
        self.git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','legacy skills')

    def git(self,*args):
        return subprocess.run(['git','-C',str(self.dot),*args],check=True,capture_output=True)

    def run_migration(self,*extra):
        return subprocess.run(['python3',str(SCRIPT),'--dot-root',str(self.dot),
            '--destination',str(self.dest),'--codex-home',str(self.codex),
            '--claude-home',str(self.claude),'--backup-dir',str(self.base/'backups'),*extra],
            capture_output=True,text=True)

    def test_move_and_repeat_preserve_host_state(self):
        first=self.run_migration()
        self.assertEqual(first.returncode,0,first.stderr)
        self.assertFalse((self.codex/'skills').is_symlink())
        self.assertEqual((self.codex/'skills/.system/app-owned').read_text(),'keep system')
        self.assertEqual((self.claude/'skills/plugin-owned/SKILL.md').read_text(),'keep plugin')
        target=self.dest/'skills/codex/codex-example'
        self.assertEqual((self.codex/'skills/codex-example').resolve(),target)
        self.assertEqual((self.dot/'ai/codex/skills/codex-example').resolve(),target)
        self.assertFalse((self.dest/'skills/codex/.system').exists())
        (target/'SKILL.md').write_text('new independent revision')
        second=self.run_migration()
        self.assertEqual(second.returncode,0,second.stderr)
        self.assertEqual((target/'SKILL.md').read_text(),'new independent revision')

    def test_conflict_stops_before_source_changes(self):
        subprocess.run(['git','init','-q',str(self.dest)],check=True)
        target=self.dest/'skills/codex/codex-example'
        target.mkdir(parents=True)
        (target/'SKILL.md').write_text('different')
        result=self.run_migration()
        self.assertNotEqual(result.returncode,0)
        self.assertTrue((self.codex/'skills').is_symlink())
        self.assertFalse((self.dot/'ai/codex/skills/codex-example').is_symlink())
        self.assertEqual((target/'SKILL.md').read_text(),'different')

    def test_git_history_recovery(self):
        self.git('rm','-r','ai/codex/skills/codex-example','ai/claude/skills/claude-example')
        self.git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','extract skills')
        result=self.run_migration()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual((self.dest/'skills/claude/claude-example/SKILL.md').read_text(),'claude content\n')

    def test_dry_run_leaves_source_and_destination_unchanged(self):
        result=self.run_migration('--dry-run')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertFalse(self.dest.exists())
        self.assertTrue((self.codex/'skills').is_symlink())


if __name__ == '__main__':
    unittest.main()
