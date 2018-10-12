<#
.SYNOPSIS    
    Corrects a refractometer reading (in Brix or specific gravity) from fermenting wort. 

.DESCRIPTION    
    Author: engageant
    Source: https://github.com/engageant/PSRefractometerCalc
    License: GNU GPLv3
    Credits: This code is adapted from Jonathan Braley's Python tool. Thanks also to Sean Terrill and his wort correction formula.

.PARAMETER OriginalGravity
    The original gravity reading, in either SG or Brix

.PARAMETER FinalGravity
    The measured final gravity reading, in either SG or Brix as shown on your hyrdometer

.PARAMETER AsBrix
    If you supply the OG and FG in Brix, you must specify this switch  

.EXAMPLE
    Convert-RefractometerReading.ps1 -OriginalGravity 1.067 -FinalGravity 1.033
    Adjusts a wort sample with an OG of 1.067 and a final gravity of 1.033 (as measured by your refractometer)

.EXAMPLE
    Convert-RefractometerReading.ps1 -OG 16.36 -FG 8.29 -AsBrix
    Adjusts a wort sample with an OG of 16.36 and a FG of 8.29, as measured by your refractometer and specified in Brix 

.LINK
https://github.com/engageant/PSRefractometerCalc

.LINK
    https://github.com/DAMNITRENZO/Refractometer_ABV_Python

.LINK
    http://seanterrill.com/2011/04/07/refractometer-fg-results/
#>

[cmdletBinding(DefaultParameterSetName = "SG")]
Param(    
    [Parameter(ParameterSetName = "SG", Mandatory = $true, Position = 0)]    
    [Parameter( ParameterSetName = "Brix", Mandatory = $true, Position = 0)]    
    [alias("OG")]          
    [double]$OriginalGravity,           
    
    [Parameter(ParameterSetName = "SG", Mandatory = $true, Position = 1)]    
    [Parameter(ParameterSetName = "Brix", Mandatory = $true, Position = 1)]        
    [alias("FG")]    
    [double]$FinalGravity,       
    
    [Parameter(ParameterSetName = "Brix", Mandatory = $false, Position = 2)]         
    [switch]$AsBrix
)

#region Function Declarations

#Converts specific gravity to Brix
function ConvertTo-Brix {
    [cmdletBinding()]
    Param(
        #the gravity reading to convert
        [Parameter(Mandatory = $true)]
        [double]$Gravity
    )

    [math]::Round((((182.4601 * $Gravity - 775.6821) * $Gravity + 1262.7794) * $Gravity - 669.5622), 2)    
}

#Converts Brix to specific gravity
function ConvertTo-SpecificGravity {
    [cmdletBinding()]
    Param(
        #the gravity reading to convert
        [Parameter(Mandatory = $true)]
        [double]$Gravity
    )
    
    [math]::Round(($Gravity / (258.6 - (($Gravity / 258.2) * 227.1))) + 1, 3)     
}

#Corrects a refractometer reading of fermented wort (in Brix)
function ConvertTo-AdjustedFinalGravity {
    [cmdletBinding()]
    Param(
        #the OG reading to convert (in Brix)
        [Parameter(Mandatory = $true)]        
        [double]$OG,
        
        #the FG reading to convert (in Brix)
        [Parameter(Mandatory = $true)]        
        [double]$FG       
    )    
   
    [decimal]$gravity = [math]::Round((1.0000 - 0.00085683 * $OG + 0.0034941 * $FG), 3)   
    $gravity    
}

function Measure-AlcoholByVolume {
    [cmdletBinding()]
    Param(
        #the OG reading (as SG)
        [Parameter(Mandatory = $true)]
        [double]$OriginalGravity,
        
        #the adjusted FG reading (as SG)
        [Parameter(Mandatory = $true)]
        [double]$AdjustedFinalSpecificGravity
    )
    
    [double]$abv = [math]::Round(($OriginalGravity - $AdjustedFinalSpecificGravity) * 131.25, 2)
    $abv
}

