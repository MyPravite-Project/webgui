package WebGUI::Image::Graph::Pie;

use strict;
use WebGUI::Image::Graph;
use constant pi => 3.14159265358979;
use GD::Graph;
use GD::Graph::pie;

our @ISA = qw(WebGUI::Image::Graph);

=head1 NAME

Package WebGUI::Image::Graph::Pie

=head1 DESCRIPTION

Package to create pie charts, both 2d and 3d.

=head1 SYNOPSIS

Pie charts.

=head1 METHODS

These methods are available from this class:

=cut

=head2 new( [width, height] )

Contstructor. See SUPER classes for additional parameters.
XXX how do we tell people that we subclasses Image to use GD instead of Imager?
Defaults to 300x300.

=cut

sub new {
    my $class = shift;
    my $session = shift;

    my $width = shift || 300;
    my $height = shift || 300;

    my $img = GD::Graph::pie->new( $width, $height, ) or die;

    my $self = bless {
        _image => $img,
        _session => $session,
        _properties => {
            width   => $width,
            height  => $height,
        },
    }, $class;

    $self->setBackgroundColor( $self->getBackgroundColor );  # set clears the image

    return $self;
}

=head2 to_rgb_triplet

Function.  GD wants lists of (R, G, B); this takes HTML style color hex strings and converts them to that.

=cut

