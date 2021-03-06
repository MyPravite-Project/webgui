package WebGUI::Role::Asset::RssFeed;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2012 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use Moose::Role;
use WebGUI::Definition::Asset;
use Tie::IxHash;

define tableName      => 'assetAspectRssFeed';
property itemsPerFeed => (
    noFormPost => 0,
    fieldType  => "integer",
    default    => 25,
    tab        => "rss",
    label      => [ 'itemsPerFeed', 'Role_RssFeed' ],
    hoverHelp  => [ 'itemsPerFeed hoverHelp', 'Role_RssFeed' ]
);
property feedCopyright => (
    noFormPost => 0,
    fieldType  => "text",
    default    => "",
    tab        => "rss",
    label      => [ 'feedCopyright', 'Role_RssFeed' ],
    hoverHelp  => [ 'feedCopyright hoverHelp', 'Role_RssFeed' ]
);
property feedTitle => (
    noFormPost => 0,
    fieldType  => "text",
    default    => "",
    tab        => "rss",
    label      => [ 'feedTitle', 'Role_RssFeed' ],
    hoverHelp  => [ 'feedTitle hoverHelp', 'Role_RssFeed' ]
);
property feedDescription => (
    noFormPost => 0,
    fieldType  => "textarea",
    default    => "",
    tab        => "rss",
    label      => [ 'feedDescription', 'Role_RssFeed' ],
    hoverHelp  => [ 'feedDescription hoverHelp', 'Role_RssFeed' ]
);
property feedImage => (
    noFormPost => 0,
    fieldType  => "image",
    tab        => "rss",
    label      => [ 'feedImage', 'Role_RssFeed' ],
    hoverHelp  => [ 'feedImage hoverHelp', 'Role_RssFeed' ]
);
property feedImageLink => (
    noFormPost => 0,
    fieldType  => "url",
    default    => "",
    tab        => "rss",
    label      => [ 'feedImageLink', 'Role_RssFeed' ],
    hoverHelp  => [ 'feedImageLink hoverHelp', 'Role_RssFeed' ]
);
property feedImageDescription => (
    noFormPost => 0,
    fieldType  => "text",
    default    => "",
    tab        => "rss",
    label      => [ 'feedImageDescription', 'Role_RssFeed' ],
    hoverHelp  => [ 'feedImageDescription hoverHelp', 'Role_RssFeed' ]
);
property feedHeaderLinks => (
    fieldType => "checkList",
    value     => "rss\natom",
    default   => undef,
    tab       => "rss",
    options   => \&_feedHeaderLinks_options,
    label     => [ 'feedHeaderLinks', 'Role_RssFeed' ],
    hoverHelp => [ 'feedHeaderLinks hoverHelp', 'Role_RssFeed' ]
);
sub _feedHeaderLinks_options {
    my $session = shift->session;
	my $i18n = WebGUI::International->new($session,'Role_RssFeed');
    my %headerLinksOptions;
    tie %headerLinksOptions, 'Tie::IxHash';
    %headerLinksOptions = (
        rss  => $i18n->get('rssLinkOption'),
        atom => $i18n->get('atomLinkOption'),
        rdf  => $i18n->get('rdfLinkOption'),
    );
    return \%headerLinksOptions;
}

requires 'getRssFeedItems';

use WebGUI::Exception;
use WebGUI::Storage;
use XML::FeedPP;
use Path::Class::File;

=head1 NAME

Package WebGUI::Role::Asset::RssFeed

=head1 DESCRIPTION

This is an aspect which exposes an asset's items as an RSS or Atom feed.

=head1 SYNOPSIS

 with 'WebGUI::Role::Asset::RssFeed';

=head1 METHODS

These methods are available from this class:

=cut

#----------------------------------------------------------------------------

=head2 addEditSaveTabs ( form )

Add the tab for the RSS feed configuration data.

=cut

override addEditSaveTabs => sub {
    my ( $self, $form ) = @_;
    $form = super();
    my $i18n = WebGUI::International->new($self->session, 'Role_RssFeed');
    $form->addTab( name => "rss", label => $i18n->get("RSS tab") );
    return $form;
};

 #-------------------------------------------------------------------

=head2 dispatch ( )

