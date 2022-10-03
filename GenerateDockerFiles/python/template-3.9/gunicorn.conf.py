app_service_app_logs_import_succeeded = False
code_profiler_import_succeeded = False
is_code_profiler_enabled = False
failure_message = "There was an issue installing an App Service Platform feature for this site."

def log_failure(feature, details, exception):
    global failure_message
    print(f"{failure_message}, Feature : {feature}, Details : {details},  Exception : {exception}")

try:
    import appServiceAppLogs as asal
    app_service_app_logs_import_succeeded = True

except Exception as e:
    feature = "AppServiceAppLogs"
    details = "import appServiceAppLogs failed"
    log_failure(feature, details, e)

try:
    import os
    from appsvc_profiler.constants import CodeProfilerConstants

    c = CodeProfilerConstants()
    is_code_profiler_enabled_app_setting_value = os.environ.get(c.APP_SETTING_TO_ENABLE_CODE_PROFILER, None)
    is_code_profiler_enabled = is_code_profiler_enabled_app_setting_value is None or is_like_true(is_code_profiler_enabled_app_setting_value)

    if is_code_profiler_enabled:
        # appsvc_profiler is currenly installed from appsvc_code_profiler-1.0.0-py3-none-any.whl
        from appsvc_profiler import CodeProfilerInstaller
        from appsvc_profiler.helpers import is_like_true
        code_profiler_import_succeeded = True

except Exception as e:
    feature = "CodeProfiler"
    details = "import appsvc_profiler failed"
    log_failure(feature, details, e)

def post_worker_init(worker):
    try:
        global app_service_app_logs_import_succeeded

        if app_service_app_logs_import_succeeded:
            asal.startHandlerRegisterer()

    except Exception as e:
        feature = "AppServiceAppLogs"
        details = "Failed to register handlers"
        log_failure(feature, details, e)

    try:
        global code_profiler_import_succeeded
        global is_code_profiler_enabled

        if is_code_profiler_enabled and code_profiler_import_succeeded:
            cpi = CodeProfilerInstaller()
            cpi.install()

    except Exception as e:
        feature = "CodeProfiler"
        details = "Installing appsvc_profiler failed"
        log_failure(feature, details, e)

def on_starting(server):
    global app_service_app_logs_import_succeeded

    try:
        if app_service_app_logs_import_succeeded :
            asal.initAppLogs()

    except Exception as e:
        feature = "AppServiceAppLogs"
        details = "Initialization failed"
        log_failure(feature, details, e)
