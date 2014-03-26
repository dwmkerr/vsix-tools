[Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" )

# todo: validate vsix version (vs 2012 version is supported only)

# Unzips a zip file at $path to the folder $destination.
function Unzip($path, $destination)
{
    [System.IO.Compression.ZipFile]::ExtractToDirectory($path, $destination)
}

# Given a path such as 'c:\test.vsix' this function 
# extracts the contents to c:\test.
function ExtractVsixToWorkingFolder($vsixPath) {
    
    # Create the destination directory.
    $extractFolderName = [System.Io.Path]::GetFileNameWithoutExtension($vsixPath)
    $extractFolderPath = (Join-Path (Split-Path $vsixPath) $extractFolderName)

    # Throw if it already exists.
    if(Test-Path $extractFolderPath) {
        throw "Cannot extract the vsix to folder '$extractFolderPath' as it already exists and might cause data loss."
    }

    # Extract the zip to the folder.
    Unzip $vsixPath $extractFolderPath

    # Return the extract folder path, which is essentially our working directory.
    return $extractFolderPath
}

# Given a path to a vsix, overwrites it with the contents of the s
# associated working folder.
function ZipWorkingFolderToVsix($workingFolder, $vsixPath) {

    # Delete the vsix (as we will overwrite it).
    Copy-Item $vsixPath -Destination ($vsixPath + ".backup")
    Remove-Item $vsixPath -Force

    # Zip the working folder up and save it at the vsix path
    [System.IO.Compression.ZipFile]::CreateFromDirectory($workingFolder, $vsixPath)

    # Remove the working folder.
    Remove-Item $workingFolder -Force -Recurse
}

# Gets the vsix manifest version. Could be:
# 1: Visual Studio 2010
# 2: Visual Studio 2012 onwards
function GetManifestVersion($manifestXml) {

    # Version 1 if we have a Vsix node with Version attribute = 1.
    if($manifestXml.DocumentElement.Name -eq "Vsix" -and $manifestXml.Vsix.Version -eq "1.0.0") {
        return 1;
    }

    # Version 2 if we have a Package manifest node with Version attribute = 2.
    if($manifestXml.DocumentElement.Name -eq "PackageManifest" -and $manifestXml.PackageManifest.Version -eq "2.0.0") {
        return 2;
    }
    
    throw "Unable to determine the version of the Vsix manifest."
}

# Sets the version of the vsix.
# Version should be a string in the format "a.b" "a.b.c" or "a.b.c.d"
function Vsix-Set-Version {
    param(
       [Parameter(Mandatory=$true)]
       [string]$VsixPath,
       [Parameter(Mandatory=$true)]
       [string]$Version
    )
    
    # First, create the working directory.
    $workingFolder = ExtractVsixToWorkingFolder $VsixPath

    # Now load the manifest.
    $manifestPath = Join-Path $workingFolder "extension.vsixmanifest"
    $manifestXml = New-Object XML
    $manifestXml.Load($manifestPath)

    # Set the package version. The xml structure depends on the manifest version.
    $manifestVersion = GetManifestVersion($manifestXml)
    if($manifestVersion -eq 1) {
        $manifestXml.Vsix.Identifier.Version = $Version
    } else {
        $manifestXml.PackageManifest.Metadata.Identity.Version = $Version
    }

    # Save the manifest.
    $manifestXml.save($manifestPath)
    
    # Finally, save the updated working folder as the vsix.
    ZipWorkingFolderToVsix $workingFolder $vsixPath
}

function Vsix-Fix-Invalid-Multiple-Files {
    param(
       [Parameter(Mandatory=$true)]
       [string]$VsixPath
    )

    # The gist is this. Find every zip file in Project Templates, e.g:
    # ProjectTemplates\CSharp\1033\PlumsProject.zip
    # ProjectTemplates\CSharp\1033\ApplesProject.zip
    # Then put *each one* into a uniquely named folder by replacing
    # 'project templates' in the path with a new unique id
    # A\CSharp\1033\PlumsProject.zip
    # B\CSharp\1033\ApplesProject.zip
    # don't use numbers, as the Visual Studio Gallery site fails
    # if you use 1, 11, 111 etc.

    # First, create the working directory.
    $workingFolder = ExtractVsixToWorkingFolder $VsixPath

    # Get the zip paths
    $letter = 65 # i.e. 'A'
    Get-ChildItem -Path (Join-Path $workingFolder '.\ProjectTemplates') -Filter *.zip -Recurse | ForEach-Object {
        $from = $_.FullName
        $newPath = $from.Replace('\ProjectTemplates\', '\' + [char]$letter + '\')
        Write-Host "From: $from"
        Write-Host "To: $newPath"
        $letter++

        # Copy the file from the old location to the new one, creating a directory chain as necessary.
        New-Item -ItemType File -Path $newPath -Force
        Copy-Item $from $newPath -Force
    }

    # Delete the project templates folder.
    Remove-Item (Join-Path $workingFolder '.\ProjectTemplates') -Force -Recurse

    # Manifest v1:
    # Remove all Vsix/Content/ProjectTemplate nodes and replace with A/B/C etc, e.g.:
    # <Content>
    #   <ProjectTemplate>ProjectTemplates</ProjectTemplate>
    # </Content>
    # to 
    # <Content>
    #   <ProjectTemplate>A</ProjectTemplate>
    #   <ProjectTemplate>B</ProjectTemplate>
    #   <ProjectTemplate>C</ProjectTemplate>
    # </Content>
    # Finally, save the updated working folder as the vsix.
    ZipWorkingFolderToVsix $workingFolder $vsixPath
}

function Vsix-Get-Manifest-Version {
    param(
       [Parameter(Mandatory=$true)]
       [string]$VsixPath
    )
    
    # First, create the working directory.
    $workingFolder = ExtractVsixToWorkingFolder $VsixPath
    
    # Now load the manifest.
    $manifestPath = Join-Path $workingFolder "extension.vsixmanifest"

    # Get the manifest version.
    $manifestXml = New-Object XML
    $manifestXml.Load($manifestPath)
    $manifestVersion = GetManifestVersion($manifestXml)

    # Finally, clean up the working folder.
    Remove-Item $workingFolder -Force -Recurse
    return $manifestVersion
}

$vsixPath2010 = ".\Test Files\VS2010\SharpGL.vsix"
$vsixPath2012 = ".\Test Files\VS2012\SharpGL.vsix"

Vsix-Fix-Invalid-Multiple-Files -VsixPath $vsixPath2010

Vsix-Get-Manifest-Version -VsixPath $vsixPath2010
Vsix-Get-Manifest-Version -VsixPath $vsixPath2012
Vsix-Set-Version -VsixPath $vsixPath2010 -Version "69.2"
Vsix-Fix-Invalid-Multiple-Files -VsixPath $vsixPath2012