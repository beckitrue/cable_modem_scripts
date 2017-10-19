#! /usr/bin/perl -w

# This program will use SNMP to initiate a TFTP transfer
# of each Cisco device's startup-configuration to the
# TFTP server. This program will only work with Cisco 
# devices using IOS. There is a seperate program for 
# Catalyst devices (cat_tftp.pl).

# This program will be run as cron job daily using OpenView's
# snmpset and snmpget. It is assumed that /opt/OV/bin is in
# your path. If you don't have OpenView you can download and
# use the SNMP Perl module from CPAN.

# reference http://www.cisco.com/warp/public/477/SNMP/copy_configs_snmp.shtml

# INPUT: file containing names of Cisco IOS devices - one per line
# OUTPUT: device startup-configuration copied to TFTP server
# AUTHOR: Becki True becki@beckitrue.com

# IMPORTANT: You must provide values for $file, $server, $read, and $write

#-------------------------------------------------------

$file = '';							# data file containing device names
open(FILE, "<$file") or die "Couldn't open $file for reading\n";
while(<FILE>) {
	chomp $_;
	push @host, $_;		
}
close FILE;

$server = '';						# tftp server IP
$inst = int(rand 2147483640) + 1;			# generate random instance number
$ccCopy = ".1.3.6.1.4.1.9.9.96.1.1.1.1";		# base OID
$protocol = "$ccCopy.2.$inst integer 1";		# tftp
$sourceType = "$ccCopy.3.$inst integer 3";		# startup-config
$destType = "$ccCopy.4.$inst integer 1";		# network file
$serverIP = "$ccCopy.5.$inst ipaddress $server";
$copyComplete = "$ccCopy.9.$inst integer 1";		# notify on complete
$copyState = "$ccCopy.10.$inst";			# check copy status
$copy_active = "$ccCopy.14.$inst integer 1";		# copy file
$copy_wait = "$ccCopy.14.$inst integer 5";		# create instance and wait
$copy_destroy = "$ccCopy.14.$inst integer 6";		# destroy instance
	
foreach $host(@host) {
	$read = '';						# SNMP read string
	$write = '';					# SNMP write string
		
	$fileName = "$ccCopy.6.$inst octetstring $host.conf";	# name of file on server
	
	# set file transfer parameters
	`/opt/OV/bin/snmpset -v 1 -c $write $host $copy_wait $protocol $sourceType $destType $serverIP $fileName $copyComplete\n`;

	# copy file
	`/opt/OV/bin/snmpset -v 1 -c $write $host $copy_active\n`;

	# check success of file transfer
	$success = `/opt/OV/bin/snmpget -v 1 -c $read $host $copyState\n`;
	chomp $success;
	$success =~ s/.*INTEGER:\s+//;

	if($success =~ m/successful/) {
		# destroy instance
		`/opt/OV/bin/snmpset -v 1 -c $write $host $copy_destroy\n`;
	}
	else {
		for (1..3) {
			# try up to 3 more times to copy file
			`/opt/OV/bin/snmpset -v 1 -c $write $host $copy_active\n`;
		
			# check success of file transfer
			$success = `/opt/OV/bin/snmpget -v 1 -c $read $host $copyState\n`;
			chomp $success;
			$success =~ s/.*INTEGER:\s+//;
			if($success =~ m/successful/) {
				# file copied, so exit for loop
				last;
			}
		}
		# destroy instance whether copy was successful or not
		`/opt/OV/bin/snmpset -v 1 -c $write $host $copy_destroy\n`;
	}
	print "$host: $success\n";
	sleep 5;

}
