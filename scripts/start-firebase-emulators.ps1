$androidStudioJbr = 'C:\Program Files\Android\Android Studio\jbr'

if (Test-Path (Join-Path $androidStudioJbr 'bin\java.exe')) {
  $env:JAVA_HOME = $androidStudioJbr
  $env:Path = "$env:JAVA_HOME\bin;$env:Path"
}

firebase emulators:start --project demo-liga-gym
