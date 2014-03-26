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
    $manifestXml.PackageManifest.Metadata.Identity.Version = $Version
    $manifestXml.save($manifestPath)
    
    # Finally, save the updated working folder as the vsix.
    ZipWorkingFolderToVsix $workingFolder $vsixPath
}

function Vsix-Fix-Invalid-Multiple-Files {
    param(
       [Parameter(Mandatory=$true)]
       [string]$VsixPath
    )
    
    # First, create the working directory.
    $workingFolder = ExtractVsixToWorkingFolder $VsixPath
    
    # Finally, save the updated working folder as the vsix.
    ZipWorkingFolderToVsix $workingFolder $vsixPath
}

$vsixPath = "C:\Repositories\GitHub\vsix-tools\SharpGL.vsix"
Vsix-Fix-Invalid-Multiple-Files -VsixPath $vsixPath