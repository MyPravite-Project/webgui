# vim:syntax=perl
#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2012 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#------------------------------------------------------------------

# Write a little about what this script tests.
# 
#

use strict;
use Test::More;
use Test::Deep;
use Data::Dumper;
use JSON;
use Path::Class;

use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;
use WebGUI::Image::Graph;

################################################################
#
#  setup session, users and groups for this test
#
################################################################

my $session         = WebGUI::Test->session;

#----------------------------------------------------------------------------
# put your tests here

my $class  = 'WebGUI::Asset::Wobject::Poll';
my $loaded = use_ok($class);

ok $loaded, "Loaded class module $class";

my $defaultNode = WebGUI::Test->asset;
my $template = $defaultNode->addChild({
    className => 'WebGUI::Asset::Template',
    parser    => 'WebGUI::Asset::Template::HTMLTemplate',
    title     => 'test poll template',
    template  => q|
{
"responses.total" : "<tmpl_var responses.total>",
"hasImageGraph"   : "<tmpl_var hasImageGraph>",
"graphUrl"        : "<tmpl_var graphUrl>"
}
|,
});

my $poll = $defaultNode->addChild({
    className     => $class,
    active        => 1,
    title         => 'test poll',
    generateGraph => 1,
    question      => "How often do you look at a man's shoes?",
    a1            => 'daily',
    a2            => 'hourly',
    a3            => 'never',
    templateId    => $template->getId,
    graphConfiguration => '{"graph_labelFontSize":"20","xyGraph_chartWidth":"200","xyGraph_drawRulers":"1","graph_labelColor":"#333333","xyGraph_drawAxis":"1","graph_formNamespace":"Graph_XYGraph_Bar","graph_backgroundColor":"#ffffff","xyGraph_bar_barSpacing":0,"graph_labelFontId":"defaultFont","graph_labelOffset":"10","xyGraph_drawMode":"sideBySide","xyGraph_yGranularity":"10","xyGraph_chartHeight":"200","graph_imageHeight":"300","graph_imageWidth":"300","xyGraph_drawLabels":"1","xyGraph_bar_groupSpacing":0,"graph_paletteId":"defaultPalette"}',
});

isa_ok($poll, 'WebGUI::Asset::Wobject::Poll');

$poll->setVote('a1', 1, '127.0.0.1');
$poll->setVote('a2', 1, '127.0.0.1');
$poll->setVote('a3', 1, '127.0.0.1');
$poll->setVote('a3', 1, '127.0.0.1');

# Bar graph
# (apparently indicated by graph_formNamespace in the graphConfiguration JSON)

$poll->prepareView();
my $json = $poll->view();
my $output = JSON::from_json($json);

cmp_deeply(
    $output,
    {
        'responses.total' => 4,
        hasImageGraph     => 1,
        graphUrl          => re('^\S+$'),
    },
    'poll has correct number of responses, a graph and a path to the generated file'
);

sub getGraphFile {
    my $graphUrl = shift;
    my $graphUrl = Path::Class::File->new($graphUrl);
    my $uploadsPath = Path::Class::Dir->new($session->config->get('uploadsPath'));
    my $uploadsUrl  = Path::Class::Dir->new($session->config->get('uploadsURL'));
    my $graphRelative = $graphUrl->relative($uploadsUrl);
    my $graphFile     = $uploadsPath->file($graphRelative);
    return $graphFile;
}

my $graphFile = getGraphFile($output->{graphUrl});

ok(-e $graphFile->stringify, 'graph exists');

diag "XY graph output: " . $graphFile->stringify;

ok(-e $graphFile->stringify, 'graph exists');

# Line graph

$poll->update({ graphConfiguration => <<EOF });
    {"graph_labelOffset":"10","xyGraph_drawLabels":"1","graph_labelFontId":"defaultFont","graph_labelColor":"#333333","graph_backgroundColor":"#ffffff","xyGraph_yGranularity":"10","graph_formNamespace":"Graph_XYGraph_Line","graph_imageHeight":"300","xyGraph_drawAxis":"1","xyGraph_drawMode":"sideBySide","xyGraph_chartHeight":"200","graph_labelFontSize":"20","graph_paletteId":"defaultPalette","graph_imageWidth":"300","xyGraph_drawRulers":"1","xyGraph_chartWidth":"200"}
EOF

$poll->prepareView();
$output = JSON::from_json( $poll->view() );
$graphFile = getGraphFile($output->{graphUrl});
ok(-e $graphFile->stringify, 'graph exists');
diag "Line graph output: " . $graphFile->stringify;

# Pie graph

$poll->update({ graphConfiguration => <<EOF });
   {"graph_imageWidth":"300","graph_backgroundColor":"#ffffff","pie_labelPosition":"top","pie_stickColor":"#333333","graph_labelOffset":"10","graph_paletteId":"defaultPalette","pie_tiltAngle":"55","graph_labelFontId":"defaultFont","graph_labelColor":"#333333","pie_topHeight":"20","graph_labelFontSize":"20","graph_formNamespace":"Graph_Pie","graph_imageHeight":"300","pie_startAngle":0}
EOF

$poll->prepareView();
$output = JSON::from_json( $poll->view() );
$graphFile = getGraphFile($output->{graphUrl});
ok(-e $graphFile->stringify, 'graph exists');
diag "Pie graph output: " . $graphFile->stringify;


# done

done_testing;
