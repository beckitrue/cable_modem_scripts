#!/usr/bin/perl

# This program will get the signal quality table from a
# DOCSIS compliant CMTS via SNMP. This program is designed
# to be used as an HPOV popup selection.

# INPUT: name of CMTS
# OUTPUT: displays the signal quality table
# AUTHOR: Becki True becki@beckitrue.com

use Net::SNMP;

while(@ARGV) {
	$cmts = (shift @ARGV);
}

$community = '';

#get signal quality table
($session, $error) = Net::SNMP->session( Hostname => $cmts, community => $community);

if(!defined($session)) {
	printf("ERROR: %s.\n", $error);
	exit 1;
}

$signalTbl = '1.3.6.1.2.1.10.127.1.1.4';

if(!defined($response = $session->get_table($signalTbl))) {
	printf("ERROR: %s.\n", $session->error());
	$session->close();
	exit 1;
}

$session->close();

$contention = "$signalTbl.1.1.";

foreach $key(sort numerically keys %$response) {
	if($key =~ m/$contention/) {
		($tmp = $key)  =~ s/$contention//;
		push @index, $tmp;
	}	
}

$contentionOID = "$signalTbl.1.1";
$unerroredOID = "$signalTbl.1.2";
$correctableOID = "$signalTbl.1.3";
$uncorrectOID = "$signalTbl.1.4";
$snrOID = "$signalTbl.1.5";
$microOID = "$signalTbl.1.6";
$equalOID = "$signalTbl.1.7";	

foreach $index(@index) {
	$contention = "$contentionOID.$index";
	$contention = $response->{$contention};
	if($contention) { $contention = 'True'; }
	else { $contention = 'False'; }

	$unerrored = "$unerroredOID.$index";
	$unerrored = $response->{$unerrored};

	$correctable = "$correctableOID.$index";
	$correctable = $response->{$correctable};

	$uncorrect = "$uncorrectOID.$index";
	$uncorrect = $response->{$uncorrect};

	$snr = "$snrOID.$index";
	$snr = $response->{$snr};
	$snr = $snr / 10;
	$snr = "$snr  (dB)";

	$micro = "$microOID.$index";
	$micro = $response->{$micro};

	$equal = "$equalOID.$index";
	$equal = $response->{$equal};

	$index = convertIndex($index);

	printf("$index
		Contention Intervals\t\t$contention
		Unerrored Codewords\t\t$unerrored
		Correctable Codewords\t\t$correctable
		Uncorrectable Codewords\t\t$uncorrect
		Signal to Noise\t\t\t$snr
		Equalization Data\t\t$equal\n\n");
}

exit 0;

sub numerically { $a <=> $b }

sub convertIndex {
# Converts ADC ifIndex from decimal value into interface number,
# CPU identifier, Slot identifier, and Chassis identifier.

# ADC ifIndex format:
# Bits 0 - 15 represent the interface number
# Bits 16 - 17 represent the CPU identifier
# Bits 18 - 22 represent the Slot identifier
# Bits 23 - 30 represent the Chassis identifier
# Bit 31 is unused to keep the ifIndex value greater than 0

# INPUT: decimal value of ADC ifIndex example: 11141128
# OUTPUT: interface, CPU, slot, and chassis identifiers

        my $index = $_[0];

	my $bit = 30;                      # highest bit with value
	my $bitVal = 2 ** $bit;            # compute decimal value of bit

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
	my @interface = @bitArray[0..15];
	my @cpu = @bitArray[16..17];
	my @slot = @bitArray[18..22];
	my @chassis = @bitArray[23..30];

	#convert slices to decimal values
	my $interfaceNum = convertSlice( \@interface );
	my $cpuNum = convertSlice( \@cpu );
	my $slotNum = convertSlice( \@slot );
	my $chassisNum = convertSlice( \@chassis );

	#if interface is between 3 and 8, return US port number
	my $port = 'UNDEFINED';
	if( (3 <= $interfaceNum) && ($interfaceNum <= 8)) {
        	$port = $interfaceNum - 2;
	}

	printf("Interface: $interfaceNum CPU: $cpuNum Slot: $slotNum Chassis: $chassisNum Port: $port\n");
	my $name = "$chassisNum/$slotNum/$cpuNum\t\tUpstream $port";
	return $name;
}

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
