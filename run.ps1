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

function RunLocalBuild ([string] $image) {
    # Run the build
    ExecuteCommand "docker build -f ./build/$image.build.Dockerfile -t cbc-$image-build-intermediate ."
    ExecuteCommand "docker build -f ./build/$image.package.Dockerfile -t cbc-$image`:latest ."
}

RunLocalBuild "api"
RunLocalBuild "identity"

ExecuteCommand "docker-compose up"
