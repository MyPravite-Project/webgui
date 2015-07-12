package WebGUI::Image;

use strict;
use WebGUI::Image::Palette;
use Imager;
use Imager::Font;
use Imager::Color;
use Imager::Fill;

=head1 NAME

Package WebGUI::Image

=head1 DESCRIPTION

Base class for image manipulations.

=head1 SYNOPSIS

This package purpous for now is to serve the basic needs of the graphing engine
built on top of this class. However, in the future this can be extended to allow
for all kinds of image manipulations within the WebGUI framework.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 getBackgroundColor ( )

Returns the background color triplet. Defaults to #ffffff (white).

=cut

sub getBackgroundColor {
	my $self = shift;

	return $self->{_properties}->{backgroundColorTriplet} || '#ffffff';
}

#-------------------------------------------------------------------

=head2 getFilename ( )

Returns the filename that has been set for this Image.  If no filename
has been set, then it throws a fatal error.

=cut

sub getFilename {
	my $self = shift;
	if (exists $self->{_properties}->{filename}) {
		return $self->{_properties}->{filename};
	}
	$self->session->log->fatal('Attempted to retrieve filename before one was set');
	return '';
}

#-------------------------------------------------------------------

=head2 getImageHeight ( )

Returns the height of the image in pixels.

=cut

sub getImageHeight {
	my $self = shift;

	return $self->{_properties}->{height} || 300;
}

#-------------------------------------------------------------------

=head2 getImageWidth ( )

Returns the width in pixels of the image.

=cut

sub getImageWidth {
	my $self = shift;

	return $self->{_properties}->{width} || 300;
}

#-------------------------------------------------------------------

=head2 getPalette ( )

Returns the palette object this image is set to. Defaults to the default palette.

=cut

sub getPalette {
	my $self = shift;

	if (!defined $self->{_palette}) {
		$self->{_palette} = WebGUI::Image::Palette->new($self->session, 'defaultPalette');
	}
	
	return $self->{_palette};
}

#-------------------------------------------------------------------

=head2 getXOffset ( )

Returns the horizontal offset of the center, relative to which the image is drawn.
Defaults to the physical center of the image.

=cut

sub getXOffset {
	my $self = shift;

	return $self->getImageWidth / 2; #$self->{_properties}->{xOffset} || $self->getWidth / 2;
}

#-------------------------------------------------------------------

=head2 getYOffset ( )

Returns the vertical offset of the center, relative to which the image is drawn.
Defaults to the physical center of the image.

=cut

sub getYOffset {
	my $self = shift;

	return $self->getImageHeight / 2; #$self->{_properties}->{yOffset} || $self->getHeight / 2;
}

#-------------------------------------------------------------------

=head2 image ( )

Returns the F<Imager> object containing this image.
F<Imager> replaces F<Image::Magick> as of C<8.0>.

=cut

sub image {
	my $self = shift;
	
	return $self->{_image};
}

#-------------------------------------------------------------------

=head2 new ( session, [ width, height ] )

Constructor for an image. Optionally you can pass the size of the image.
The new image is initialized to C<< $self->getBackgroundColor() >>.

=head3 session

The webgui session object.

=head3 width

The width of the image in pixels. Defaults to 300.

=head3 height

The height of the image in pixels. Defaults to 300.

=cut

sub new {
	my $class = shift;
	my $session = shift;
	
	my $width = shift || 300;
	my $height = shift || 300;

    my $img = Imager->new(
        xsize => $width, ysize => $height,
    );

	my $self = bless {
        _image => $img,
        _session => $session,
        _properties => {
            width	=> $width,
            height	=> $height,
		},
	}, $class;

    $img->box( filled => 1, color => Imager::Color->new( $self->getBackgroundColor() ), );

    return $self;
}

#-------------------------------------------------------------------

=head2 session ( )

Returns a reference to the current session.

=cut

sub session {
	my $self  = shift;

	return $self->{_session};
}

