#-------------------------------------------------------------------
# WebGUI is Copyright 2001 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

# Yeah if you're looking at this code you're probably thinking to
# yourself, "What a #$@*ing mess!" That's what we think too. But
# if you know Perl well enough to know that this sux, then you
# probably don't need to use this script cuz you know how to
# install Perl modules and such.


BEGIN {
        unshift (@INC, "./lib");
}

use strict;
use CPAN;

if ($ARGV[0] eq "--help" || $ARGV[0] eq "/?" || $ARGV[0] eq "/help" || $ARGV[0] eq "-?" || $ARGV[0] eq "-help" || $ARGV[0] eq "help") {
	print "Usage: ".$0." [option]\n";
	print "\t--help\t\t\tPrint this menu.\n";
	print "\t--install-modules\tInstall any missing Perl modules.\n";
	print "\n";
	exit;
}

print "\nWebGUI is checking your system environment...\n\n";

my $os;
if ($^O =~ /Win/i) {
	$os = "Microsoftish";
} else {
	$os = "Linuxish";
}

print "Operating System:\t".$os."\n";

if ($ARGV[0] eq "--install-modules" && $< != 0 && $os eq "Linuxish") {
	print "You cannot install Perl modules unless you are the root user.\n";
	exit;
} elsif ($ARGV[0] eq "--install-modules" && $os eq "Windowsish") {
	print $0." cannot currently install Perl modules under ".$os." operating systems.\n";
	exit;
}

###################################
# Checking Perl
###################################

print "Perl Interpreter:\t";
if ($] >= 5.006) {
	print "OK\n";
} else {
	print "Please upgrade to 5.6 or later!\n";
	if ($ARGV[0] ne "") {
		print "Test environment exiting, cannot continue without Perl 5.6.\n";
		exit;
	}
}

print "LWP module:\t\t";
if (eval { require LWP }) {
        print "OK\n";
} else {
	if ($ARGV[0] eq "--install-modules") {
        	print "Installing...\n";
		CPAN::Shell->install("LWP");
	} else {
        	print "Please install.\n";
	}
}

print "HTTP::Request module:\t";
if (eval { require HTTP::Request }) {
        print "OK\n";
} else {
        print "Please install LWP.\n";
}

print "HTTP::Headers module:\t";
if (eval { require HTTP::Headers }) {
        print "OK\n";
} else {
        print "Please install LWP.\n";
}

print "Digest::MD5 module:\t";
if (eval { require Digest::MD5 }) {
        print "OK\n";
} else {
        if ($ARGV[0] eq "--install-modules") {
        	print "Installing...\n";
                CPAN::Shell->install("Digest::MD5");
        } else {
                print "Please install.\n";
        }
}

print "DBI module:\t\t";
if (eval { require DBI }) {
	print "OK\n";
} else {
        if ($ARGV[0] eq "--install-modules") {
        	print "Installing...\n";
                CPAN::Shell->install("DBI");
        } else {
                print "Please install.\n";
        }
}

print "Database drivers:\t";
print join(", ",DBI->available_drivers);
print "\n";

print "Tie::IxHash module:\t";
if (eval { require Tie::IxHash }) {
        print "OK\n";
} else {
        if ($ARGV[0] eq "--install-modules") {
        	print "Installing...\n";
                CPAN::Shell->install("Tie::IxHash");
        } else {
                print "Please install.\n";
        }
}

print "Tie::CPHash module:\t";
if (eval { require Tie::CPHash }) {
        print "OK\n";
} else {
        if ($ARGV[0] eq "--install-modules") {
        	print "Installing...\n";
                CPAN::Shell->install("Tie::CPHash");
        } else {
                print "Please install.\n";
        }
}

print "Net::SMTP module:\t";
if (eval { require Net::SMTP }) {
        print "OK\n";
} else {
        if ($ARGV[0] eq "--install-modules") {
                print "Installing...\n";
                CPAN::Shell->install("Net::SMTP");
        } else {
                print "Please install.\n";
        }
}

print "XML::RSS module:\t";
if (eval { require XML::RSS }) {
        print "OK\n";
} else {
        if ($ARGV[0] eq "--install-modules") {
                print "Installing...\n";
                CPAN::Shell->install("XML::RSS");
        } else {
                print "Please install.\n";
        }
}

print "Net::LDAP module:\t";
if (eval { require Net::LDAP }) {
        print "OK\n";
} else {
        if ($ARGV[0] eq "--install-modules") {
                print "Installing...\n";
                CPAN::Shell->install("Net::LDAP");
        } else {
                print "Please install.\n";
        }
}

# this is here to insure they installed correctly.
print "WebGUI modules:\t\t";
#if (eval { require WebGUI } && eval { require WebGUI::SQL }) {
if (eval { require WebGUI::SQL }) {
        print "OK\n";
} else {
        print "Please install.\n";
}

print "Data::Config module:\t";
if (eval { require Data::Config }) {
        print "OK\n";
} else {
        print "Please install.\n";
}

###################################
# Checking Config File
###################################

print "Config file:\t\t";
my ($config);
$config = new Data::Config './etc/WebGUI.conf';
unless (defined $config) {
	print "Couldn't open it.\n";
} elsif ($config->param('dsn') =~ /\s$/) {
        print "DSN cannot end with a space.\n";
} elsif ($config->param('dsn') !~ /\DBI\:\w+\:\w+/) {
	print "DSN is improperly formatted.\n";
} elsif ($config->param('dbuser') =~ /\s$/) {
	print "dbuser cannot end with a space.\n";
} elsif ($config->param('dbuser') =~ /\s$/) {
	print "dbpass cannot end with a space.\n";
} else {
	print "OK\n";
}

###################################
# Checking database
###################################

print "Database connection:\t";
my ($dbh, $test);
unless (eval { $dbh = DBI->connect($config->param('dsn'), $config->param('dbuser'), $config->param('dbpass')) }) {
	print "Can't connect with info provided.\n";
} else {
	print "OK\n";
	print "Database tables:\t";
	($test) = WebGUI::SQL->quickArray("select count(*) from page",$dbh);
	if ($test < 1) {
		print "Looks like you need to create some tables.\n";
	} else {
		print "OK\n";
	}
	$dbh->disconnect();
}

###################################
# Checking Version
###################################

print "Latest version:\t\t";
my ($header, $userAgent, $request, $response, $version, $referer);
$userAgent = new LWP::UserAgent;
$userAgent->agent("WebGUI-Check/2.0");
$header = new HTTP::Headers;
$referer = "http://webgui.cli.getversion/".`hostname`;
chomp $referer;
$header->referer($referer);
$request = new HTTP::Request (GET => "http://www.plainblack.com/downloads/latest-version.txt", $header);
$response = $userAgent->request($request);
$version = $response->content;
chomp $version;
if ($response->is_error) {
	print "Couldn't connect to Plain Black Software. Check your connection and try again.\n";
} elsif ($version eq $WebGUI::VERSION) {
	print "OK\n";
} else {
	print "You are using ".$WebGUI::VERSION." and ".$version." is available.\n";
}


print "\nTesting complete!\n";



