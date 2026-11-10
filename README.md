# Exercise: Fewer Keystrokes

Exercise code for the lesson **Exercise: Fewer Keystrokes** in PowerShell in Depth on [ask-codey.com](https://www.ask-codey.com).

Grandma's 80th-birthday photo book is nearly done, and the folders are four levels deep, so every command is long. You'll set PSReadLine up the way you like it, fix a long command with keys instead of retyping it, find an old command in a saved history, and write two one-line commands that check whether the first step worked before the second one runs. A Pester check tells you which tasks are done.

## What's here

- `photo-book/`: the photo book project. `originals` has the photos by year, month and event, `edited` the edited copies, `book\page-order.txt` the book's pages, and `backup` is where copies go. The photos are small practice files with photo names. Tasks 3 and 5 add to this folder.
- `saved-history.txt`: a copy of Sam's saved PowerShell history from August, the file that `(Get-PSReadLineOption).HistorySavePath` names, one command a line. Read it; don't change it.
- `fast-settings.ps1`, `backup-line.txt`, `fallback-line.txt` and `answers.txt`: for you to finish.
- `Check.Tests.ps1`: the check. You don't need to change it.

## What to do

Open PowerShell 7 in this folder, the one with `Check.Tests.ps1` in it, and run every command from here. Use the keys from the chapter as you go: Ctrl+Left and Ctrl+Right, Ctrl+Backspace, Ctrl+Z, Esc, Ctrl+Space, the up arrow, and `#` with Tab.

**Your settings, in `fast-settings.ps1`**

1. **Predictions as a list.** Add the `Set-PSReadLineOption` line that shows predictions as a list from the start.
2. **A longer memory.** Add the `Set-PSReadLineOption` line that makes PSReadLine remember 10000 commands.

Try them in this window with `. .\fast-settings.ps1` (read "dot, space, the path"): they last until you close the window, so nothing changes for good. The check doesn't run them either: it only reads which settings the file asks for.

**Keys**

3. **The lake photo.** `IMG_0731` from the lake needs an edited copy, in a `lake` folder that doesn't exist yet. Make the folder first:

   ```powershell
   New-Item -ItemType Directory -Path photo-book\edited\2026\07-july\lake
   ```

   Then paste this line, **but don't press Enter**: its destination is missing `lake\`.

   ```powershell
   Copy-Item photo-book\originals\2026\07-july\lake\IMG_0731.jpg photo-book\edited\2026\07-july\IMG_0731-edit.jpg
   ```

   Fix it without retyping: press Ctrl+Left until the cursor is at the start of `IMG_0731` in the destination, type `lake\`, and press Enter.

**History**

4. **The zip that's still there.** In August, Sam zipped the birthday photos twice, and only `backup\birthday-edits.zip` (with an *s*) was kept. Search `saved-history.txt` with `Select-String` and write the whole command that made that zip after `4)` in `answers.txt`.

**Did it work?**

5. **Back up, and only then say so.** Write one line in `backup-line.txt`, under the comment, that copies `photo-book\edited`, with everything in it, into `photo-book\backup`, and only if that worked, prints `Backup done` with `Write-Output`. Run it here first to see it work.
6. **Read the page order, or else say so.** Write one line in `fallback-line.txt`, under the comment, that shows `photo-book\book\page-order.txt` with `Get-Content`, or, if that fails, prints `No page order yet` with `Write-Output`.
7. **A program's number.** There's no program called `photo-resizer`. Run `where.exe photo-resizer` (on a Mac or Linux, `which photo-resizer`), then `$LASTEXITCODE`, and write the number after `7)`.
8. **Worked, or True?** Run `Test-Path photo-book\backup\nothing-here.jpg`, then `$?` on the next line, and write what `$?` shows after `8)`.

To put a line into one of the files, open it in an editor (`edit backup-line.txt`, from *Editing in the Terminal: edit*), paste the line under the comment, and save.

## Check your work

The check needs Pester 5 or newer. Install it once, if you haven't already:

```powershell
Install-PSResource Pester
```

Then, from this folder:

```powershell
Invoke-Pester
```

At first every test fails: that is expected. Each task you finish turns its test green. A failing test's message says which task it is and what it found.

The check runs your lines from tasks 5 and 6 in throwaway copies of `photo-book`: one where the first command can work, and one where it can't (no `edited` folder, no `page-order.txt`). So a line joined with `;` instead of `&&` or `||` shows up, even if it looked right when you tried it. Your own `photo-book` isn't touched.

If PowerShell says the check *cannot be loaded because running scripts is disabled* or *is not digitally signed*, the folder came from a download that Windows marked as from the internet. Unblock its files once with `Get-ChildItem -Recurse | Unblock-File`, from this folder, and run `Invoke-Pester` again. *Why a Script Won't Run: The Execution Policy*, in Module 5, explains what that does.

## Tips

- `Get-PSReadLineOption` reads your settings back after you try `fast-settings.ps1`.
- Write `10000` without a comma: PowerShell reads `10,000` as a list of two numbers.
- In task 3, a word for Ctrl+Left ends at a space, `\`, `-` or `.`, so from the end of the line the stops are `jpg`, `edit`, then `IMG_0731`.
- In task 4, search for a word only the right line has.
- `&&` is "and then, if it worked"; `||` is "or else". A semicolon runs the second command either way.
- Check `$?` and `$LASTEXITCODE` right after the command you care about: every command changes `$?`.

## Hand it in

When it works, push your solution to a public repo of your own on GitHub, then paste that repo's address into **Submit your exercise** on the lesson page at [ask-codey.com](https://www.ask-codey.com). That's what completes the lesson. The lesson page shows the Git commands, step by step.