#-------------------------------------------------------------------

=head2 setBackgroundColor ( colorTriplet )

Sets the backgroundcolor. Using this method will erase everything that is
already on the image.

=head3 colorTriplet

The color for the background. Supply as a html color triplet of the form
#ffffff.

=cut

sub setBackgroundColor {
	my $self = shift;
	my $colorTriplet = shift;

    $colorTriplet ||= '#000000';
    my $color = Imager::Color->new($colorTriplet) or $self->session->log->error("Invalid color spec ``$colorTriplet''");
    $self->image->box( filled => 1, color => $color, );
	$self->{_properties}->{backgroundColorTriplet} = $colorTriplet;

}

#-------------------------------------------------------------------

=head2 setFilename ($filename)

Set the default filename to be used for this image.  Returns the filename.

=cut

sub setFilename {
	my ($self,$filename) = shift;
	$self->{_properties}->{filename} = $filename;
}

#-------------------------------------------------------------------

=head2 setImageHeight ( height )

Set the height of the image.
Blanks the newly extended or shrunk image to C<< $self->getBackgroundColor >>.

As of C<8.0>, this replaces the image object rather than modifying the existing one.
Previous copies returned by C<< image() >> are unchanged.

=head3 height

The height of the image in pixels.

=cut

sub setImageHeight {
	my $self = shift;
	my $height = shift;
        die "Must have a height" unless $height;

    my $img = Imager->new(
        xsize => $self->{_properties}->{width}, ysize => $height,
    );

	$self->{_properties}->{height} = $height;
    $self->{_image} = $img;

    $img->box( filled => 1, color => Imager::Color->new( $self->getBackgroundColor() ), );
}

#-------------------------------------------------------------------

=head2 setImageWidth ( width )

Set the width of the image.

=head3 width

The width of the image in pixels.

As of C<8.0>, this replaces the image object rather than modifying the existing one.
Previous copies returned by C<< image() >> are unchanged.

=cut

sub setImageWidth {
	my $self = shift;
	my $width = shift;
    die "Must have a width" unless $width;

    my $img = Imager->new(
        xsize => $width, ysize => $self->{_properties}->{height},
    );

	$self->{_properties}->{width} = $width;
    $self->{_image} = $img;

    $img->box( filled => 1, color => Imager::Color->new( $self->getBackgroundColor() ), );
}

#-------------------------------------------------------------------

=head2 setPalette ( palette )

Set the palette object this image will use.

=head3 palette

An instanciated WebGUI::Image::Palette object.

=cut

sub setPalette {
	my $self = shift;
	my $palette = shift;

	$self->{_palette} = $palette;
}

#-------------------------------------------------------------------

=head2 saveToFileSystem ( path, [ filename ] )

Saves the image to the specified path and filename.

=head3 path

The directory where the image should be saved.

=head3 filename

The filename the image should get. If not passed it will default to the name set
by the setFilename method.

=cut

sub saveToFileSystem {
	my $self = shift;
	my $path = shift;
	my $filename = shift || $self->getFilename;

    $self->image->write( file => $path.'/'.$filename ) or $self->session->log->error("Failed to write file: ``$path/$filename'': " . $self->image->errstr);
}

#-------------------------------------------------------------------

=head2 saveToScalar ( )

Returns a scalar containing the image contents.

NOTE: This method does not work properly at the moment!

=cut

sub saveToScalar {
	my $imageContents;
	my $self = shift;

    $self->image->write( type => 'png', data => \$imageContents ) or $self->session->log->error("Failed to save image to a string: " . $self->image->errstr);
	
	return $imageContents;
}

#-------------------------------------------------------------------

=head2 saveToStorageLocation ( storage, [ filename ] )

Save the image to the specified storage location.

=head3 storage

An instanciated WebGUI::Storage object.

=head3 filename

The filename the image should get. If not passed it will default to the name set
by the setFilename method.

=cut

