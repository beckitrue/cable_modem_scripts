#!/usr/bin/perl

# This program will telnet into a BSR64000 and get the modem stats and inband
# spectrum information for an upstream.
# (show interfaces cable X/Y upstream <us number> spectrum <start freq> <stop freq>)

# This program is designed to be used as an HPOV popup selection

# INPUT: upstream interface name ie: RDNMTC1:up1/0
# OUTPUT: the results of the show spectrum command
# AUTHOR: Becki True becki@beckitrue.com

use Net::Telnet::Cisco;

while (@ARGV) {
	$interface = (shift @ARGV);
}

my $file = '';
open(FILE, "<$file") or die "Couldn't open $file for reading\n";
while(<FILE>) {
        @input = split;
}
$global = $input[0];
$priv = $input[1];

# parse OV selection name
$cmts = $interface;
$cmts =~ s/:.*//;
$up = $interface;
$up =~ s/.*://;
$card = $up;
$card =~ s/\/.*//;
$card =~ s/up//;
$card = "$card/0";
$port = $up;
$port =~ s/.*\///;

telnet($cmts, $card, $port);

sub telnet {
#INPUT: [1]cmts name [2]slot number [3]port number 
#OUTPUT: results of show interface modem stats and spectrum command

	my $cmts = $_[0];
      my $slot = $_[1];
      my $port = $_[2];
      my $to = 30;
	my $startFreq = '29500000';
	my $stopFreq = '33500000';
        
      my $cs = Net::Telnet::Cisco->new( Host => $cmts, Timeout => $to );

      #errmode -  define action to be performed on error
      $cs->errmode("return"); 

      $cs->login( '' , $global );     
      my $ok = $cs->enable($priv);

      if($ok) {
            # Turn off paging
            $cs->cmd( 'page off' );

		my @modems = $cs->cmd( "show interfaces cable $slot upstream $port stats" );
		printf("Modems on upstream:\n");
		print @modems, "\n\n";

		my @spectrum = $cs->cmd( "show interfaces cable $slot upstream $port spectrum $startFreq $stopFreq");
		print @spectrum;
	}

	$cs->close;
}
