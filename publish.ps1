$publishModuleSplat = @{
    Path        = ".\FindObsolete"
    NuGetApiKey = $ENV:nugetapikey
    Verbose     = $true
    Force       = $true
    Repository  = "PSGallery"
    ErrorAction = 'Stop'
}

Instal-Module Select-Ast -Scope CurrentUser

"Files in module output:"
Get-ChildItem $Destination -Recurse -File |
    Select-Object -Expand FullName

"Publishing [$Destination] to [$PSRepository]"

Publish-Module @publishModuleSplat