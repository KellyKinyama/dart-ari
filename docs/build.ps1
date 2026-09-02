#Requires -Version 5.1
<#
.SYNOPSIS
    Regenerate DOCX / HTML / PDF from every .md under docs/ using pandoc.

.EXAMPLE
    .\docs\build.ps1                 # build every docs/*.md into all three formats
    .\docs\build.ps1 -Only dashboard-sow.md
    .\docs\build.ps1 -Formats docx
#>

[CmdletBinding()]
param(
    [string[]]$Only,
    [ValidateSet('docx', 'html', 'pdf', 'all')]
    [string[]]$Formats = @('all')
)

$ErrorActionPreference = 'Stop'
$docsDir = Split-Path -Parent $PSCommandPath
$repoRoot = Split-Path -Parent $docsDir

if (-not (Get-Command pandoc -ErrorAction SilentlyContinue)) {
    Write-Error "pandoc not found. Install with: winget install --id JohnMacFarlane.Pandoc"
    exit 1
}

$targets = @(
    Get-ChildItem -Path $docsDir -Filter '*.md' -File |
        Where-Object { -not $Only -or $Only -contains $_.Name }
)

if (-not $targets) {
    Write-Warning "No matching Markdown files under $docsDir"
    exit 0
}

$wantAll  = $Formats -contains 'all'
$wantDocx = $wantAll -or ($Formats -contains 'docx')
$wantHtml = $wantAll -or ($Formats -contains 'html')
$wantPdf  = $wantAll -or ($Formats -contains 'pdf')

$hasWkhtml = [bool](Get-Command wkhtmltopdf -ErrorAction SilentlyContinue)
if ($wantPdf -and -not $hasWkhtml) {
    Write-Warning "wkhtmltopdf not on PATH -- skipping PDF. Install: winget install --id wkhtmltopdf.wkhtmltopdf"
}

foreach ($src in $targets) {
    $stem = [IO.Path]::GetFileNameWithoutExtension($src.Name)
    $title = (Get-Culture).TextInfo.ToTitleCase(($stem -replace '[-_]+', ' '))
    Write-Host "==> $($src.Name)" -ForegroundColor Cyan

    if ($wantDocx) {
        $out = Join-Path $docsDir "$stem.docx"
        pandoc $src.FullName `
            --from=gfm `
            --to=docx `
            --output=$out `
            --toc --toc-depth=2
        if ($LASTEXITCODE -eq 0) { Write-Host "    docx -> $out" -ForegroundColor Green }
    }

    if ($wantHtml) {
        $out = Join-Path $docsDir "$stem.html"
        pandoc $src.FullName `
            --from=gfm `
            --to=html5 `
            --standalone --embed-resources `
            --toc --toc-depth=2 `
            --metadata "title=$title" `
            --output=$out
        if ($LASTEXITCODE -eq 0) { Write-Host "    html -> $out" -ForegroundColor Green }
    }

    if ($wantPdf -and $hasWkhtml) {
        $out = Join-Path $docsDir "$stem.pdf"
        pandoc $src.FullName `
            --from=gfm `
            --to=pdf `
            --pdf-engine=wkhtmltopdf `
            --toc --toc-depth=2 `
            --output=$out
        if ($LASTEXITCODE -eq 0) { Write-Host "    pdf  -> $out" -ForegroundColor Green }
    }
}
