$publishModuleSplat = @{
    Path        = ".\FindObsolete"
    NuGetApiKey = $ENV:nugetapikey
    Verbose     = $true
    Force       = $true
    Repository  = "PSGallery"
    ErrorAction = 'Stop'
}

Install-Module Select-Ast -Scope CurrentUser -Force

"Files in module output:"
Get-ChildItem $Destination -Recurse -File |
    Select-Object -Expand FullName

"Publishing [$Destination] to [$PSRepository]"

Publish-Module @publishModuleSplat