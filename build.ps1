Param (
    [string] $buildversion = "0.0.0.1"
)

function IsNotCiBuild {
    return [string]::IsNullOrWhiteSpace($Env:APPVEYOR)
}

function ExecuteCommand ([string] $command, [bool] $throwOnError = $true) {
    Write-Host $command
    Invoke-Expression $command
    if ($LASTEXITCODE -ne 0) {
        if ($throwOnError){
            throw "An error occurred executing the command '$command'. LASTEXITCODE=$LASTEXITCODE"
        }

        return $false
    }

    return $true
}

function RunBuild ([string] $image) {
    # Download the cached images.
    $pulled = ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$image-build:latest" $false
    if ($pulled -ne $true) {
        Write-Host "There is no latest build image 'appcyc.azurecr.io/cbc-$image-build:latest' using the base image."
        ExecuteCommand "docker tag microsoft/aspnetcore-build:2.0.0 appcyc.azurecr.io/cbc-$image-build:latest"
    }

    $pulled = ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$image`:latest" $false
    if ($pulled -ne $true) {
        Write-Host "There is no latest image 'appcyc.azurecr.io/cbc-$image`:latest' using the base image."
        ExecuteCommand "docker tag microsoft/aspnetcore:2.0.0 appcyc.azurecr.io/cbc-$image`:latest"
    }

    # Tag the image with the previous image
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$image-build:latest cbc-$image-build:previous"
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$image`:latest cbc-$image`:previous"

    # Run the build
    ExecuteCommand "docker build --cache-from cbc-$image-build:previous -f ./build/$image.build.Dockerfile -t cbc-$image-build:latest -t appcyc.azurecr.io/cbc-$image-build:$buildversion -t appcyc.azurecr.io/cbc-$image-build:latest ."
    ExecuteCommand "docker build --cache-from cbc-$image`:previous -f ./build/$image.package.Dockerfile -t cbc-$image`:latest -t appcyc.azurecr.io/cbc-$image`:$buildversion -t appcyc.azurecr.io/cbc-$image`:latest ."

    # Push to the repository

    $previousBuildImage = & docker images cbc-$image-build:previous -q --no-trunc | Out-String
    $latestBuildImage = & docker images cbc-$image-build:latest -q --no-trunc | Out-String
    if ($latestBuildImage -eq $previousBuildImage) {
        Write-Host "The build image has not changed '$latestBuildImage'."
    }
    else {
        Write-Host "Pushing the new build image 'cbc-$image-build:latest'."
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image-build:$buildversion"
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image-build:latest"
    }

    $previousImage = & docker images cbc-$image`:previous -q --no-trunc | Out-String
    $latestImage = & docker images cbc-$image`:latest -q --no-trunc | Out-String
    if ($latestImage -eq $previousImage) {
        Write-Host "The image has not changed '$latestImage'."
        return $false
    }
    else {
        Write-Host "Pushing the new image 'cbc-$image`:latest'."
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image`:$buildversion"
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$image`:latest"
        return $true
    }
}

# Pull the latest base images, these are used by all the builds and are also used as the previous image if one is not
# present in the remote container repository.
ExecuteCommand "docker pull microsoft/aspnetcore-build:2.0.0"
ExecuteCommand "docker pull microsoft/aspnetcore:2.0.0"

RunBuild "identity"

ExecuteCommand "docker image list"
