package WebGUI::Search::Index;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2006 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use warnings;

=head1 NAME

Package WebGUI::Search::Index

=head1 DESCRIPTION

A package for working with the WebGUI Search Engine.

=head1 SYNOPSIS

 use WebGUI::Search::Index;

=head1 METHODS

These methods are available from this package:

=cut


#-------------------------------------------------------------------

=head2 addFile ( path ) 

Use an external filter defined in the config file as searchIndexerPlugins.

=head3 path

The path to the filename to index, including the filename.

=cut

sub addFile {
	my $self = shift;
	my $path = shift;
	$path =~ m/\.(\w)$/;
	my $type = lc($1);
	my $filters = $self->session->config->get("searchIndexerPlugins");
	my $filter = $filters->{$type};
	my $content = `$filter $path`;
	$self->addKeywords($content) if (!$content =~ m/^\s*$/);
}


#-------------------------------------------------------------------

=head2 addKeywords ( text )

Add more text to the keywords index for this asset.

=head3 text

A string of text. You may optionally also put HTML here, and it will be automatically filtered.

=cut

sub addKeywords {
	my $self = shift;
	my $text = shift;
	$text = WebGUI::HTML::filter($text, "all");
	my $add = $self->session->db->prepare("update assetIndex set keywords=concat(keywords,' ',?) where assetId = ?");
	$add->execute([$text, $self->getId]);
}


#-------------------------------------------------------------------

=head2 asset ( )

Returns a reference to the asset object we're indexing.

=cut

sub asset {
	my $self = shift;
	return $self->{_asset};
}


#-------------------------------------------------------------------

=head2 create ( asset )

Constructor that also creates the initial index of an asset.

=cut

sub create {
	my $class = shift;
	my $asset = shift;
	my $self = $class->new($asset);
	$self->delete;
	my $url = $asset->get("url");
	$url =~ s/\/|\-|\_/ /g;
	my $description = WebGUI::HTML::filter($asset->get('description'), "all");
	my $keywords = join(" ",$asset->get("title"), $asset->get("menuTitle"), $asset->get("synopsis"), $url, $description);
	my $add = $self->session->db->prepare("insert into assetIndex (assetId, title, startDate, endDate, creationDate, revisionDate, 
		ownerUserId, groupIdView, groupIdEdit, lineage, className, synopsis, keywords) values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )");
	$add->execute([$asset->getId, $asset->get("title"), $asset->get("startDate"), $asset->get("endDate"), $asset->get("creationDate"),
		$asset->get("revisionDate"), $asset->get("ownerUserId"), $asset->get("groupIdView"), $asset->get("groupIdEdit"), 
		$asset->get("lineage"), $asset->get("className"), $asset->get("synopsis"), $keywords]);
	return $self;
}


#-------------------------------------------------------------------

=head2 delete ( )

Deletes this indexed asset.

=cut

sub delete {
	my $self = shift;
	my $delete = $self->session->db->prepare("delete from assetIndex where assetId=?");
	$delete->execute([$self->getId]);
}

#-------------------------------------------------------------------

=head2 DESTROY ( ) 

Deconstructor.

=cut

sub DESTROY {
	my $self = shift;
	undef $self;
}

#-------------------------------------------------------------------

=head2 getId ( )

Returns the ID used to create this object.

=cut

sub getId {
	my $self = shift;
	return $self->{_id};
}

#-------------------------------------------------------------------

=head2 setIsPublic ( boolean )

Sets the status of whether this asset will appear in public searches.

=cut

sub isPublic {
	my $self = shift;
	my $boolean = shift;
	my $set = $self->session->db->prepare("update assetIndex set isPublic=? where assetId=?");
	$set->execute($boolean, $self->getId);
}

#-------------------------------------------------------------------

=head2 new ( asset )

Constructor.

=head3 asset

A reference to an asset object.

=cut

sub new {
	my $class = shift;
	my $asset = shift;
	my $self = {_asset=>$asset, _session=>$asset->session, _id=>$asset->getId};
	return $self;
}


#-------------------------------------------------------------------

=head2 session ( )

Returns a reference to the current session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}

#-------------------------------------------------------------------

=head2 updateSynopsis ( text )

Overrides the asset's default synopsis with a new chunk of text.

NOTE: This doesn't change the asset itself, only the synopsis in the search index.

=head3 text

The text to put in place of the current synopsis.

=cut

sub updateSynopsis {
	my $self = shift;
	my $text = shift;
	my $add = $self->session->db->prepare("update assetIndex set synopsis=? where assetId=?");
	$add->execute([$text,$self->getId]);
}



1;

