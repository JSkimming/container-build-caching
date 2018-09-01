Param (
    [string] $buildVersion = "0.0.0.1",
    [string] $imagePrefix = "linux",
    [bool] $pushOnSuccess = $false,
    [bool] $labelForDevelopment = $true
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

    $buildCachedImage = ""
    $runtimeCachedImage = ""

    if ($pushOnSuccess) {
        # Download the cached images.
        $pulled = ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest" $false
        if ($pulled -eq $false) {
            Write-Host "There is no latest build image 'appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest' using the base image."
            ExecuteCommand "docker tag microsoft/dotnet:2.1-sdk appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest"
        }

        $pulled = ExecuteCommand "docker pull appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest" $false
        if ($pulled -eq $false) {
            Write-Host "There is no latest image 'appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest' using the base image."
            ExecuteCommand "docker tag microsoft/dotnet:2.1-aspnetcore-runtime appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest"
        }

        # Tag the image with the previous image
        ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest appcyc.azurecr.io/cbc-$imagePrefix-$image-build:previous"
        ExecuteCommand "docker tag appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest appcyc.azurecr.io/cbc-$imagePrefix-$image`:previous"

        $buildCachedImage = "--cache-from appcyc.azurecr.io/cbc-$imagePrefix-$image-build:previous"
        $runtimeCachedImage = "--cache-from appcyc.azurecr.io/cbc-$imagePrefix-$image`:previous"
    }

    # Run the build

    $buildImageTags = "-t cbc-$image-build-intermediate:latest"
    $runtimeImageTags = ""

    if ($labelForDevelopment) {
        $runtimeImageTags = "$runtimeImageTags -t cbc-$image`:latest"
    }

    if ($pushOnSuccess) {
        $buildImageTags = "$buildImageTags -t appcyc.azurecr.io/cbc-$imagePrefix-$image-build:$buildVersion -t appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest"
        $runtimeImageTags = "$runtimeImageTags -t appcyc.azurecr.io/cbc-$imagePrefix-$image`:$buildVersion -t appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest"
    }

    $buildImageTags = $buildImageTags.Trim()
    $runtimeImageTags = $runtimeImageTags.Trim()

    ExecuteCommand "docker build -f ./build/$image.build.Dockerfile $buildCachedImage $buildImageTags ."
    ExecuteCommand "docker build -f ./build/$image.package.Dockerfile $runtimeCachedImage $runtimeImageTags ."

    # Push to the repository
    if ($pushOnSuccess) {

        # Remove the intermediate image tag
        ExecuteCommand "docker rmi cbc-$image-build-intermediate:latest"

        $previousBuildImage = & docker images appcyc.azurecr.io/cbc-$imagePrefix-$image-build:previous -q --no-trunc | Out-String | ForEach-Object { $_.Trim() }
        $latestBuildImage = & docker images appcyc.azurecr.io/cbc-$imagePrefix-$image-build:latest -q --no-trunc | Out-String | ForEach-Object { $_.Trim() }
        if ($latestBuildImage -eq $previousBuildImage) {
            Write-Host "The build image has not changed '$latestBuildImage'."
        }
        else {
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
        else {
            Write-Host "Pushing the new image 'appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest'."
            ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image`:$buildVersion"
            ExecuteCommand "docker push appcyc.azurecr.io/cbc-$imagePrefix-$image`:latest"
            return $true
        }
    }
}

# Pull the latest base images, these are used by all the builds and are also used as the previous image if one is not
# present in the remote container repository.
ExecuteCommand "docker pull microsoft/dotnet:2.1-sdk"
ExecuteCommand "docker pull microsoft/dotnet:2.1-aspnetcore-runtime"

RunBuild "api"
RunBuild "identity"

ExecuteCommand "docker image list"
