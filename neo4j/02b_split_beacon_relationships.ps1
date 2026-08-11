# Split the large parcel-beacon CSV into smaller chunks
# to avoid loading the entire file into memory.

# --- CONFIG ---
$inputFile  = "C:\path\to\beacon_parcel_block_link.csv"
$outputDir  = "C:\path\to\chunks"
$rowsPerFile = 500000  # data rows per chunk (excluding header)

# --- PRECHECKS ---
if (-not (Test-Path -LiteralPath $inputFile)) {
  throw "Input file not found: $inputFile"
}

# Ensure output directory exists
[void][System.IO.Directory]::CreateDirectory($outputDir)

# --- STREAMED SPLIT (no huge memory use) ---
$reader = [System.IO.File]::OpenText($inputFile)

try {
  $header = $reader.ReadLine()
  $i = 0
  $fileIndex = 0

  function New-Writer([int]$idx, [string]$hdr) {
    $name = ("chunk_{0:D3}.csv" -f $idx)
    $path = Join-Path $outputDir $name
    $w = New-Object System.IO.StreamWriter(
      $path,
      $false,
      [System.Text.Encoding]::UTF8
    )
    $w.WriteLine($hdr)
    return $w
  }

  $writer = New-Writer -idx $fileIndex -hdr $header

  while (($line = $reader.ReadLine()) -ne $null) {
    if (($i -gt 0) -and ($i % $rowsPerFile -eq 0)) {
      $writer.Flush()
      $writer.Dispose()

      $fileIndex++
      $writer = New-Writer -idx $fileIndex -hdr $header
    }

    $writer.WriteLine($line)
    $i++
  }

  $writer.Flush()
  $writer.Dispose()
}
finally {
  $reader.Close()
  $reader.Dispose()
}

Write-Host "Done. Wrote $($fileIndex + 1) chunk file(s) to $outputDir"
