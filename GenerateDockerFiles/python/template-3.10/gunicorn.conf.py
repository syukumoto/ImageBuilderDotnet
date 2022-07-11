app_service_app_logs_import_succeeded = False
code_profiler_import_succeeded = False

try:
    import appServiceAppLogs as asal
    app_service_app_logs_import_succeeded = True
    
except Exception as e:
    print(e)    

try:
    import os
    
    # appsvc_profiler is currenly installed from appsvc_code_profiler-1.0.0-py3-none-any.whl
    from appsvc_profiler import CodeProfilerInstaller
    from appsvc_profiler.constants import CodeProfilerConstants
    from appsvc_profiler.helpers import is_like_true
    code_profiler_import_succeeded = True
    
except Exception as e:
    print(e)

def post_worker_init(worker):
    if app_service_app_logs_import_succeeded:
        asal.startHandlerRegisterer()
    
    try:
        c = CodeProfilerConstants()        
        is_code_profiler_enabled_app_setting_value = os.environ.get(c.APP_SETTING_TO_ENABLE_CODE_PROFILER, None)
        is_code_profiler_enabled = is_code_profiler_enabled_app_setting_value is None or is_like_true(is_code_profiler_enabled_app_setting_value)
        
        if code_profiler_import_succeeded and is_code_profiler_enabled:
            cpi = CodeProfilerInstaller()
            cpi.install()
            
    except Exception as e:
        print(e)

def on_starting(server):
    if app_service_app_logs_import_succeeded:
        asal.initAppLogs()