function Measure-Attenuation {
    [cmdletBinding()]
    Param(
        #the OG reading (as SG)
        [Parameter(Mandatory = $true)]
        [double]$OriginalGravity,
        
        #the adjusted FG reading (as SG)
        [Parameter(Mandatory = $true)]
        [double]$AdjustedFinalSpecificGravity
    )

    [double]$attenuation = [math]::Round((($OriginalGravity - 1) * 1000 - ($AdjustedFinalSpecificGravity - 1) * 1000) / (($OriginalGravity - 1) * 10), 2)
    $attenuation
}

function Measure-Calories {
    [cmdletBinding()]
    Param(
        #the OG reading (as SG)
        [Parameter(Mandatory = $true)]
        [double]$OriginalGravity,
        
        #the adjusted FG reading (as SG)
        [Parameter(Mandatory = $true)]
        [double]$AdjustedFinalSpecificGravity
    )

    [double]$caloriesFromAlcohol = 1881.22 * $AdjustedFinalSpecificGravity * ($OriginalGravity - $AdjustedFinalSpecificGravity) / (1.775 - $OriginalGravity)
    [double]$caloriesFromCarbs = 3550 * $AdjustedFinalSpecificGravity * ((0.1808 * $OriginalGravity) + (0.8192 * $AdjustedFinalSpecificGravity) - 1.0004)
    [double]$calories = [math]::Round($caloriesFromAlcohol + $caloriesFromCarbs, 2)
    $calories
}

#Validates input parameters
function ValidateParams {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [switch]$AsBrix
    )

    if ($OriginalGravity -lt $FinalGravity) {
        Write-Error "Original gravity must be higher than final gravity." -Category InvalidArgument
        exit
    }
    if ($AsBrix) {        
        if (($OriginalGravity -lt 0) -or ($OriginalGravity -gt 44.1) -or ($FinalGravity -lt 0) -or ($FinalGravity -gt 44.1)) {
            Write-Error "Gravities must be between 0 and 44.1" -Category InvalidArgument
            exit
        } 
    }
    else {
        if (($OriginalGravity -lt 0) -or ($OriginalGravity -gt 1.200) -or ($FinalGravity -lt 0) -or ($FinalGravity -gt 1.200)) {
            Write-Error "Gravities must be between 0 and 1.200" -Category InvalidArgument
            exit
        } 
    }
}
#endregion

#region Main

switch ($PSCmdlet.ParameterSetName) {
    "Brix" {      
        ValidateParams -AsBrix
        #ConvertTo-AdjustedFinalGravity takes its input as Brix, so let's grab that value before we convert it to SG
        $adjustedFG = ConvertTo-AdjustedFinalGravity -OG $OriginalGravity -FG $FinalGravity
        #the rest of the functions are based on specific gravity, so let's convert them
        $OriginalGravity = ConvertTo-SpecificGravity $OriginalGravity
        $FinalGravity = ConvertTo-SpecificGravity $FinalGravity    
    }    
    "SG" {
        ValidateParams
        $adjustedFG = ConvertTo-AdjustedFinalGravity -OG (ConvertTo-Brix $OriginalGravity) -FG (ConvertTo-Brix $FinalGravity) 
    }
}        

$brixOG = ConvertTo-Brix $OriginalGravity
$brixFG = ConvertTo-Brix $FinalGravity
$brixAdjustedFG = ConvertTo-Brix $adjustedFG
$abv = Measure-AlcoholByVolume -OriginalGravity $OriginalGravity -AdjustedFinalSpecificGravity $adjustedFG
$attenuation = Measure-Attenuation -OriginalGravity $OriginalGravity -AdjustedFinalSpecificGravity $adjustedFG
$calories = Measure-Calories -OriginalGravity $OriginalGravity -AdjustedFinalSpecificGravity $adjustedFG

Write-Output "Original Gravity: $OriginalGravity (SG) / $brixOG (Brix)"
Write-Output "Final Gravity (refractometer reading): $FinalGravity (SG) / $brixFG (Brix)"
Write-Output "Adjusted Final Gravity: $adjustedFG (SG) / $brixAdjustedFG (Brix)"
Write-Output "ABV: $abv%"
Write-Output "Attenuation: $attenuation%"
Write-Output "Calories (per 12 oz): $calories"
#endregion
