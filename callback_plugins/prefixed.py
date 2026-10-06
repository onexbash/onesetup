from __future__ import annotations

import os

from ansible.plugins.callback.default import CallbackModule as DefaultCallback

DOCUMENTATION = """
name: prefixed
type: stdout
short_description: Default output, with task names prefixed by their pre-task file
extends_documentation_fragment:
  - default_callback
  - result_format_callback
"""

MARKER = os.sep + "pre_tasks" + os.sep


class CallbackModule(DefaultCallback):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "prefixed"

    @staticmethod
    def _prefix(task):
        path = (task.get_path() or "").rsplit(":", 1)[0]  # strip ":<line>"
        if MARKER not in path:
            return None
        rel = os.path.splitext(path.split(MARKER, 1)[1])[0]  # osx/clt
        return "PRE-TASK: " + rel.replace(os.sep, ".")  # PRE-TASK: osx.clt

    def v2_playbook_on_task_start(self, task, is_conditional):
        prefix = self._prefix(task)
        name = task.get_name()
        if prefix and not name.startswith(prefix):
            task.name = f"{prefix} | {name}"
        super().v2_playbook_on_task_start(task, is_conditional)
