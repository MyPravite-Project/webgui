package WebGUI::Macro::a_account;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::International;
use WebGUI::Macro;
use WebGUI::Session;

#-------------------------------------------------------------------
sub process {
	my ($output, $temp, @param);
	$output = $_[0];
        while ($output =~ /\^a(.*?)\;/) {
                @param = WebGUI::Macro::getParams($1);
		$temp = '<a class="myAccountLink" href="'.$session{page}{url}.'?op=displayAccount">';
		if ($param[0] ne "") {
			$temp .= $param[0];
		} else {
			$temp .= WebGUI::International::get(46);
		}
		$temp .= '</a>';
                $output =~ s/\^a(.*?)\;/$temp/;
        }
	#---everything below this line will go away in a later rev.
	if ($output =~ /\^a(.*)\^\/a/) {
        	$temp = '<a class="myAccountLink" href="'.$session{page}{url}.'?op=displayAccount">'.$1.'</a>';
                $output =~ s/\^a(.*)\^\/a/$temp/g;
	} elsif ($output =~ /\^a/) {
        	$temp = '<a class="myAccountLink" href="'.$session{page}{url}.'?op=displayAccount">'.WebGUI::International::get(46).'</a>';
        	$output =~ s/\^a/$temp/g;
	}
	return $output;
}

1;

