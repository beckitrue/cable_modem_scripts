#!/usr/bin/perl

# Converts ADC ifIndex from decimal value into interface number,
# CPU identifier, Slot identifier, Chassis identifier, and upstream.

# ADC ifIndex format:
# Bits 0 - 15 represent the interface number
# Bits 16 - 17 represent the CPU identifier
# Bits 18 - 22 represent the Slot identifier
# Bits 23 - 30 represent the Chassis identifier
# Bit 31 is unused to keep the ifIndex value greater than 0

# INPUT: decimal value of ADC ifIndex example: 11141128
# OUTPUT: interface, CPU, slot, and chassis identifiers
# AUTHOR: Becki True becki@beckitrue.com

while(@ARGV) {
	$index = (shift @ARGV);
}
$bit = 30;			# highest bit with value
$bitVal = 2 ** $bit;		# compute decimal value of bit

# convert from decimal to 31 bit binary number and store each bit in
# an element of an array with the array index equivilent to the log 
# base 2 of that bit's decimal value
while($bit >= 0) {
	if($index >= $bitVal) {
		$bitArray[$bit] = 1;
		$index = $index - $bitVal;
	}
	else { $bitArray[$bit] = 0; }
	$bit--;
	$bitVal = $bitVal / 2;
}

# slice the bitArray into arrays representing interface, cpu, slot, chassis
@interface = @bitArray[0..15];
@cpu = @bitArray[16..17];
@slot = @bitArray[18..22];
@chassis = @bitArray[23..30];

#convert slices to decimal values
$interfaceNum = convertSlice( \@interface );
$cpuNum = convertSlice( \@cpu );
$slotNum = convertSlice( \@slot );
$chassisNum = convertSlice( \@chassis );

#if interface is between 3 and 8, return US port number
$port = 'UNDEFINED';
if( (3 <= $interfaceNum) && ($interfaceNum <= 8)) {
        $us = $interfaceNum - 2;
}

printf("Interface: $interfaceNum CPU: $cpuNum Slot: $slotNum Chassis: $chassisNum Upstream: $us\n");

sub convertSlice {
# converts array slice to decimal value
# INPUT: an array with each element containing a binary number
# OUTPUT: a decimal number

	my ($aref) = @_;
	my $i = 0;
	my $value = 0;

	foreach (@$aref) {
		if($_) {
			$value += (2 ** $i);
		}
		$i++;
	}
	
	return $value;
}