sub saveToStorageLocation {
	my $self = shift;
	my $storage = shift;
	my $filename = shift || $self->getFilename;
	
    $self->image->write( file => $storage->getPath($filename) ) or $self->session->log->error('Failed to write file: ``' . $storage->getPath($filename) . "'': " . $self->image->errstr);
}

#-------------------------------------------------------------------

=head2 text ( properties )

Draw text captions on images.

=head3 properties

  C<x>, C<y>, C<text>, C<pointsize>, C<font>, C<alignHorizontal>, C<alignVertical>, C<align>, C<color>.

	alignHorizontal : The horizontal alignment for the text. Valid values are: 'left', 'center' and 'right'. Defaults to 'left'.

	alignVertical : The vertical alignment for the text. Valid values are: 'top', 'center' and 'bottom'. Defaults to 'top'.

You can use the align property to set the text justification.

=cut

sub text {
	my $self = shift;
	my %properties = @_;

    # my ($x_ppem, $y_ppem, $ascender, $descender, $width, $height, $max_advance) = $self->image->QueryMultilineFontMetrics(%properties);
    # brilliant, I'm now copying and pasting untested code

    my $pointsize = delete $properties{pointsize};
    my $color = delete $properties{color};
    my $font = delete $properties{font};

    if( $font and ! ref($font) ) {
        $font = Imager::Font->new(file => '$font', size => $pointsize, color => $color, );
    }
    $font ||= Imager::Font->new(
        file  =>  $self->getLabelFont->getFile,
        index => 0,
        size  => $self->getLabelFontSize,
    ) or $self->session->log->error("Failed to create a font object for file ``" . $self->getLabelFont->getFile . "'': " . Imager->errstr);

    my (undef, undef, $width, $height, undef, undef, undef, undef, ) = $font->bounding_box(string => $properties{text}, canon => 1);
    # warn "label width: $width height: $height";  # that seems to work, which is good, because we need it, it turns out

	# Process horizontal alignment
	if ($properties{alignHorizontal} eq 'center') {
		$properties{x} -= ($width / 2);
	}
	elsif ($properties{alignHorizontal} eq 'right') {
		$properties{x} -= $width;
	}

	# Process vertical alignment
	if ($properties{alignVertical} eq 'center') {
		$properties{y} -= ($height / 2);
	}
	elsif ($properties{alignVertical} eq 'bottom') {
		$properties{y} -= $height;
	}

	if ($properties{align} eq 'Center') {
        die;  # deprecating these unless I can find anything that actually uses them
	}
	elsif ($properties{align} eq 'Right') {
        die;
	}

	# We must delete these keys or else placement can go wrong for some reason...
	delete $properties{alignHorizontal};
	delete $properties{alignVertical};
    delete $properties{align};

    my $x = delete $properties{x};
    my $y = delete $properties{y};
    my $text = delete $properties{text};
    my $rotate = delete $properties{rotate};   # ignored but apparently frequently used previously; that requires changes to layouts
    my $style = delete $properties{style};     # ignored

    keys %properties and $self->session->log->error("Unrecognized optional argument(s) to WebGUI::Image::text: " . join ', ', keys %properties);  # no longer passing unrecognized arguments as-is to whatever image processing library we're currently using as a backend

	$self->image->string(
        x => $x,
        y => $y + $height,  # see note below for the align option
        text => $text,
        aa => 1,
        font => $font,
        size => $pointsize,
        color => $color,
        # align => 0,  # x, y is top left of the text, but then labels with ascenders next to those without are unaligned, so it's better to do this ourselves from font metrics
        # vlayout => $rotate, # this just makes it fail; docs say "for drivers that support it, draw the text vertically. Note: I haven't found a font that has the appropriate metrics yet"
    ) or $self->session->log->error("Failed to draw text on an image: ") . $self->image->errstr; # errstr never contains error text even when it fails (always fails when vlayout is set)

}

1;

