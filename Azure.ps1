$all_lines = ""
$locations = Get-AzureRmLocation
foreach ($locat in $locations)
{

#$size = Get-AzureRmVMSize -Location $locat | Where-Object {$_.Name -eq "Standard_F4"}
$size = Get-AzureRmVMSize $locat.Location | Where-Object {$_.Name -eq "Standard_F4"}

if ($size.Name -eq "Standard_F4")
{  

# Variables for common values
$resourceGroup = "Coin"
$location = $locat.Location
$vmName = "Ubu1"+$location

"--------- "+$location+" --------- "


$rg = New-AzureRmResourceGroup -ResourceGroupName "coin1$location" -Location $location

$resourceGroup = "coin1$location"

# Definer user name and blank password
$securePassword = ConvertTo-SecureString 'LONG-AND-SECURE-PASSWORD' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("YOUR_USER_NAME", $securePassword)

# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name mySubnet2 -AddressPrefix 192.168.2.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name MYvNET2 -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$publicIp = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4
$publicIp | Select-Object Name,IpAddress

foreach ( $ipad in $publicIp)
{
$line = "putty.exe "+$ipad.IpAddress+" -l YOUR_USER_NAME -pw LONG-AND-SECURE-PASSWORD `r`n"
}
$all_lines = $all_lines + $line

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleSSH  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 22 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name myNetworkSecurityGroup2 -SecurityRules $nsgRuleSSH

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -Name myNic2 -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id


  # Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_F4 |
  Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred |
  Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 16.04-LTS -Version latest |
  Add-AzureRmVMNetworkInterface -Id $nic.Id

#$vmConfig.DiagnosticsProfile = $null

New-AzureRmStorageAccount -StorageAccountName "storage1$location" -Location $location -ResourceGroupName $resourceGroup -Type "Standard_LRS"

# Create a virtual machine
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig



  }

}

$all_lines