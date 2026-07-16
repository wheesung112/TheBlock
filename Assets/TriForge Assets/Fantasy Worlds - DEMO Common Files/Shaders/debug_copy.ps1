try {
    Write-Host "Current Directory: $((Get-Location).Path)"
    if (Test-Path "FWGrass.shader") {
        Write-Host "Source file exists."
    } else {
        Write-Error "Source file NOT found."
        exit 1
    }
    
    Copy-Item -Path "FWGrass.shader" -Destination "FWGrass_Wireframe.shader" -Force -Verbose
    
    if (Test-Path "FWGrass_Wireframe.shader") {
        Write-Host "Destination file created successfully."
    } else {
        Write-Error "Destination file missing after copy."
    }
} catch {
    Write-Error $_
}
