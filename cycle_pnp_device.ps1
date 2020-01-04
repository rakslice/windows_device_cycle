param(
	[String]$deviceID,
	[int]$disableTime=3
)

echo $deviceID
echo "Disabling device for $disableTime s"

disable-pnpdevice -instanceid $deviceID -confirm:$false
start-sleep $disableTime
enable-pnpdevice -instanceid $deviceID -confirm:$false

echo "Device re-enabled."
echo "We're done"

start-sleep 10

