package WebGUI::Style;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2004 Plain Black LLC.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut


use strict;
use Tie::CPHash;
use WebGUI::International;
use WebGUI::Session;
use WebGUI::Template;
use WebGUI::URL;

=head1 NAME

Package WebGUI::Style

=head1 DESCRIPTION

This package contains utility methods for WebGUI's style system.

=head1 SYNOPSIS

 use WebGUI::Style;
 $template = WebGUI::Style::getTemplate();
 $html = WebGUI::Style::process($content);

 setLink($url,\%params);
 setMeta(\%params);
 setRawHeadTags($html);
 setScript($url, \%params);

=head1 SUBROUTINES 

These subroutines are available from this package:

=cut


#-------------------------------------------------------------------

=head2 getTemplate ( [ templateId ] )

Retrieves the template for this style.

=over

=item templateId

The unique identifier for the template to retrieve. Defaults to the style template tied to the current page.

=back

=cut

sub getTemplate {
	my $templateId = shift || $session{page}{styleId};
	return WebGUI::Template::get($templateId,"style");
}


#-------------------------------------------------------------------

=head2 process ( content [ , templateId ] )

Returns a parsed style with content based upon the current WebGUI session information.

=over

=item content

The content to be parsed into the style. Usually generated by WebGUI::Page::generate().

=item templateId

The unique identifier for the template to retrieve. Defaults to the style template tied to the current page.

=back

=cut

sub process {
	my %var;
	$var{'body.content'} = shift;
	my $templateId = shift || $session{page}{styleId};
	if ($session{page}{makePrintable}) {
		$templateId = $session{page}{printableStyleId};
	} elsif ($session{page}{useAdminStyle} ne "" && $session{setting}{useAdminStyle}) {
		$templateId = $session{setting}{adminStyleId};
	} elsif ($session{scratch}{personalStyleId} ne "") {
		$templateId = $session{scratch}{personalStyleId};
	} elsif ($session{page}{useEmptyStyle}) {
		$templateId = 6;
	}
        my $type = lc($session{setting}{siteicon});
        $type =~ s/.*\.(.*?)$/$1/;
	$var{'head.tags'} = '
		<meta name="generator" content="WebGUI '.$WebGUI::VERSION.'" />
		<meta http-equiv="Content-Type" content="text/html; charset='.WebGUI::International::getLanguage($session{page}{languageId},"charset").'" />
		<link rel="icon" href="'.$session{setting}{siteicon}.'" type="image/'.$type.'" />
		<link rel="SHORTCUT ICON" href="'.$session{setting}{favicon}.'" />
		'.$session{page}{head}{raw}.'
                <script>
                        function getWebguiProperty (propName) {
                                var props = new Array();
                                props["extrasURL"] = "'.$session{config}{extrasURL}.'";
                                props["pageURL"] = "'.WebGUI::URL::page().'";
                                return props[propName];
                        }
                </script>
                ';
        # generate additional link tags
	foreach my $url (keys %{$session{page}{head}{link}}) {
		$var{'head.tags'} .= '<link href="'.$url.'"';
		foreach my $name (keys %{$session{page}{head}{link}{$url}}) {
			$var{'head.tags'} .= ' '.$name.'="'.$session{page}{head}{link}{$url}{$name}.'"';
		}
		$var{'head.tags'} .= ' />'."\n";
	}
	# generate additional javascript tags
	foreach my $tag (@{$session{page}{head}{javascript}}) {
		$var{'head.tags'} .= '<script';
		foreach my $name (keys %{$tag}) {
			$var{'head.tags'} .= ' '.$name.'="'.$tag->{$name}.'"';
		}
		$var{'head.tags'} .= '></script>'."\n";
	}
	# generate additional meta tags
	foreach my $tag (@{$session{page}{head}{meta}}) {
		$var{'head.tags'} .= '<meta';
		foreach my $name (keys %{$tag}) {
			$var{'head.tags'} .= ' '.$name.'="'.$tag->{$name}.'"';
		}
		$var{'head.tags'} .= ' />'."\n";
	}
	if ($session{var}{adminOn}) {
                # This "triple incantation" panders to the delicate tastes of various browsers for reliable cache suppression.
		$var{'head.tags'} .= '
                	<meta http-equiv="Pragma" content="no-cache" />
                	<meta http-equiv="Cache-Control" content="no-cache, must-revalidate, max_age=0" />
                	<meta http-equiv="Expires" content="0" />
			';
        }
	return WebGUI::Template::process($templateId,"style",\%var);
}	


#-------------------------------------------------------------------

=head2 setLink ( url, params )

Sets a <link> tag into the <head> of this rendered page for this page view. This is typically used for dynamically adding references to CSS and RSS documents.

=over

=item url

The URL to the document you are linking.

=item params

A hash reference containing the other parameters to be included in the link tag, such as "rel" and "type".

=back

=cut

sub setLink {
	my $url = shift;
	my $params = shift;
	$session{page}{head}{link}{$url} = $params;
}



#-------------------------------------------------------------------

=head2 setMeta ( params )

Sets a <meta> tag into the <head> of this rendered page for this page view. 

=over

=item params

A hash reference containing the parameters of the meta tag.

=back

=cut

sub setMeta {
	my $params = shift;
	push(@{$session{page}{head}{meta}},$params);
}



#-------------------------------------------------------------------

=head2 setRawHeadTags ( tags )

Sets data to be output into the <head> of the current rendered page for this page view.

=over

=item tags

A raw string containing tags. This is just a raw string so you must actually pass in the full tag to use this call.

=back

=cut

sub setRawHeadTags {
	my $tags = shift;
	$session{page}{head}{raw} .= $tags;
}


#-------------------------------------------------------------------

=head2 setScript ( url, params )

Sets a <script> tag into the <head> of this rendered page for this page view. This is typically used for dynamically adding references to Javascript or ECMA script.

=over

=item url

The URL to your script.

=item params

A hash reference containing the additional parameters to include in the script tag, such as "type" and "language".

=back

=cut

sub setScript {
	my $url = shift;
	my $params = shift;
	$params->{src} = $url;
	my $found = 0;
	foreach my $script (@{$session{page}{head}{javascript}}) {
		$found = 1 if ($script->{src} eq $url);
	}
	push(@{$session{page}{head}{javascript}},$params) unless ($found);	
}


1;
