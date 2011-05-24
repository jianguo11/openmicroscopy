python build.py clean
if errorlevel 1 goto ERROR
python build.py
if errorlevel 1 goto ERROR
python build.py -f components\tools\OmeroPy\build.xml -Dtest.with.fail=true test
if errorlevel 1 goto ERROR
python build.py -f components\tools\OmeroPy\build.xml -Dtest.with.fail=true integration
if errorlevel 1 goto ERROR

cd examples
python ..\target\scons\scons.py run_py=1 no_cpp=1
if errorlevel 1 goto ERROR

exit /b 0
:ERROR
  echo Failed %ERRORLEVEL%
  exit /b %ERRORLEVEL%