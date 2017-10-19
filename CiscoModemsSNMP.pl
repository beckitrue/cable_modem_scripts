#!/usr/bin/perl -w

# This program uses SNMP to get the number of total, active and registered
# modems on each upstream port.  Since these are Cisco MIBs, this script
# is limited to Cisco CMTS devices.

# INPUT: CMTS name
# OUTPUT: Modem count table
# AUTHOR: Becki True becki@beckitrue.com

use Net::SNMP;
use strict;

my $host = $ARGV[0];
my $comm = '';        # put your read community string here

# establish SNMP session with host
my ($session, $error) = Net::SNMP->session( Hostname => $host, community => $comm, version => 'snmpv2');
if(!defined($session)) {
        printf("Connection Error: %s.\n", $error);
        exit 1;
}

my $total = '1.3.6.1.4.1.9.9.116.1.4.1.1.3';
my $active = '1.3.6.1.4.1.9.9.116.1.4.1.1.4';
my $reg = '1.3.6.1.4.1.9.9.116.1.4.1.1.5';
my $ifDesc = '1.3.6.1.2.1.2.2.1.2';
my %desc;
my $desc;
my $index;
my @index;
my $totalmodems;
my $activemodems;
my $registered;

# get ifDesc of upstream ports
if (!defined($desc = $session->get_table($ifDesc))) {
        printf("Get ifDesc error: %s.\n", $session->error());
        $session->close();
        exit 1;
}

# sort by upstream name and store indexes in an array
foreach my $key(sort hashValueSort(keys(%$desc))) {
	if($desc->{$key} =~ m/[uU]pstream/) {
		$index = $key;
		$index =~ s/$ifDesc.//;
		push @index, $index;
	}
}

# get total modems on each upstream port
if (!defined ($totalmodems = $session->get_table($total))) {
        printf("Get total error: %s.\n", $session->error());
        $session->close();
        exit 1;
}

# get active modems on each upstream port
if (!defined($activemodems = $session->get_table($active))) {
        printf("Get active error: %s.\n", $session->error());
        $session->close();
        exit 1;
}

# get registered modems on each upstream port
if (!defined($registered = $session->get_table($reg))) {
        printf("Get registered error: %s.\n", $session->error());
        $session->close();
        exit 1;
}

# print results
print "CMTS: $host\n\n";
print "Upstream port\t\tTotal\tActive\tRegistered\n";
foreach $index (@index) {
	my $descOID = "$ifDesc.$index";
	my $totalOID = "$total.$index";
	my $activeOID = "$active.$index";
	my $regOID = "$reg.$index";
	print "$desc->{$descOID}\t$totalmodems->{$totalOID}\t$activemodems->{$activeOID}\t$registered->{$regOID}\n";
}

$session->close();

sub hashValueSort {
	$desc->{$a} cmp $desc->{$b};
}

exit 0;