Extent the base method in Asset.pm to handle RSS feeds.

=cut

around dispatch => sub {
    my ( $orig, $self, $fragment ) = @_;
    if ($fragment eq '.rss') {
        return $self->www_viewRss;
    }
    elsif ($fragment eq '.atom') {
        return $self->www_viewAtom;
    }
    elsif ($fragment eq '.rdf') {
        return $self->www_viewRdf;
    }
    return $self->$orig($fragment);
};

#-------------------------------------------------------------------

=head2 _httpBasicLogin ( )

Set header values and content to show the HTTP Basic Auth login box.

=cut

sub _httpBasicLogin {
    my ( $self ) = @_;
    $self->session->request->headers_out->set(
        'WWW-Authenticate' => 'Basic realm="'.$self->session->setting->get('companyName').'"'
    );
    $self->session->response->status(401);
    $self->session->response->sendHeader;
    return '';
}

#-------------------------------------------------------------------

=head2 exportAssetCollateral ()

Extended from WebGUI::Asset and exports the www_viewRss() and
www_viewAtom() methods with filenames generated by
getStaticAtomFeedUrl() and getStaticRssFeedUrl().

This method will be called with the following parameters:

=head3 basePath

A L<Path::Class> object representing the base filesystem path for this
particular asset.

=head3 params

A hashref with the quiet, userId, depth, and indexFileName parameters from
L<WebGUI::Asset/exportAsHtml>.

=head3 session

The session doing the full export.  Can be used to report status messages.

=cut

around exportAssetCollateral => sub {
    # Lots of copy/paste here from AssetExportHtml.pm, since none of the methods there were
    #   directly useful without ginormous refactoring.
    my $orig = shift;
    my $self = shift;
    my $basepath = shift;
    my $args = shift;
    my $reportSession = shift;

    my $reporti18n = WebGUI::International->new($self->session, 'Asset');

    my $basename = $basepath->basename;
    my $filedir;
    my $filenameBase;

    # We want our .rss and .atom files to "appear" at the same level as the asset.
    if ($basename eq 'index.html') {
        # Get the 2nd ancestor, since the asset url had no dot in it (and it therefore
        #   had its own directory created for it).
        $filedir = $basepath->parent->parent->absolute->stringify;
        # Get the parent dir's *path* (essentially the name of the dir) relative to
        #   its own parent dir.
        $filenameBase = $basepath->parent->relative( $basepath->parent->parent )->stringify;
    }
    else {
        # Get the 1st ancestor, since the asset is a file recognized by apache, so
        #   we want our files in the same dir.
        $filedir = $basepath->parent->absolute->stringify;
        # just use the basename.
        $filenameBase = $basename;
    }

    if ( $reportSession && !$args->{quiet} ) {
        $reportSession->output->print('<br />');
    }

    foreach my $ext (qw( rss atom rdf )) {
        my $dest = Path::Class::File->new($filedir, $filenameBase . '.' . $ext);

        # tell the user which asset we're exporting.
        if ( $reportSession && !$args->{quiet} ) {
            my $message = sprintf $reporti18n->get('exporting page'), $dest->absolute->stringify;
            $reportSession->output->print(
                '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' . $message . '<br />');
        }
        my $exportSession = $self->session->duplicate;

        # open another session as the user doing the exporting...
        my $selfdupe = WebGUI::Asset->newById( $exportSession, $self->assetId, $self->revisionDate );

        # next, get the contents, open the file, and write the contents to the file.
        my $fh = eval { $dest->open('>:utf8') };
        if($@) {
            $exportSession->close;
            WebGUI::Error->throw(error => "can't open " . $dest->absolute->stringify . " for writing: $!");
        }
        $exportSession->asset($selfdupe);
        $exportSession->output->setHandle($fh);
        my $contents;
        if ($ext eq 'rss') {
            $contents = $selfdupe->www_viewRss;
        }
        else {
            $contents = $selfdupe->www_viewAtom;
        } # add more for more extensions.

        # chunked content is already printed, no need to print it again
        unless($contents eq 'chunked') {
            $exportSession->output->print($contents);
        }

        $exportSession->close;

        # tell the user we did this asset collateral correctly
        if ( $reportSession && !$args->{quiet} ) {
            $reportSession->output->print($reporti18n->get('done'));
        }
    }
    return $self->$orig($basepath, $args, $reportSession);
};

