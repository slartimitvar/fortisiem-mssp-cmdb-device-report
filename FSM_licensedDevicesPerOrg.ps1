# Define the credentials for basic authentication
$username = "super/<username>"
$password = "<password>"

# Create the auth header using Basic Authentication
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))
$headers = @{
    Authorization = "Basic $encodedCredentials"
}

# Define the orgs base URL
$baseUrlOrg = "https://<fortisiem.server>/phoenix/rest/config/Domain"

# Make GET request for orgs
$response = Invoke-RestMethod -Uri $baseUrlOrg -Headers $headers -Method Get

# Build the response
$orgArray = @()

# Loop through each org node
foreach ($item in $response.response.result.domains.domain) {

    # Add item to orgArray if id > 2000 and enabled
    if ($item.domainId -gt 2000 -and $item.disabled -eq "false") {
            $orgArray += $item.name
    }

}

# Define the devices base URL
$baseUrlDev = "https://<fortisiem.server>/phoenix/rest/cmdbDeviceInfo/devices"

# Loop on organisations
foreach ($org in $orgArray) {

    # Add org paramater into url
    $orgParameter = "?organization=" + $org
    $url = $baseUrlDev + $orgParameter

    # Make the GET request for devices
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    # Build the response
    $devArray = @()

    # Loop through each device node
    foreach ($item in $response.devices.device) {

        # Add item to array if consuming license (Approved or Pending)
        if ($item.unmanaged -eq "false") {
            if ($item.approved -eq "true") {
                $status = "approved"
            } else {
                $status = "pending"
            }
            # Create an object to store the item data
            $object = [PSCustomObject]@{
                ip  = $item.accessIp
                name = $item.name
                status = $status
            }
            # Add the object to the array
            $devArray += $object
        }
        
    }

    # Simple output of the results
    "`n--== " + $org + " ==--`n"
    $devArray
    "`nLicensed " + $org + " devices = " + $devArray.Count + "`n"
    
    # TODO: compare with previous results to alert on new Pending devices for license cost management
}
