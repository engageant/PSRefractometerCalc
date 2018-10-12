# PSRefractometerCalc
A PowerShell-based tool for adjusting refractometer readings of fermented wort, inspired by Jonathan Braley's [Python tool](https://github.com/DAMNITRENZO/Refractometer_ABV_Python).

### Syntax
Convert-RefractometerReading.ps1 \[-OriginalGravity\] \<Double\> \[-FinalGravity\] \<Double\> [\<CommonParameters\>]

### Example 1
	Convert-RefractometerReading.ps1 -OriginalGravity 1.067 -FinalGravity 1.033
Adjusts a wort sample with an OG of 1.067 and a final gravity of 1.033 (as measured by your refractometer)

### Example 2
	Convert-RefractometerReading.ps1 -OG 16.36 -FG 8.29 -AsBrix
Adjusts a wort sample with an OG of 16.36 and a FG of 8.29, as measured by your refractometer and specified in Brix 

#### Output from both examples
	Original Gravity: 1.067 (SG) / 16.36 (Brix)
	Final Gravity (refractometer reading): 1.033 (SG) / 8.29 (Brix)
	Adjusted Final Gravity: 1.015 (SG) / 3.83 (Brix)
	ABV: 6.83%
	Attenuation: 77.61%
	Calories (per 12 oz): 226.72