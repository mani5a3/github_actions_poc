Write-Host "Starting SonarQube Quality Gate check"

        # Verify report exists
        $reportPath = ".scannerwork/report-task.txt"
        if (-not (Test-Path $reportPath)) {
            Write-Host "ERROR: Report file not found at $reportPath"
            exit 1
        }

        # Read report
        $reportLines = Get-Content $reportPath
        $ceLine = $reportLines | Where-Object { $_ -match "^ceTaskUrl=" }
        if (-not $ceLine) {
            Write-Host "ERROR: ceTaskUrl not found in report"
            exit 1
        }
        $ceUrl = $ceLine -replace "^ceTaskUrl=", ""
        Write-Host "Compute engine URL: $ceUrl"

        # Prepare auth header
        $pair = "$($env:SONAR_TOKEN):"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $headers = @{ Authorization = "Basic $base64" }

        # Poll Sonar until analysis is completed
        $maxAttempts = 60
        $attempt = 0
        $finalStatus = ""
        do {
            Start-Sleep -Seconds 5
            $attempt++
            try {
                $taskResponse = Invoke-RestMethod -Uri $ceUrl -Headers $headers -ErrorAction Stop
                $finalStatus = $taskResponse.task.status
                Write-Host "Sonar compute engine status: $finalStatus"
            } catch {
                Write-Host "Warning: error calling CE API; retrying..."
                $finalStatus = ""
            }
            if ($attempt -ge $maxAttempts) {
                Write-Host "ERROR: Timed out waiting for Sonar compute engine"
                exit 1
            }
        } while ($finalStatus -ne "SUCCESS" -and $finalStatus -ne "FAILED")

        if ($finalStatus -ne "SUCCESS") {
            Write-Host "ERROR: Sonar compute engine did not finish successfully ($finalStatus)"
            exit 1
        }

        # Fetch Quality Gate result
        $analysisId = $taskResponse.task.analysisId
        if (-not $analysisId) {
            Write-Host "ERROR: analysisId not found"
            exit 1
        }

        $qgUrl = "$env:SONAR_HOST_URL/api/qualitygates/project_status?analysisId=$analysisId"
        Write-Host "Quality gate API URL: $qgUrl"

        try {
            $qgResponse = Invoke-RestMethod -Uri $qgUrl -Headers $headers -ErrorAction Stop
        } catch {
            Write-Host "ERROR: Failed to call Sonar quality gate API"
            exit 1
        }

        $qgStatus = $qgResponse.projectStatus.status
        Write-Host "Sonar quality gate status: $qgStatus"

        # Print each condition
        Write-Host "Quality Gate condition results:"
        foreach ($cond in $qgResponse.projectStatus.conditions) {
            Write-Host ("  Metric        : {0}" -f $cond.metricKey)
            Write-Host ("    Status      : {0}" -f $cond.status)
            Write-Host ("    ActualValue : {0}" -f $cond.actualValue)
            Write-Host ("    Comparator  : {0}" -f $cond.comparator)
            Write-Host ("    Threshold   : {0}" -f $cond.errorThreshold)
        }

        # Fail based on status
        if ($qgStatus -eq "OK") {
            Write-Host "Quality gate passed"
        } else {
            Write-Host "Quality gate failed. Please fix the above conditions."
            exit 1
        }