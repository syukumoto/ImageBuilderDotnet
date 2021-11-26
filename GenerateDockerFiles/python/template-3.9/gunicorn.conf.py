import constants
import code_profiler_installer as c
from pathlib import Path

Path(constants.CODE_PROFILER_LOGS_DIR).mkdir(parents=True, exist_ok=True)
pidfile = constants.PID_FILE_LOCATION

def post_worker_init(worker):
    try:
        profiler_installer = c.CodeProfilerInstaller()
        profiler_installer.add_signal_handlers()              
            
    except Exception as e:
        print(e)