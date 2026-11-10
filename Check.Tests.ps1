# Checks the eight tasks in README.md, one test per task.
# It never changes your PSReadLine settings or your history, and it runs your two one-line commands only in
# throwaway copies of photo-book, so your own folder stays as it is.
# Run it from this folder with: Invoke-Pester
# You don't need to change this file.

BeforeAll {
    # answers.txt: "4) answer" lines, by task number.
    $script:answers = @{}
    foreach ($line in Get-Content (Join-Path $PSScriptRoot 'answers.txt')) {
        if ($line -match '^\s*(\d+)\)\s*(.*)$') {
            $script:answers[[int]$Matches[1]] = $Matches[2].Trim().Trim("'", '"')
        }
    }

    # The first line of a file that isn't empty and isn't a # comment, or $null.
    function Get-LearnerLine([string] $name) {
        $path = Join-Path $PSScriptRoot $name
        if (-not (Test-Path -LiteralPath $path)) { return $null }
        Get-Content -LiteralPath $path | Where-Object { $_.Trim() -ne '' -and -not $_.TrimStart().StartsWith('#') } |
            Select-Object -First 1
    }

    # What fast-settings.ps1 asks Set-PSReadLineOption for. A stand-in function catches each call, so nothing is
    # really set: the file is read in a scope where Set-PSReadLineOption is that stand-in.
    function Get-SettingsCall {
        $calls = [System.Collections.Generic.List[object]]::new()
        $file = Join-Path $PSScriptRoot 'fast-settings.ps1'
        & {
            function Set-PSReadLineOption {
                param($PredictionViewStyle, $MaximumHistoryCount)
                $calls.Add([pscustomobject]@{ PredictionViewStyle = "$PredictionViewStyle"; MaximumHistoryCount = $MaximumHistoryCount })
            }
            . $file
        }
        $calls
    }

    # Runs one line in PowerShell 7, in a throwaway copy of photo-book, and returns what it printed and where.
    function Invoke-InCopy([string] $line, [switch] $WithoutEdited, [switch] $WithoutPageOrder) {
        $dir = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $dir | Out-Null
        Copy-Item -Path (Join-Path $PSScriptRoot 'photo-book') -Destination $dir -Recurse
        Get-ChildItem (Join-Path $dir 'photo-book/backup') -Exclude 'README.txt' | Remove-Item -Recurse -Force
        if ($WithoutEdited) { Remove-Item (Join-Path $dir 'photo-book/edited') -Recurse -Force }
        if ($WithoutPageOrder) { Remove-Item (Join-Path $dir 'photo-book/book/page-order.txt') -Force }
        $pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        $exe = if ($pwsh) { $pwsh.Source } else { (Get-Process -Id $PID).Path }
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($line))
        Push-Location $dir
        try { $out = & $exe -NoProfile -NonInteractive -EncodedCommand $encoded 2>&1 | Out-String }
        finally { Pop-Location }
        [pscustomobject]@{ Output = $out; Folder = $dir }
    }
}

