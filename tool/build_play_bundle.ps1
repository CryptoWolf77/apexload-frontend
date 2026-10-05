param(
    [string]$FlutterExecutable = 'flutter',
    [switch]$NoPub
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'android/key.properties'))) {
    throw 'Release signing requires android/key.properties. A debug-signed bundle must not be uploaded.'
}

$previousJavaOptions = $env:JAVA_TOOL_OPTIONS
$previousFlutterAnalytics = $env:FLUTTER_SUPPRESS_ANALYTICS
$previousDartAnalytics = $env:DART_SUPPRESS_ANALYTICS
Push-Location -LiteralPath $projectRoot
try {
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    $env:DART_SUPPRESS_ANALYTICS = 'true'
    if ($env:OS -eq 'Windows_NT') {
        $javaSocketDirectory = Join-Path $projectRoot '.codex-tmp/jvm'
        New-Item -ItemType Directory -Path $javaSocketDirectory -Force | Out-Null
        $socketOption = '-Djdk.net.unixdomain.tmpdir="' + $javaSocketDirectory.Replace('\', '/') + '"'
        $env:JAVA_TOOL_OPTIONS = ($previousJavaOptions + ' ' + $socketOption).Trim()
    }
    $buildArguments = @(
        'build', 'appbundle', '--release',
        '--dart-define=APEXLOAD_ADMOB_LIVE=true',
        '--dart-define=APEXLOAD_API_BASE_URL=https://api.apexload.org',
        '--dart-define=APEXLOAD_TESTER_PREMIUM=false',
        '--dart-define=APEXLOAD_ENABLE_MOCK_ANALYZE_FALLBACK=false',
        '--dart-define=ANDROID_STORE_URL=https://play.google.com/store/apps/details?id=com.yahyazlab.apexload'
    )
    if ($NoPub) { $buildArguments += '--no-pub' }
    & $FlutterExecutable @buildArguments
    if ($LASTEXITCODE -ne 0) { throw "Flutter build failed with exit code $LASTEXITCODE." }
    Write-Output 'Play bundle: build/app/outputs/bundle/release/app-release.aab (live AdMob, production API, standard subscriptions).'
} finally {
    $env:JAVA_TOOL_OPTIONS = $previousJavaOptions
    $env:FLUTTER_SUPPRESS_ANALYTICS = $previousFlutterAnalytics
    $env:DART_SUPPRESS_ANALYTICS = $previousDartAnalytics
    Pop-Location
}
