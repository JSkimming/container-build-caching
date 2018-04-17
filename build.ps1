Param (
    [string] $buildVersion = "0.0.0.1",
    [string] $imagePrefix = "linux"
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
}

function RunBuild ([string] $image) {
    # Download the cached images.
    $pulled = ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest" $false
    if ($pulled -eq $false) {
        Write-Host "There is no latest build image 'appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest' using the base image."
        ExecuteCommand "docker tag microsoft/aspnetcore-build:2.0.0 appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest"
    }

    $pulled = ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest" $false
    if ($pulled -eq $false) {
        Write-Host "There is no latest image 'appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest' using the base image."
        ExecuteCommand "docker tag microsoft/aspnetcore:2.0.0 appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest"
    }

    # Tag the image with the previous image
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest cbc-$imagePrefix-$image-build:previous"
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest cbc-$imagePrefix-$image`:previous"

    # Run the build
    ExecuteCommand "docker build -f ./build/$image.build.Dockerfile --cache-from cbc-$imagePrefix-$image-build:previous -t cbc-$image-build-intermediate -t cbc-$imagePrefix-$image-build:latest -t appcyc.azurecr.io/cbc-$imagePrefix-$image-build:$buildVersion -t appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest ."
    ExecuteCommand "docker build -f ./build/$image.package.Dockerfile --cache-from cbc-$imagePrefix-$image`:previous -t cbc-$imagePrefix-$image`:latest -t appcyc.azurecr.io/cbc-$imagePrefix-$image`:$buildVersion -t appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest ."

    # Remove the intermediate image tag
    ExecuteCommand "docker rmi cbc-$image-build-intermediate"

    # Push to the repository

    $previousBuildImage = & docker images cbc-$imagePrefix-$image-build:previous -q --no-trunc | Out-String
    $latestBuildImage = & docker images cbc-$imagePrefix-$image-build:latest -q --no-trunc | Out-String
    if ($latestBuildImage -eq $previousBuildImage) {
        Write-Host "The build image has not changed '$latestBuildImage'."
    }
    else {
        Write-Host "Pushing the new build image 'cbc-$imagePrefix-$image-build:latest'."
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image-build:$buildVersion"
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest"
    }

    $previousImage = & docker images cbc-$imagePrefix-$image`:previous -q --no-trunc | Out-String
    $latestImage = & docker images cbc-$imagePrefix-$image`:latest -q --no-trunc | Out-String
    if ($latestImage -eq $previousImage) {
        Write-Host "The image has not changed '$latestImage'."
        return $false
    }
    else {
        Write-Host "Pushing the new image 'cbc-$imagePrefix-$image`:latest'."
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image`:$buildVersion"
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest"
        return $true
    }
}

# Pull the latest base images, these are used by all the builds and are also used as the previous image if one is not
# present in the remote container repository.
ExecuteCommand "docker pull microsoft/aspnetcore-build:2.0.0"
ExecuteCommand "docker pull microsoft/aspnetcore:2.0.0"

RunBuild "identity"

ExecuteCommand "docker image list"