Describe 'Exercise: Fewer Keystrokes' {

    It '1) fast-settings.ps1 shows predictions as a list' {
        $calls = @(Get-SettingsCall)
        $calls.Count | Should -BeGreaterThan 0 -Because 'task 1 adds a Set-PSReadLineOption line to fast-settings.ps1 (it has none yet)'
        @($calls.PredictionViewStyle) | Should -Contain 'ListView' -Because 'task 1 is Set-PSReadLineOption -PredictionViewStyle ListView'
    }

    It '2) fast-settings.ps1 remembers 10000 commands' {
        $last = Get-SettingsCall | Where-Object { $null -ne $_.MaximumHistoryCount } | Select-Object -Last 1
        $last | Should -Not -BeNullOrEmpty -Because 'task 2 adds Set-PSReadLineOption -MaximumHistoryCount to fast-settings.ps1'
        "$($last.MaximumHistoryCount)" | Should -Match '^\d+$' -Because 'the history count is one number: write 10000 without a comma (with one, PowerShell reads 10,000 as a list of two numbers)'
        [int]"$($last.MaximumHistoryCount)" | Should -BeGreaterOrEqual 10000 -Because 'task 2 raises the history from 4096 to 10000 commands'
    }

    It '3) the lake photo is copied into edited\2026\07-july\lake' {
        $right = Join-Path $PSScriptRoot 'photo-book/edited/2026/07-july/lake/IMG_0731-edit.jpg'
        $wrong = Join-Path $PSScriptRoot 'photo-book/edited/2026/07-july/IMG_0731-edit.jpg'
        Test-Path -LiteralPath $right | Should -BeTrue -Because 'task 3 makes the folder photo-book\edited\2026\07-july\lake, then copies originals\2026\07-july\lake\IMG_0731.jpg into it as IMG_0731-edit.jpg'
        Test-Path -LiteralPath $wrong | Should -BeFalse -Because 'a copy landed in 07-july itself, outside the lake folder: the line was run before lake\ was added. Remove that one (Remove-Item with -WhatIf first)'
    }

    It '4) answers.txt has the command that made backup\birthday-edits.zip' {
        $answers[4] | Should -Not -BeNullOrEmpty -Because 'task 4 has no answer yet. Search saved-history.txt with Select-String'
        ($answers[4] -replace '\s+', ' ') | Should -Be 'Compress-Archive -Path edited\2026\08-august\birthday -DestinationPath backup\birthday-edits.zip -Force' -Because 'two lines in saved-history.txt zip the birthday photos; only one makes birthday-edits.zip, with an s. Copy the whole line'
    }

    It '5) backup-line.txt copies the edited photos, and only then says Backup done' {
        $line = Get-LearnerLine 'backup-line.txt'
        $line | Should -Not -BeNullOrEmpty -Because 'task 5 has no line yet in backup-line.txt'
        $ok = Invoke-InCopy $line
        Test-Path (Join-Path $ok.Folder 'photo-book/backup/edited/2026/08-august/birthday/IMG_0815-edit.jpg') | Should -BeTrue -Because "the line copies photo-book\edited, with everything in it, into photo-book\backup (Copy-Item -Recurse). It printed: $($ok.Output.Trim())"
        $ok.Output | Should -Match 'Backup done' -Because 'when the copy works, the line prints Backup done with Write-Output'
        $broken = Invoke-InCopy $line -WithoutEdited
        $broken.Output | Should -Not -Match 'Backup done' -Because 'in a copy of photo-book with no edited folder, the copy fails, so Backup done must not print: join the two commands with &&, not ;'
    }

    It '6) fallback-line.txt reads the page order, or else says there is none' {
        $line = Get-LearnerLine 'fallback-line.txt'
        $line | Should -Not -BeNullOrEmpty -Because 'task 6 has no line yet in fallback-line.txt'
        $with = Invoke-InCopy $line
        $with.Output | Should -Match 'Page 1: IMG_0815-edit\.jpg' -Because "when photo-book\book\page-order.txt is there, the line shows it with Get-Content. It printed: $($with.Output.Trim())"
        $with.Output | Should -Not -Match 'No page order yet' -Because 'the message is only for when the file is missing: join the two commands with ||'
        $without = Invoke-InCopy $line -WithoutPageOrder
        $without.Output | Should -Match 'No page order yet' -Because 'in a copy of photo-book with no page-order.txt, Get-Content fails, so the line prints No page order yet with Write-Output'
    }

    It '7) answers.txt has the exit code where.exe ends with for a program that is not there' {
        $answers[7] | Should -Not -BeNullOrEmpty -Because 'task 7 has no answer yet. Run where.exe photo-resizer (which photo-resizer on a Mac or Linux), then $LASTEXITCODE'
        $answers[7] | Should -Be '1' -Because 'a program that did not find what it looked for ends with a number other than 0. $LASTEXITCODE shows it, right after the program'
    }

    It '8) answers.txt has what $? says right after Test-Path on a missing file' {
        $answers[8] | Should -Not -BeNullOrEmpty -Because 'task 8 has no answer yet. Run Test-Path photo-book\backup\nothing-here.jpg, then $? on the next line'
        ($answers[8] -replace '^\$', '') | Should -Be 'True' -Because 'Test-Path answered False, but it worked: $? says whether a command worked, not what it answered'
    }
}
