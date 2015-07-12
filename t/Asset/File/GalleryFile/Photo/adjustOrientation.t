#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;

# Test the 'adjustOrientation' method called by 'applyConstraints'. It is 
# responsible for rotating JPEG images according to orientation information
# in EXIF data (if present). A number of test images have been created for 
# this purpose which are checked based on dimensions and pixel-wise.

use WebGUI::Test;
use WebGUI::Session;
use WebGUI::Asset::File::GalleryFile::Photo;

use Test::More; 
use Test::Deep;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;
my $node            = WebGUI::Asset->getImportNode($session);
my $versionTag      = WebGUI::VersionTag->getWorking($session);

# Name version tag and make sure it gets cleaned up
$versionTag->set({name=>"Orientation adjustment test"});
WebGUI::Test->addToCleanup($versionTag);

# Create gallery and a single album
my $gallery
    = $node->addChild({
        className           => "WebGUI::Asset::Wobject::Gallery",
        imageResolutions    => "1024",        
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });
my $album
    = $gallery->addChild({
        className           => "WebGUI::Asset::Wobject::GalleryAlbum",
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });
    
# Create single photo inside the album    
my $photo
    = $album->addChild({
        className           => "WebGUI::Asset::File::GalleryFile::Photo",
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });

# Commit all changes
$versionTag->commit;

#----------------------------------------------------------------------------
# Tests
plan tests => 8;

#----------------------------------------------------------------------------
# Test adjustment of image with orientation set to 1

$photo->setFile( WebGUI::Test->getTestCollateralPath('orientation_1.jpg') );
my $storage = $photo->getStorageLocation;

# Check dimensions
cmp_deeply( [ $storage->getSizeInPixels($photo->get('filename')) ], [2, 3], "Check if image with orientation 1 was left as is (based on dimensions)" );

# Check single pixel
my $image = Imager->new;
$image->read(file => $storage->getPath( $photo->get('filename') )) or die Imager->errstr();
cmp_bag([ $image->getpixel(x=>1, y=>1)->rgba() ], [255,255,255,ignore()], 'Check if image with orientation 1 was left as is (based on pixel values)');


#----------------------------------------------------------------------------
# Test adjustment of image with orientation set to 3

# Attach new image to Photo asset
$photo->setFile( WebGUI::Test->getTestCollateralPath('orientation_3.jpg') );
$storage = $photo->getStorageLocation;

# uncomment to view before/after images
# system 'xv',  WebGUI::Test->getTestCollateralPath('orientation_3.jpg'); # XXX
# system 'xv', $storage->getPath( $photo->get('filename') );  # XXX

# Check dimensions
cmp_deeply( [ $storage->getSizeInPixels($photo->get('filename')) ], [2, 3], "Check if image with orientation 3 was rotated by 180° (based on dimensions)" );

# Check single pixel
$image->read( file => $storage->getPath( $photo->get('filename') ) ) or die Imager->errstr();
ok my @pixel =  $image->getpixel( x=>1, y=>2 )->rgba(), "read bottom right pixel";
ok $pixel[0] < 50 && $pixel[1] < 50 && $pixel[2] < 50, "Check if image with orientation 3 was rotated by 180° (based on pixels)"; # jpeg recompression smears the image, but the bottom right corner should now be dark
ok @pixel =  $image->getpixel( x=>0, y=>0 )->rgba(), "read top left pixel";
ok $pixel[0] > 200  && $pixel[1] > 200 && $pixel[2] > 200, "Check if image with orientation 3 was rotated by 180°, part II (based on pixels)"; # jpeg recompression smears the image, but the top left pixel should now be light

#----------------------------------------------------------------------------
# Test adjustment of image with orientation set to 6

# Attach new image to Photo asset
$photo->setFile( WebGUI::Test->getTestCollateralPath('orientation_6.jpg') );
my $storage = $photo->getStorageLocation;

# Check dimensions
cmp_deeply( [ $storage->getSizeInPixels($photo->get('filename')) ], [3, 2], "Check if image with orientation 6 was rotated by 90° CW (based on dimensions)" );

# Check single pixel
$image->read( file => $storage->getPath( $photo->get('filename') ) ) or die Imager->errstr();

ok my @pixel =  $image->getpixel( x=>2, y=>0 )->rgba(), "read top right pixel";
ok $pixel[0] < 50 && $pixel[1] < 50 && $pixel[2] < 50, "Check if image with orientation 6 was rotated by 90° CW (based on pixels)"; # jpeg recompression smears the image, but the top right corner should now be dark
ok @pixel =  $image->getpixel( x=>0, y=>0 )->rgba(), "read top left pixel";
ok $pixel[0] > 200  && $pixel[1] > 200 && $pixel[2] > 200, "Check if image with orientation 6 was rotated by 90° CW, part II (based on pixels)"; # jpeg recompression smears the image, but the top left pixel should now be light


#----------------------------------------------------------------------------
# Test adjustment of image with orientation set to 8

# Attach new image to Photo asset
$photo->setFile( WebGUI::Test->getTestCollateralPath('orientation_8.jpg') );
$storage = $photo->getStorageLocation;

# Check dimensions
cmp_deeply( [ $storage->getSizeInPixels($photo->get('filename')) ], [3, 2], "Check if image with orientation 8 was rotated by 90° CCW (based on dimensions)" );

# Check single pixel
$image->read( file => $storage->getPath( $photo->get('filename') ) );

ok my @pixel =  $image->getpixel( x=>0, y=>1 )->rgba(), "read bottom left pixel";
ok $pixel[0] < 50 && $pixel[1] < 50 && $pixel[2] < 50, "Check if image with orientation 8 was rotated by 90° CCW (based on pixels)"; # the bottom left corner should now be dark
ok @pixel =  $image->getpixel( x=>0, y=>0 )->rgba(), "read top left pixel";
ok $pixel[0] > 200  && $pixel[1] > 200 && $pixel[2] > 200, "Check if image with orientation 8 was rotated by 90° CCW, part II (based on pixels)"; # the top left pixel should now be light

