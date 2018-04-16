Param (
    [string] $buildversion = "0.0.0.1"
)

function IsNotCiBuild {
    return [string]::IsNullOrWhiteSpace($Env:APPVEYOR)
}

function ExecuteCommand ([string] $command) {
    Write-Host $command
    Invoke-Expression $command
    if ($LASTEXITCODE -ne 0) {
        throw "An error occurred executing the command '$command'. LASTEXITCODE=$LASTEXITCODE"
    }
}

function RunBuild ([string] $image) {
    # Download the cached images.
    ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$image-build:latest"
    ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$image`:latest"

    # Tag the image with the previous image
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$image-build:latest cbc-$image-build:previous"
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$image`:latest cbc-$image`:previous"

    # Run the build
    ExecuteCommand "docker build --cache-from cbc-$image-build:previous -f ./build/Dockerfile.$image.build -t cbc-$image-build:latest -t appcyc.azurecr.io/cbc-$image-build:$buildversion -t appcyc.azurecr.io/cbc-$image-build:latest ."
    ExecuteCommand "docker build --cache-from cbc-$image`:previous -f ./build/Dockerfile.$image.package -t cbc-$image`:latest -t appcyc.azurecr.io/cbc-$image`:$buildversion -t appcyc.azurecr.io/cbc-$image`:latest ."

    # Push to the repository
    ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image-build:$buildversion"
    ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image-build:latest"
    ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image`:$buildversion"
    ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image`:latest"
}

RunBuild "identity"

ExecuteCommand "docker image list"
