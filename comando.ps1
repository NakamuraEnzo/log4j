# Ensure we can run everything
Set-ExecutionPolicy Bypass -Scope Process -Force

# Escape characters in PowerShell: https://ss64.com/ps/syntax-esc.html

# Write-Host "Start iterating drives..."
$volumes = Get-WmiObject win32_volume -filter "drivetype=3"
$log4jFound = $false
foreach ($volume in $volumes)
{
    $driveletter = $volume.driveletter # e.g. C:
    if ($driveletter -ne $null)
    {
        $drivename   = $volume.name        # e.g. C:\

        # Write-Output "`n== Checking $driveletter... =="

        # Find log4j-core*.jar files, directly
        # and remove org/apache/logging/log4j/core/lookup/JndiLookup.class
        # with zip.exe -q -d command.
        # Use unzip -l | findstr JndiLookup as paranoia check.
        # Write-Host "== Find log4j-core*.jar files... =="
        Get-ChildItem -Path $drivename -Filter log4j-core*.jar -Recurse -ErrorAction SilentlyContinue | % {
            $log4jFound = $true
            Write-Host "== $($_.FullName) =="

            Write-Host "> zip.exe -q -d `"$($_.FullName)`" `"org/apache/logging/log4j/core/lookup/JndiLookup.class`""
            zip.exe -q -d "$($_.FullName)" "org/apache/logging/log4j/core/lookup/JndiLookup.class"

            Write-Host "> unzip.exe -l `"$($_.FullName)`" | findstr JndiLookup"
            unzip.exe -l "$($_.FullName)" | findstr JndiLookup

            Write-Host "== END =="
        }

        # Find JndiLookup.class in uncompressed directories on the file-system (aka *.class)
        # Write-Host "== Find uncompressed JndiLookup.class files... =="
        Get-ChildItem -Path $drivename -Filter JndiLookup.class -Recurse -ErrorAction SilentlyContinue | % {
            Write-Host "== $($_.FullName) =="
            $log4jFound = $true

            Write-Host "> Remove-Item -Path `"$($_.FullName)`" -Force"
            Remove-Item -Path $_.FullName -Force

            Write-Host "== END =="
        }
    }
}

Write-Host $log4jFound

if (!$log4jFound) {
    Write-Host "Log4j not found"
}

# Find embedded log4j-core*.jar files ("Java Über JARs" or shaded JARs, i.e., JARs in other JAR/WAR/etc.)
# Write-Host "== Find log4j-core*.jar files that are embedded into other archives... =="
# Write-Host "TODO: Not supported!"
# Write-Host "INSTEAD APPLY: https://github.com/mergebase/log4j-detector"

# Find log4j in docker containers
# Write-Host "== Find log4j in docker containers... =="
# Write-Host "TODO: Not supported!"
# Write-Host "READ: https://www.docker.com/blog/apache-log4j-2-cve-2021-44228/"
# Write-Host "THUS, APPLY: docker scan"

# Write-Host "Press ENTER to continue..."
# cmd /c Pause | Out-Null