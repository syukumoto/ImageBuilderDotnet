import os

# appsvc_profiler is currenly installed from appsvc_code_profiler-1.0.0-py3-none-any.whl
from appsvc_profiler import CodeProfilerInstaller
from appsvc_profiler.constants import CodeProfilerConstants as constants
from pathlib import Path

try:
    Path(constants.CODE_PROFILER_LOGS_DIR).mkdir(parents=True, exist_ok=True)
    pidfile = constants.PID_FILE_LOCATION
    
except Exception as e:
    print(f"Gunicorn was unable to set the pidfile path due to the exception : {e}")

def post_worker_init(worker):
    try:
        profiler_installer = CodeProfilerInstaller()
        profiler_installer.add_signal_handlers()              
            
    except Exception as e:
        print(e)
        os.environ[constants.CODE_PROFILER_SIGNAL_HANDLER_NOT_INITIALIZED_ENV_NAME]="true"