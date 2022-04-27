<#
.SYNOPSIS
Quick and dirty script to get process information friendly in powershell
Author: Arale61 (@arale61)

Required Dependencies: None
Optional Dependencies: None
.DESCRIPTION
Outputs in a tree format the running processes with cmdline information.
It's a quick and dirty way that is not performing fast.
.PARAMETER levels
Specifies the level of child to try to resolve.
.PARAMETER OutFile
Specifies full path to dump output to.
.PARAMETER OwnerInfo
Specifies to try to get the owner information for each process.
.EXAMPLE
Get-PsTree
.EXAMPLE
Get-PsTree -OwnerInfo
.EXAMPLE
Get-PsTree -levels 6
.EXAMPLE
Get-PsTree -OutFile "c:\programdata\processes.txt"
.EXAMPLE
Get-PsTree -OutFile "c:\programdata\processes.txt" -OwnerInfo
#>
function Get-PsTree(){
    param(
        $levels=4,
        $OutFile="",
        [switch]
        $OwnerInfo
    )
    Set-Variable -Name doneProc -Option AllScope
    $procs = get-wmiobject -class Win32_Process;
    $doneProc = @();
    $groupped = $procs | Select-Object -property ParentProcessId,ProcessId,Name,CommandLine |group-object -property ParentprocessId ;

    function PrintProcessLine($process, $level){
        $tab = "`t" * $level
        $ownerData = "-"
        if($OwnerInfo -eq $true){
            try {
                $owner = $_.GetOwner()
            }
            catch {}
            
            if ($null -ne $owner -and !([string]::IsNullOrEmpty($owner.User))){
                if (!([string]::IsNullOrEmpty($owner.Domain))){
                    $ownerData = "$($owner.Domain)\$($owner.User)"
                }
                elseif(!([string]::IsNullOrEmpty($owner.PSComputerName))){
                    $ownerData = "$($owner.PSComputerName)\$($owner.User)"
                }else{
                    $ownerData = "$($owner.User)"
                }
            }
            
        }

        Write-Host
        Write-Host -ForegroundColor Yellow -NoNewLine "$($tab)$($currentProc.ProcessId): "
        if($OwnerInfo -eq $true){
            Write-Host -ForegroundColor Green -NoNewLine "$($ownerData) "
        }
        Write-Host -ForegroundColor White -NoNewLine "$($currentProc.Name) "
        Write-Host -ForegroundColor Gray -NoNewLine "$($($currentProc.CommandLine))"

        if(!([string]::IsNullOrEmpty($OutFile))){
            if($OwnerInfo -eq $true){
                "$($tab)$($currentProc.ProcessId): $($ownerData) $($currentProc.Name) $($currentProc.CommandLine)" | out-file $OutFile -Append -Width 2147483647;
            }else{
                "$($tab)$($currentProc.ProcessId): $($currentProc.Name) $($currentProc.CommandLine)" | out-file $OutFile -Append -Width 2147483647;
            }
        }
    }

    function PrintParentAndChilds($currentProc, $currentLevel){
        if ($currentProc.ProcessId -notin $doneProc){ 
            $ProcessId=$currentProc.ProcessId;
            PrintProcessLine $currentProc $currentLevel
            $doneProc += @($ProcessId);
        }
        if ($currentLevel -lt $levels){
            $procs | where-object { $_.ParentProcessId -eq $ProcessId -and $_.ProcessId -ne $ProcessId} | foreach-object {
                $newLevel = $currentLevel + 1
                PrintParentAndChilds $_  $newLevel
            }
        }
    }

    # començar amb l'agrupació i aquells q son top process (parentProcessId -eq 0) o aquells sense pare?
    $procs | where-object { ($_.ParentProcessId -eq 0 -or $null -eq $_.ParentProcessId) -or ($_.ProcessId -in $groupped.Values) }| foreach-object { 
        if ($_.ProcessId -notin $doneProc){
            PrintParentAndChilds $_ 0
            Write-Host
        }
    }

    # fer la resta...
    $procs | where-object { $_.ProcessId -notin $doneProc } | foreach-object {
        PrintParentAndChilds $_ 0
        Write-Host
    }
}

# Get-PsTree