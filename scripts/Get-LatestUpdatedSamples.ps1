# Define the folder containing the WinUIGallery Samples relative to the script location
$SamplesFolder = Join-Path -Path $PSScriptRoot -ChildPath "..\WinUIGallery\Samples"

# Change directory to the WinUIGallery folder
Push-Location -Path $SamplesFolder

# Define the folder containing the control pages
$currentFolder = "ControlPages"
$now = [datetimeoffset]::Now
# Retrieve the list of files in the folder with their details
$filesWithDetails = git ls-tree -r HEAD --name-only $currentFolder | ForEach-Object { 
    $file = $_  # Current file path from the git tree

    # Check if the file is directly under the $currentFolder and not in subdirectories
    if ($file -match "^$currentFolder/[^/]+$") {
        # Get the last commit date for the file
        $lastCommitDate = git log -1 --format="%ai" -- $file

        # Get the commit status for the file (checks if it was modified in the last commit)
        $commitStatus = git log -1 --name-status -- $file | Select-String -Pattern "^M" | ForEach-Object { $_.Line.Split()[0] }
        # If the file was modified ("M"), create a custom object with file details
        if ($commitStatus -eq "M") {
            $target = [datetimeoffset]::ParseExact($lastCommitDate, "yyyy-MM-dd HH:mm:ss zzz", $null)
            $timespan = $now - $target
            $Filename = $file.Substring($currentFolder.Length + 1)  # Trim the folder path to get the file name
            $Displayname = $Filename -replace '\.xaml\.cs$', '' -replace '\.xaml$', ''
            $Displayname = $Displayname -replace 'Page$', ''

            $Fullpath = (Resolve-Path -Path "$file" -RelativeBasePath "$SamplesFolder").Path
            [PSCustomObject]@{
                Fullpath = $Fullpath
                RelativePath = $file
                File = $Filename
                Displayname = $Displayname
                LastCommitDate = $lastCommitDate  # Last commit date for the file
                Age = $timespan
            }
        }
    }
}
[System.Collections.ArrayList]$UpdatedList = [System.Collections.ArrayList]::new()
# Sort the files by the last commit date in descending order
$sortedFiles = $filesWithDetails | Sort-Object LastCommitDate -Descending
# Create a hashtable to cache processed file base names to avoid duplicates
$cachedBaseNames = @{ }
# Initialize the output string for the latest updated samples
$LatestUpdatedSamples = "Latest Updated Samples:`n"
# Process the sorted files
$sortedFiles | ForEach-Object {
   
    $name = $_.Displayname
    $date = $_.LastCommitDate
    $days = $_.Age.Days
    $color = 'DarkGreen'
    if($days -lt 15){
         $color = 'Green'
    }elseif($days -lt 35){
         $color = 'Yellow'
    }elseif($days -lt 90){
         $color = 'DarkRed'
    }else{
         $color = 'Magenta'
    }
    # Add the file to the output if it hasn't been cached yet
    if (-not $cachedBaseNames.Contains($name)) {
            $UpdateString = "{0,-32}`tUpdated {1} days ago" -f $name, $days
        $LatestUpdatedSamples += "$UpdateString" # Append the file name to the output
        Write-Host "$UpdateString" -f $color
    }
}

pop-location

# Output the list of latest updated samples
#Write-Output $LatestUpdatedSamples

# Wait for the user to press Enter before closing the PowerShell window
Read-Host -Prompt "Press Enter to exit"