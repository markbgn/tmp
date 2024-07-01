# Define source and destination paths
$sourcePath = "F:\fdr"
$destPath = "F:\dest"
$searchPattern = "*example.string.ss*"

# Iterate through each directory in the source path
Get-ChildItem -Path $sourcePath -Directory | ForEach-Object {
    $directory = $_.FullName
    $dirName = $_.Name

    # Check if the directory name starts with "batch"
    if ($dirName -like "batch*") {
        # Find all files in the directory that match the search pattern
        Get-ChildItem -Path $directory -File -Recurse -Filter $searchPattern | ForEach-Object {
            $file = $_.FullName

            # Determine the relative path of the file
            $relativePath = $file.Substring($sourcePath.Length).TrimStart('\')

            # Define the destination path
            $destFilePath = Join-Path $destPath $relativePath

            # Create the destination directory if it does not exist
            $destDir = [System.IO.Path]::GetDirectoryName($destFilePath)
            if (!(Test-Path -Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force
            }

            # Copy the file to the destination path
            Copy-Item -Path $file -Destination $destFilePath -Force
        }
    }
}
