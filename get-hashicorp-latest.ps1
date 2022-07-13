param(
    [ValidateSet("terraform", "vault", "packer")]
    [string]$bin,
    [string]$bin_path = "C:\Terraform" ,
    [string]$bin_arch = "amd64"
)

function format-path {
    param (
        [string]$path
    )
    if (-not $path.EndsWith("\")) {
        $path = $path + "\"
    }
    return $path
}

$bin_path = format-path -path $bin_path

# Get installed versions
function get-current-bin-version () {
    param (
        [string]$bin
    )
    # Regex for version number
    [regex]$regex = '\d+\.\d+\.\d+'
	
    # Build terraform command and run it
    $command = "$bin_path" + "$bin" + ".exe"
    $version = &$command version | Write-Output

    # Match and return versions
    [string]$version -match $regex > $null
    return $Matches[0]
}

function get-latest-bin-version {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("terraform", "vault", "packer")]
        [string]$bin
    )

    $release_url = "https://api.github.com/repos/hashicorp/$bin/releases/latest"

    # Get web content and convert from JSON
    $web_content = Invoke-WebRequest -Uri $release_url -UseBasicParsing | ConvertFrom-Json

    return $web_content.tag_name.replace("v", "")
}

function download-binary {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("terraform", "vault", "packer")]
        [string]$bin
    )

    Write-Host "Downloading latest version"

    # Build download URL
    $url = "https://releases.hashicorp.com/$bin/$(get-latest-bin-version -bin $bin)/$bin" + "_$(get-latest-bin-version -bin $bin)_windows_" + $bin_arch + ".zip"

    # Output folder (in location provided)
    $download_location = $bin_path + $bin + ".zip"

    # Set TLS to 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download terraform
    Invoke-WebRequest -Uri $url -OutFile $download_location > $null

    # Unzip terraform and replace existing terraform file
    Write-Host "Installing latest terraform"
    Expand-Archive -Path $download_location -DestinationPath $bin_path -Force

    # Remove zip file
    Write-Host "Remove zip file"
    Remove-Item $download_location -Force
}

# Check if terraform exists in $bin_path
if (-not (Test-Path ("$bin_path" + "$bin" + ".exe"))) {
    Write-Host "$bin could not be located in $bin_path"
    Write-Host
    download-binary -bin $bin
}

# Check if current version is different than latest version
elseif ((get-current-bin-version -bin $bin) -ne (get-latest-bin-version -bin $bin)) {
    # Write basic info to sceen
    Write-Host "Current $bin version: $(get-current-bin-version -bin $bin)"
    Write-Host "Latest $bin Version: $(get-latest-bin-version -bin $bin)"
    Write-Host
    download-binary -bin $bin
}

# If versions match, display message
else {
    Write-Host "Latest Terraform already installed."
    Write-Host
    Write-Host "Current $bin version: $(get-current-bin-version -bin $bin)"
    Write-Host "Latest $bin Version: $(get-latest-bin-version -bin $bin)"
}