#-------------------------------------------------------------------

=head2 getRssFeedItems ()

This method needs to be implemented by any class that is using it.  To ensure
this, it will throw an exception.

It returns an array reference of hash references.  The list below shows
which ones are required, along with some common keys which are optional.
Other keys may be added, as well.

=head3 Hash reference keys

=head4 title

=head4 description

=head4 link

This is a url to the item.

=head4 date

An epoch date, an RFC 1123 date, or a date in ISO format (referred to as MySQL format
inside WebGUI)

=head4 author

This is optional.

=head4 guid

This is optional.  A unique descriptor for this item.

=cut

#-------------------------------------------------------------------

=head2 _getFeedUrl ($extension)

Generic method for returning the URL for a type of feed.  If the special scratch variable
isExporting is true, the static url (url based vs asset function based) will be returned
instead.

=head3 $extension

The kind of feed that is requested.  Valid extensions are "rss", "atom" or "rdf".

=cut

sub _getFeedUrl {
    my $self = shift;
    my $extension = shift;
    if ( $self->session->scratch->get('isExporting') ) {
        return $self->_getStaticFeedUrl($extension);
    }
    return $self->getUrl("func=view\u$extension");
}

#-------------------------------------------------------------------

=head2 _getStaticFeedUrl ($extension)

Generic method for returning the static URL for a type of feed.  The returned URL will be complete,
and absolute, containing the gateway URL for this site.

=head3 $extension

The kind of feed that is requested.  Valid extensions are "rss", "atom" or "rdf".

=cut

sub _getStaticFeedUrl {
    my $self = shift;
    my $extension = shift;
    my $url = $self->url . '.' . $extension;
    $url = $self->session->url->gateway($url);
    if ($self->encryptPage) {
        $url = $self->session->url->getSiteURL . $url;
        $url =~ s/^http:/https:/;
    }
    return $url;
}

#-------------------------------------------------------------------

=head2 getAtomFeedUrl ()

Returns the URL for this asset's feed in Atom format.  If the special scratch variable
isExporting is true, the static url (url based vs asset function based) will be returned
instead.


=cut

sub getAtomFeedUrl {
    my $self = shift;
    return $self->_getFeedUrl('atom');
}

#-------------------------------------------------------------------

=head2 getRdfFeedUrl ()

Returns the URL for this asset's feed in RDF format.  If the special scratch variable
isExporting is true, the static url (url based vs asset function based) will be returned
instead.


=cut

sub getRdfFeedUrl {
    my $self = shift;
    return $self->_getFeedUrl('rdf');
}

#-------------------------------------------------------------------

=head2 getRssFeedUrl ()

Returns the URL for this asset's feed in RSS 2.0 format.  If the special scratch variable
isExporting is true, the static url (url based vs asset function based) will be returned
instead.


=cut

sub getRssFeedUrl {
    my $self = shift;
    return $self->_getFeedUrl('rss');
}

#-------------------------------------------------------------------

=head2 getStaticAtomFeedUrl ()

Returns the URL to use when exporting for this asset's feed in Atom format.

=cut

sub getStaticAtomFeedUrl {
    my $self = shift;
    return $self->_getStaticFeedUrl('atom');
}

#-------------------------------------------------------------------

=head2 getStaticRdfFeedUrl ()

Returns the URL to use when exporting for this asset's feed in RDF format.

=cut

sub getStaticRdfFeedUrl {
    my $self = shift;
    return $self->_getStaticFeedUrl('rdf');
}

#-------------------------------------------------------------------

=head2 getStaticRssFeedUrl ()

Returns the URL to use when exporting for this asset's feed in RSS 2.0 format.

=cut

sub getStaticRssFeedUrl {
    my $self = shift;
    return $self->_getStaticFeedUrl('rss');
}

#-------------------------------------------------------------------

=head2 getFeed ( $feed )

Adds the syndicated items to the feed; returns the stringified edition.

Returns this feed so that XML::FeedPP methods can be chained on it.

TODO: convert dates?

=head3 $feed

