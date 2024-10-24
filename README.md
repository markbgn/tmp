name: Deploy .NET App to IIS with Backup

on:
  push:
    branches:
      - main  # Trigger the workflow on push to the main branch

jobs:
  deploy:
    runs-on: windows-latest

    steps:
      # Step 1: Checkout the code
      - name: Checkout code
        uses: actions/checkout@v3

      # Step 2: Set up .NET SDK
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '7.x'  # Specify your .NET version

      # Step 3: Restore dependencies
      - name: Restore dependencies
        run: dotnet restore

      # Step 4: Build the .NET app
      - name: Build .NET app
        run: dotnet build --configuration Release --no-restore

      # Step 5: Publish the app
      - name: Publish .NET app
        run: dotnet publish -c Release -o ./publish

      # Step 6: Stop IIS, Backup, Deploy, Start IIS (PowerShell via WinRM)
      - name: Stop IIS and Backup/Deploy via PowerShell
        uses: microsoft/powershell-action@v1
        with:
          script: |
            # Step 1: Start a PSSession to the IIS server
            $securePassword = ConvertTo-SecureString $env:WINRM_PASSWORD -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential ($env:WINRM_USERNAME, $securePassword)
            $session = New-PSSession -ComputerName $env:WINRM_HOST -Credential $credential

            # Step 2: Stop IIS on the remote server
            Invoke-Command -Session $session -ScriptBlock {
              Stop-Service -Name 'W3SVC'
              Write-Host 'IIS stopped.'
            }

            # Step 3: Backup the existing folder with timestamp
            Invoke-Command -Session $session -ScriptBlock {
              $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
              $backupPath = "F:\Backup\MagnumAF\MagnumAF_$timestamp.zip"
              $sourcePath = "F:\Webdata\MagnumAF"
              Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
              [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcePath, $backupPath)
              Write-Host "Backup completed: $backupPath"
            }

            # Step 4: Deploy the new build (Copy artifacts)
            Invoke-Command -Session $session -ScriptBlock {
              $publishPath = "$PWD\publish" # Assuming the publish path is in the current working directory
              $destinationPath = "F:\Webdata\MagnumAF"
              Remove-Item -Recurse -Force -Path $destinationPath\*  # Clean destination folder
              Copy-Item -Recurse -Force -Path $publishPath\* -Destination $destinationPath
              Write-Host "Deployment completed: $publishPath to $destinationPath"
            }

            # Step 5: Start IIS
            Invoke-Command -Session $session -ScriptBlock {
              Start-Service -Name 'W3SVC'
              Write-Host 'IIS started.'
            }

            # Step 6: Remove the PSSession
            Remove-PSSession $session
        env:
          WINRM_USERNAME: ${{ secrets.WINRM_USERNAME }}
          WINRM_PASSWORD: ${{ secrets.WINRM_PASSWORD }}
          WINRM_HOST: ${{ secrets.WINRM_HOST }}
