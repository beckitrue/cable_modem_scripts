#!/usr/bin/perl -w

# This program will use SNMP to initiate a TFTP transfer
# of each Cisco device's startup-configuration to the
# TFTP server. This program will only work with Cisco 
# devices using Catalyst OS. There is a seperate program for 
# IOS devices (ios_tftp.pl).

# This program will be run as cron job daily using OpenView's
# snmpset and snmpget. It is assumed that /opt/OV/bin is in
# your path. If you don't have OpenView you can download and
# use the SNMP Perl module from CPAN.

# reference http://www.cisco.com/warp/public/477/SNMP/move_files_images_snmp.html

# INPUT: file containing names of Cisco Catalyst OS devices - one per line
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
$tftpGrp = '1.3.6.1.4.1.9.5.1.5';			# base OID
$tftpHost = "$tftpGrp.1.0 octetstring $server";
$tftpModule = "$tftpGrp.3.0 integer 1";			# module number to copy config from
$tftpAction = "$tftpGrp.4.0 integer 3";			# send config to tftp server
$tftpResult = "$tftpGrp.5.0";				# result of the transfer
	
foreach $host(@host) {
		$read = '';					# SNMP read string
		$write = '';				# SNMP write string
	
	$fileName = "$tftpGrp.2.0 octetstring $host.conf";	# name of file on server
	
	# copy file
	`/opt/OV/bin/snmpset -v 1 -c $write $host $tftpHost $fileName $tftpModule $tftpAction\n`;
		
	# wait a few seconds for the transfer - these take a little while
	sleep 15;
	
	# check success of file transfer
	$success = `/opt/OV/bin/snmpget -v 1 -c $read $host $tftpResult\n`;
	chomp $success;
	$success =~ s/.*INTEGER:\s+//;

	if($success !~ m/successful/) {
		for (1..3) {
			# try up to 3 more times to copy file
			`/opt/OV/bin/snmpset -v 1 -c $write $host $tftpHost $fileName $tftpModule $tftpAction\n`;
			sleep 15;
		
			# check success of file transfer
			$success = `/opt/OV/bin/snmpget -v 1 -c $read $host $tftpResult\n`;
			chomp $success;
			$success =~ s/.*INTEGER:\s+//;
			if($success =~ m/successful/) {
				# file copied, so exit for loop
				last;
			}
		}		
	}
	print "$host: $success\n";
}
