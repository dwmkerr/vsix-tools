vsix-tools
==========

[![GuardRails badge](https://badges.production.guardrails.io/dwmkerr/vsix-tools.svg)](https://www.guardrails.io)

VsixTools is a small set of useful powershell functions that can be helpful when
maintaining Visual Studio Extension Packages (*.vsix files).

What can the tools do?
----------------------

You can use the tools to set the version number of a vsix package:

````PowerShell

# Load vsix tools
. VsixTools.ps1

# Set the version number of 'MyPackage'.
$vsixPath = "c:/MyPackage.vsix"
Vsix-SetVersion -VsixPath $vsixPath -Version "2.2.0.1"

````

You can also use the tools to fix the notorious [Invalid Multiple Files in Vsix](http://stackoverflow.com/questions/9416467/invalid-multiple-zip-files-in-in-vsix) issue in packages, letting you upload packages that contain mulitple project templates to the Visual Studio Gallery.

````PowerShell

# Load vsix tools
. VsixTools.ps1

# Fix 'MyPackage'.
$vsixPath = "c:/MyPackage.vsix"
Vsix-FixInvalidMultipleFiles -VsixPath $vsixPath 

````

Why do I need the tools?
------------------------

If you don't publish vsix files regularly, you don't. But if you want to fix the invalid zip files issue and 
version your vsix files as part of an automated process, these tools might help.

How do I use the tools?
-----------------------

Put the ``VsixTools.ps1`` file somewhere and [dot source](http://technet.microsoft.com/en-us/library/ee176949.aspx#ECAA)
it from your script. Then just use the ``Vsix-SetVersion`` or ``Vsix-FixInvalidMultipleFiles`` functions as you need
them. If you need more functionality, raise an issue and I'll see what I can do.

The tools have no other dependecies and are written in Powershell 2.

The script works for packages of version 1 or 2 - i.e. Visual Studio 2010 to 2013.

Other Notes
-----------

Currently, the tools use the shell functions to zip up files - these are *very* slow compared to 
using the .NET Framework to handle zip files. However, I've discovered that there seem to be intermittent
problems with the reading of vsix files by Visual Studio if they've been zipped in this way, so I'm using
the slower but less problematic shell version of zipping.
