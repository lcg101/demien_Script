# PowerShell 스크립트: disk_info.ps1


Write-Host "PHYSICAL"
Write-Host "---------------------------------------------------------"
Write-Host "TYPE     SIZE                 RSIZE       MODEL                        STATE"
Write-Host "---------------------------------------------------------"

$disks = Get-PhysicalDisk | ForEach-Object {
    $disk = $_
    $model = $disk.Model
    $manufacturerSize = [math]::Floor($disk.Size / 1000000000) 
    $state = $disk.OperationalStatus

    
    $diskNumber = (Get-Disk | Where-Object { $_.Number -eq $disk.DeviceID }).Number

    
    $partitions = Get-Partition -DiskNumber $diskNumber
    $rsize = $partitions | Measure-Object -Property Size -Sum | Select-Object -ExpandProperty Sum
    $rsize = [math]::Floor($rsize / 1GB) 

    
    Write-Host ("{0,-7} {1,-20} {2,-11} {3,-30} {4,-5}" -f "Disk", "$manufacturerSize GB", "$rsize GB", $model, $state)
}

Write-Host ""
