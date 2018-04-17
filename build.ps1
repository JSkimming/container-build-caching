Param (
    [string] $buildVersion = "0.0.0.1",
    [string] $imagePrefix = "linux",
    [bool] $pushOnSuccess = $false
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
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest appcyc.azurecr.io/cbc-$imagePrefix-$image-build:previous"
    ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest appcyc.azurecr.io/cbc-$imagePrefix-$image`:previous"

    # Run the build
    ExecuteCommand "docker build -f ./build/$image.build.Dockerfile --cache-from appcyc.azurecr.io/cbc-$imagePrefix-$image-build:previous -t cbc-$image-build-intermediate -t appcyc.azurecr.io/cbc-$imagePrefix-$image-build:$buildVersion -t appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest ."
    ExecuteCommand "docker build -f ./build/$image.package.Dockerfile --cache-from appcyc.azurecr.io/cbc-$imagePrefix-$image`:previous -t appcyc.azurecr.io/cbc-$imagePrefix-$image`:$buildVersion -t appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest ."

    # Remove the intermediate image tag
    ExecuteCommand "docker rmi cbc-$image-build-intermediate"

    # Push to the repository

    $previousBuildImage = & docker images appcyc.azurecr.io/cbc-$imagePrefix-$image-build:previous -q --no-trunc | Out-String | ForEach-Object { $_.Trim() }
    $latestBuildImage = & docker images appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest -q --no-trunc | Out-String | ForEach-Object { $_.Trim() }
    if ($latestBuildImage -eq $previousBuildImage) {
        Write-Host "The build image has not changed '$latestBuildImage'."
    }
    elseif ($pushOnSuccess) {
        Write-Host "Pushing the new build image 'appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest'."
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image-build:$buildVersion"
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest"
    }

    $previousImage = & docker images appcyc.azurecr.io/cbc-$imagePrefix-$image`:previous -q --no-trunc | Out-String | ForEach-Object { $_.Trim() }
    $latestImage = & docker images appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest -q --no-trunc | Out-String | ForEach-Object { $_.Trim() }
    if ($latestImage -eq $previousImage) {
        Write-Host "The image has not changed '$latestImage'."
        return $false
    }
    elseif ($pushOnSuccess) {
        Write-Host "Pushing the new image 'appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest'."
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image`:$buildVersion"
        ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest"
        return $true
    }
}

# Pull the latest base images, these are used by all the builds and are also used as the previous image if one is not
# present in the remote container repository.
ExecuteCommand "docker pull microsoft/aspnetcore-build:2.0.0"
ExecuteCommand "docker pull microsoft/aspnetcore:2.0.0"

RunBuild "api"
RunBuild "identity"

ExecuteCommand "docker image list"
