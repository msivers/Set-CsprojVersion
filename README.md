# Set-CsprojVersion Powershell Script
Update value for version elements &lt;Version>, &lt;VersionPrefix>, &lt;VersionSuffix> and &lt;PackageVersion> in the specified .NET Core .CSPROJ file.

Individual segments of version can be updated explicitly or patch and revision segments can be incremented or auto generated.

*NOTE: Version elements will only be updated if they exist in the project file (XML).*

</br>

## Parameters
</br>

Parameter    | Descriptioon
------------ | ------------
`path` | The path to the .csproj file to update (REQUIRED).
`major` | Define/override major segment (1st) of version. Otherwise will use existing.
`minor` | Define/override minor segment (2nd) of version. Otherwise will use existing if exists or 0 if not defined or existing.
`patch` | Define/override patch segment (3rd) of version. Otherwise will use existing if exists. To remove this segment use -1.
`revision` | Define/override revision segment (4th) of version. Otherwise will use existing if exists. To remove this segment use -1.
`prerelease` | Prerelease suffix - textual description of prerelease build state. e.g. alpha, beta, preview, prerelease, rc.1, preview3. A leading hyphen is not required.
`incrementpatch` | Switch to auto increment patch segment if exists.
`incrementrevision` | Switch to auto increment revision segment if exists.
`autopatchandrevision` | Switch to auto generate patch and revision segments. Patch is generated as the month since 2015.     Revision is generated as total minutes of current month.
`autorevision` | Switch to auto generate revision segment. Revision is generated as total minutes of current month. Max value: 44640.
</br>

## Examples
</br>

>*Version 1.5.0 updated to 1.5.7.28349*
>```powershell
>Set-CsprojVersion.ps1 -path MyProject.csproj -autopatchandrevision
>``` 
</br>

>*Version 1.2.0.12 updated to 1.2.0.13*
>```powershell
>Set-CsprojVersion.ps1 -path MyProject.csproj -incrementrevision
>``` 
</br>

>*Version 2.6.1 updated to 2.6.2-alpha*
>```powershell
>Set-CsprojVersion.ps1 -path MyProject.csproj -patch 2 -prerelease alpha
>``` 
</br>

>*Version 3.1.3.8-beta2 updated to 3.1.4.0*
>```powershell
>Set-CsprojVersion.ps1 -path MyProject.csproj -prerelease -1 -incrementpatch -revision 0
>``` 
</br>

>*Version 1.2.1.27126 updated to 2.3.1*
>```powershell
>Set-CsprojVersion.ps1 -path MyProject.csproj -major 2 -minor 3 -build 1 -revision -1
>``` 
</br>

## Notes

Author: Michael Sivers
