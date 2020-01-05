param(
	[String]$deviceID,
	[int]$disableTime=3
)

write-host $deviceID
write-host "Disabling device for $disableTime s"

disable-pnpdevice -instanceid $deviceID -confirm:$false
start-sleep $disableTime
enable-pnpdevice -instanceid $deviceID -confirm:$false

write-host "Device re-enabled."
write-host "We're done"

start-sleep 10

