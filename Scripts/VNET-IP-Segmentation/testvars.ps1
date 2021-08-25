$subscriptions = @()
$subscriptions += New-Object -TypeName psobject -Property @{
    name = "Services"
    region = "eastus"
    addressSize = 24
    cider = $true
}

$subscriptions += New-Object -TypeName psobject -Property @{
    name = "PreProd"
    region = "eastus"
    addressSize = 1000
    cider = $false
}

$subnets = @()

$subnets += New-Object -TypeName psobject -Property @{
    name = "vm"
    subscription = "Services"
    region = "eastus"
    addressSize = 60
    cider = $false
}

$subnets += New-Object -TypeName psobject -Property @{
    name = "management"
    subscription = "Services"
    region = "eastus"
    addressSize = 27
    cider = $true
}

$subnets += New-Object -TypeName psobject -Property @{
    name = "test"
    subscription = "PreProd"
    region = "eastus"
    addressSize = 100
    cider = $false
}

$subnets += New-Object -TypeName psobject -Property @{
    name = "dev"
    subscription = "PreProd"
    region = "eastus"
    addressSize = 100
    cider = $false
}

$cloudAddressSpace = "10.128.0.0/17"
$cloudName = "LukeCommercial"