An XML::FeedPP sub-object, XML::FeedPP::{Atom,Rss,Rdf} that will be filled
with data from the Asset via the getRssFeedItems method.

=cut

sub getFeed {
    my $self = shift;
    my $feed = shift;
    foreach my $item ( @{ $self->getRssFeedItems } ) {
        my $set_permalink_false = 0;
        my $new_item = $feed->add_item( %{ $item } );
        if (!$new_item->guid) {
            if ($new_item->link) {
                $new_item->guid( $new_item->link );
            }
            else {
                $new_item->guid( $self->session->id->generate );
                $set_permalink_false = 1;
            }
        }
        $new_item->guid( $new_item->guid, isPermaLink => 0 ) if $set_permalink_false;
    }
    $feed->title( $self->feedTitle || $self->title );
    $feed->description( $self->feedDescription || $self->synopsis );
    $feed->pubDate( $self->getContentLastModified );
    $feed->copyright( $self->feedCopyright );
    $feed->link( $self->session->url->getSiteURL . $self->getUrl );
    # $feed->language( $lang );
    if ($self->feedImage) {
        my $storage = WebGUI::Storage->get($self->session, $self->feedImage);
        my @files = @{ $storage->getFiles };
        if (scalar @files) {
            $feed->image(
                $storage->getUrl( $files[0] ),
                $self->feedImageDescription || $self->getTitle,
                $self->feedImageUrl || $self->getUrl,
                $self->feedImageDescription || $self->getTitle,
                ( $storage->getSizeInPixels( $files[0] ) ) # expands to width and height
            );
        }
    }
    return $feed;
}

#-------------------------------------------------------------------

=head2 prepareView ()

Extend the master class to insert head links via addHeaderLinks.

=cut

around prepareView => sub {
    my $orig = shift;
    my $self = shift;
    $self->addHeaderLinks;
    return $self->$orig;
};

#-------------------------------------------------------------------

=head2 addHeaderLinks ()

Add RSS, Atom, or RDF links in the HEAD block of the Asset, depending
on how the Asset has configured feedHeaderLinks.

=cut

sub addHeaderLinks {
    my $self = shift;
    my $style = $self->session->style;
    my $title = $self->feedTitle || $self->title;
    my %feeds = map { $_ => 1 } split /\n/, $self->feedHeaderLinks;
    my $addType = keys %feeds > 1;
    if ($feeds{rss}) {
        $style->setLink($self->getRssFeedUrl, {
            rel   => 'alternate',
            type  => 'application/rss+xml',
            title => $title . ( $addType ? ' (RSS)' : ''),
        });
    }
    if ($feeds{atom}) {
        $style->setLink($self->getAtomFeedUrl, {
            rel   => 'alternate',
            type  => 'application/atom+xml',
            title => $title . ( $addType ? ' (Atom)' : ''),
        });
    }
    if ($feeds{rdf}) {
        $style->setLink($self->getRdfFeedUrl, {
            rel   => 'alternate',
            type  => 'application/rdf+xml',
            title => $title . ( $addType ? ' (RDF)' : ''),
        });
    }
}

#-------------------------------------------------------------------

=head2 www_viewAtom ()

Return Atom view of the syndicated items.

=cut

sub www_viewAtom {
    my $self = shift;
    return $self->_httpBasicLogin unless $self->canView;
    $self->session->response->content_type('application/atom+xml');
    return $self->getFeed( XML::FeedPP::Atom->new )->to_string;
}

#-------------------------------------------------------------------

=head2 www_viewRdf ()

Return Rdf view of the syndicated items.

=cut

sub www_viewRdf {
    my $self = shift;
    return $self->_httpBasicLogin unless $self->canView;
    $self->session->response->content_type('application/rdf+xml');
    return $self->getFeed( XML::FeedPP::RDF->new )->to_string;
}

#-------------------------------------------------------------------

=head2 www_viewRss ()

Return RSS view of the syndicated items.

=cut

sub www_viewRss {
    my $self = shift;
    return $self->_httpBasicLogin unless $self->canView;
    $self->session->response->content_type('application/rss+xml');
    return $self->getFeed( XML::FeedPP::RSS->new )->to_string;
}

1;
