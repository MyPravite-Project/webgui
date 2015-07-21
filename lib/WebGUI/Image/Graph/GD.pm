package WebGUI::Image::Graph::GD;

use strict;
use WebGUI::Image::Graph;
use Scalar::Util 'blessed';
use GD;
use GD::Graph;
use GD::Text;

our @ISA = qw(WebGUI::Image::Graph);

=head1 NAME

Package WebGUI::Image::Graph::Pie

=head1 DESCRIPTION

Base class for L<WebGUI::Image::Graph> classes that use the L<GD> image library instead of the L<Imager> image library.

=head1 SYNOPSIS

Replaces the L<Imager> implementation in the L<WebGUI::Image> superclass of our parent L<WebGUI::Image::Graph> with a L<GD::Graph> implementation.


=head1 METHODS

These methods are available from this class:

=cut

=head2 new( [width, height] )

Contstructor. See SUPER classes for additional parameters.
Defaults to 300x300.
This should be subclassed to create the correct type of graph (eg, L<GD::Graph::pie>).

=cut

sub new {
    my $class = shift;
    my $session = shift;

    my $width = shift || 300;
    my $height = shift || 300;

    my $img = GD::Graph->new( $width, $height, ) or die;

    my $self = bless {
        _image => $img,
        _session => $session,
        _properties => {
            width   => $width,
            height  => $height,
        },
    }, $class;

    $self->setBackgroundColor( $self->getBackgroundColor );  # the set method clears the image

    return $self;
}

=head2 to_rgb_triplet( '#ff0000' )

Function or class method.  GD wants lists of (R, G, B); this takes HTML style color hex strings and converts them to that.

=cut

sub to_rgb_triplet {
    shift @_ if ref($_[0] );
    return @_ if @_ == 3;
    @_ == 1 or die "argument should be an HTML style six character hex string; got ``@_''";
    my $color = shift;
    $color =~ s{^#}{};
    (my @triplet) = $color =~ m/(..)/g;
    @triplet = map hex $_, @triplet;
    return @triplet;
}

=head2 drawLabel ( $label, [ %properties ] )

Various methods have been subclassed from L<WebGUI::Image> and replaced with L<GD> equivalent.

Draw a label.
Ignores most of the properties currently, but does take C<x> and C<y> properties.

=cut

=head2 saveToFile( $fn )

=head2 saveToFileSystem( $path[, $filename] )

Defaults to the filename set in C<setFilename>.

=head2 saveToStorageLocation( $storage[, $filename] )

=head2 setImageWidth( $width )

=head2 setImageHeight( $height )

=head2 setBackgroundColor( '#ff0000' )

=cut

sub drawLabel {
    my $self = shift;
    my $label = shift;
    my %properties = @_;

    my $x = delete $properties{x};
    my $y = delete $properties{y};

    my $label_color = $self->image->gd->colorAllocate( to_rgb_triplet( $self->getLabelColor ) );

    if( GD::Text->can_do_ttf() ) {
        my $label_font = $self->getLabelFont;
        $label_font = $label_font->getFile if blessed($label_font) and $label_font->isa('WebGUI::Image::Font');  # extract the filename of the ttf if needed
        $self->image->gd->stringFT($label_color, $label_font, $self->getLabelFontSize, 0, $x, $y, $label);
    } else {
        $self->image->gd->string(gdSmallFont, $x, $y, $label, $label_color);
    }
}

sub saveToFile {
    my $self = shift;
    my $filename = shift;

    (my $type) = $filename =~ m/.*\.(\w)$/;
    $type ||= 'png';
    $type = 'png' unless grep $type eq $_, qw/jpg jpeg gif png/;

    open my $fh, '>', $filename or $self->session->log->error("Failed to open file for write:  $filename:  ``$!''");
    $fh->print( $self->image->gd->png ) if $type eq 'png';
    $fh->print( $self->image->gd->gif) if $type eq 'gif';
    $fh->print( $self->image->gd->jpeg ) if $type eq 'jpg' or $type eq 'jpeg';
    close $fh;
}

sub saveToFileSystem {
    my $self = shift;
    my $path = shift;
    my $filename = shift || $self->getFilename;
    $self->saveToFile("$path/$filename");
}

sub saveToStorageLocation {
    my $self = shift;
    my $storage = shift;
    my $filename = shift || $self->getFilename;
    $self->saveToFile( $storage->getPath($filename) );
}

sub setImageWidth {
    my $self = shift;
    my $width = shift;
    die "Must have a width" unless $width;

    $self->{_image} = GD::Graph::pie->new( $width, $self->getImageHeight, ) or die;
    $self->{_properties}->{width} = $width;

    $self->setBackgroundColor( $self->getBackgroundColor );  # set clears the image
}

sub setImageHeight {
    my $self = shift;
    my $height = shift;
    die "Must have a height " unless $height;

    $self->{_image} = GD::Graph::pie->new( $self->getImageWidth, $height ) or die;
    $self->{_properties}->{height} = $height;

    $self->setBackgroundColor( $self->getBackgroundColor );  # set clears the image
}

sub setBackgroundColor {
    my $self = shift;
    my $colorTriplet = shift;
    $colorTriplet ||= '#000000';
    $self->{_properties}->{backgroundColorTriplet} = $colorTriplet;
    my $bg = $self->image->gd->colorAllocate( to_rgb_triplet( $colorTriplet ) );
    $self->image->gd->filledRectangle( 0, 0, $self->getImageWidth-1, $self->getImageHeight-1, $bg, );
    $self->image->set( bgclr => $bg );
}