sub to_rgb_triplet {
    return @_ if @_ == 3;
    my $color = shift;
    $color =~ s{^#}{};
    (my @triplet) = $color =~ m/(..)/g;
    @triplet = map hex $_, @triplet;
    return @triplet;
}

=head2 configurationForm ( )

Called to compose the asset's edit view "Graphing" tab.
See WebGUI::Image::Graph for documentation.

=cut

sub configurationForm {
	my $self = shift;
    my $tab  = shift;

    $self->SUPER::configurationForm($tab);
	my $i18n = WebGUI::International->new($self->session, 'Image_Graph_Pie');

	$tab->addField('float',
		name		=> 'pie_topHeight',
		value		=> $self->getTopHeight,
		label		=> $i18n->get('pie height'),
		hoverHelp	=> $i18n->get('pie height description'),
	);
    $tab->addField('float',
        name        => 'pie_tiltAngle',
        value       => $self->getTiltAngle,
        label       => $i18n->get('tilt angle'), 
        hoverHelp   => $i18n->get('tilt angle description'),
    );
	$tab->addField('float',
		name		=> 'pie_startAngle',
		value		=> $self->getStartAngle,
		label		=> $i18n->get('start angle'),
		hoverHelp	=> $i18n->get('start angle description'),
	);
	$tab->addField('color',
		name		=> 'pie_stickColor',
		value		=> $self->getStickColor,
		label		=> $i18n->get('stick color'),
		hoverHelp	=> $i18n->get('stick color description'),
	);
	$tab->addField('selectBox',
		name		=> 'pie_labelPosition',
		value		=> [ $self->getLabelPosition ],
		label		=> $i18n->get('label position'),
		hoverHelp	=> $i18n->get('label position description'),	
		options=> {
			center	=> $i18n->get('center'), 
			top	=> $i18n->get('top'),
			bottom	=> $i18n->get('bottom'),
		},
	);
}

=head2 draw ( )

Draws the pie chart.

=cut

sub draw {

    my $self = shift;
    $self->image->set( '3d' => $self->getTiltAngle );

    my $dataset = $self->getDataset(0);  # 0th dataset; pie charts only plot one
    my $labels = $self->getLabel();

    # don't die if there is no data
    if( ! $dataset or ! @$dataset ) {
        $dataset = [1];
        $labels = ['No Votes Yet'];
    }

    $self->image->plot([ $labels, $dataset ]) or die "plot failed";

}

=head2 drawLabel ( label, [ properties ] )

Draw a label.

=cut

sub drawLabel {
 # XXXX unimpl for GD
    warn "XXXXXX";
}

=head2 formNamespace ( )

Extends the form namespace for this object. See WebGUI::Image::Graph for
documentation.

=cut

sub formNamespace {
	my $self = shift;

	return $self->SUPER::formNamespace.'_Pie';
}

=head2 getConfiguration ( )

Returns a configuration hashref. See WebGUI::Image::Graph for documentation.

=cut

sub getConfiguration {
	my $self = shift;

	my $config = $self->SUPER::getConfiguration;

    $config->{pie_tiltAngle}    = $self->getTiltAngle;
	$config->{pie_startAngle}	= $self->getStartAngle;
	$config->{pie_topHeight}	= $self->getTopHeight;
	$config->{pie_stickColor}	= $self->getStickColor;
	$config->{pie_labelPosition}	= $self->getLabelPosition;
	return $config;
}

=head2 setConfiguration ( config )

Applies the settings in the given configuration hash. See WebGUI::Image::Graph
for more information.

=head2 config

A configuration hash.

=cut

sub setConfiguration {
	my $self = shift;
	my $config = shift;

	$self->SUPER::setConfiguration($config);

	$self->setTiltAngle($config->{pie_tiltAngle});
	$self->setStartAngle($config->{pie_startAngle});
	$self->setTopHeight($config->{pie_topHeight});
	$self->setStickColor($config->{pie_stickColor});
	$self->setLabelPosition($config->{pie_labelPosition});
	
	return $config;
}


=head2 getDataset ( )

Returns the first dataset that is added. Pie charts can only handle one dataset
and therefore the first added dataset is used.

=cut

sub getDataset {
	my $self = shift;

	return $self->SUPER::getDataset(0);
}

=head2 getLabelPosition ( )

Returns the position of the labels relative to the thickness of the pie.
Allowed positions are 'bottom', 'center' and 'top'. Defaults to 'top'.

=cut

sub getLabelPosition {
	my $self = shift;

	return $self->{_pieProperties}->{labelPosition} || 'top';
}

=head2 setLabelPosition ( position )

Sets the position of the labels relative to the thickness of the pie.
Allowed positions are 'bottom', 'center' and 'top'. Defaults to 'top'.

=head3 position

The position of the labels.

=cut

sub setLabelPosition {
	my $self = shift;
	my $position = shift;
	
	$self->{_pieProperties}->{labelPosition} = $position;
}


=head2 getStartAngle ( )

Rteurn the initial angle of the first slice. In effect all slices are rotated by
this value.

=cut

sub getStartAngle {
	my $self = shift;

	return $self->{_pieProperties}->{startAngle} || 0;
}

=head2 setStartAngle ( angle )

Sets the initial angle of the first slice. In effect all slices are rotated by
this value.

=head3 angle

The desired start angle in degrees.

=cut

sub setStartAngle {
	my $self = shift;
	my $angle = shift;

	$self->{_pieProperties}->{startAngle} = $angle;
}

=head2 setStickColor ( color )

Sets the color of the sticks connecting pie and labels. Defaults to #333333.

=head3 color

The desired color value.

=cut

sub setStickColor {
	my $self = shift;
	my $color = shift;

	$self->{_pieProperties}->{stickColor} = $color;
}

=head2 getStickColor ( )

Returns the color of the sticks connecting pie and labels. Defaults to #333333.

=cut

sub getStickColor {
	my $self = shift;

	return $self->{_pieProperties}->{stickColor} || '#333333';
}

=head2 getTopHeight ( )

Returns the thickness of the top of the pie in pixels. Defaults to 20 pixels.

=cut

sub getTopHeight {
	my $self = shift;

	return 20 unless (defined $self->{_pieProperties}->{topHeight});
	return $self->{_pieProperties}->{topHeight};
}

=head2 setTopHeight ( thickness )

Sets the thickness of the top of the pie in pixels. Defaults to 20 pixels.

=head3 thickness

The thickness of the top in pixels.

=cut

sub setTopHeight {
	my $self = shift;
	my $height = shift;

	$self->{_pieProperties}->{topHeight} = $height;
}

=head2 getBottomHeight ( )

Returns the thickness of the bottom. Defaults to 0.

=cut

sub getBottomHeight {
	my $self = shift;

	return $self->{_pieProperties}->{bottomHeight} || 0;
}

=head2 setBottomHeight ( thickness )

Sets the thickness of the bottom.

=head3 thickness

The thickness of the bottom.

=cut

sub setBottomHeight {
	my $self = shift;
	my $height = shift;

	$self->{_pieProperties}->{bottomHeight} = $height;
}

=head2 setTiltAngle( $angle )

=head2 getTiltAngle( )

In wG7, this is the angle between the screen and the pie chart, from 0 to 90.
Currently recognized values are 0 for a 2D pie chart or 1 or greater for a 3D pie chart.
Defaults to a 3D pie chart.

=cut

=head2 setTiltAngle ( angle )

Sets the angle between the screen and the pie chart. Valid angles are 0 to 90
degrees. Zero degrees results in a 2d pie where other values will generate a 3d
pie chart. Defaults to 55 degrees.

=head3 angle

The tilt angle. Must be in the range from  0 to 90. If a value less than zero is
passed the angle will be set to 0. If a value greater than 90 is passed the
angle will be set to 90.

=cut        

sub setTiltAngle {
    my $self = shift;
    my $angle = shift;

    $angle = 0 if ($angle < 0);
    $angle = 90 if ($angle > 90);

    $self->{_pieProperties}->{tiltAngle} = $angle;
}

sub getTiltAngle {
    my $self = shift;
    my $angle = shift;

    return 55 unless defined $self->{_pieProperties}->{tiltAngle};
    return $self->{_pieProperties}->{tiltAngle};
}

=head2 Various things subclassed from WebGUI::Image XXX

=cut

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
}

