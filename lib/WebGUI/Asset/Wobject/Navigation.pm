package WebGUI::Asset::Wobject::Navigation;

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
use Tie::IxHash;
use WebGUI::Form;
use WebGUI::International;
use WebGUI::SQL;

use Moose;
use WebGUI::Definition::Asset;
use experimental 'smartmatch';

extends 'WebGUI::Asset::Wobject';

define assetName => ["assetName", 'Asset_Navigation'];
define icon      => 'navigation.gif';
define tableName => 'Navigation';

property    templateId => (
                label        => ['1096', 'Asset_Navigation'],
                hoverHelp    => ['1096 description', 'Asset_Navigation'],
                tab          => 'display',
                fieldType    => "template",
                default      => 'PBnav00000000000bullet',
                namespace    => 'Navigation',
            );
property    mimeType => (
                label        => ['mimeType', 'Asset_Navigation'],
                hoverHelp    => ['mimeType description', 'Asset_Navigation'],
                tab          => 'display',
                fieldType    => "mimeType",
                default      => 'text/html',
            );
property    assetsToInclude => (
                fieldType    => 'checkList',
                default      => "descendants",
                label        => ["Relatives To Include", 'Asset_Navigation'],
                hoverHelp    => ["Relatives To Include description", 'Asset_Navigation'],
                noFormPost   => 1,
            );
property    startType => (
                fieldType    => 'selectBox',
                default      => "relativeToCurrentUrl",
                label        => ["Start Point Type", 'Asset_Navigation'],
                hoverHelp    => ["Start Point Type description", 'Asset_Navigation'],
                noFormPost   => 1,
            );
property    startPoint => (
                fieldType   => 'text',
                default     => 0,
                label       => ["Start Point", 'Asset_Navigation'],
                hoverHelp   => ["Start Point description", 'Asset_Navigation'],
                noFormPost   => 1,
            );
property    ancestorEndPoint => (
                noFormPost  => 1,
                fieldType   => 'selectBox',
                default     => 55,
                noFormPost   => 1,
            );
property    descendantEndPoint => (
                noFormPost  => 1,
                fieldType   => 'selectBox',
                default     => 55,
                noFormPost   => 1,
            );
property    showSystemPages => (
                label        => [30, 'Asset_Navigation'],
                fieldType    => 'yesNo',
                default      => 0,
                tab         => "display",
            );
property    showHiddenPages => (
                label        => [31, 'Asset_Navigation'],
                fieldType    => 'yesNo',
                default      => 0,
                tab         => "display",
            );
property    showUnprivilegedPages => (
                label        => [32, 'Asset_Navigation'],
                fieldType    => 'yesNo',
                default      => 0,
                tab         => "display",
            );
property    reversePageLoop => (
                label        => ['reverse page loop', 'Asset_Navigation'],
                fieldType    => 'yesNo',
                default      => 0,
                tab         => "display",
            );

#-------------------------------------------------------------------

=head2 getEditForm ( )

Manually build the edit form due to javascript elements.

=cut

override getEditForm => sub {
    my $self = shift;
    my $fb   = super();
    my $i18n = WebGUI::International->new($self->session, "Asset_Navigation");
    my ( $descendantsChecked, $ancestorsChecked, $selfChecked, $pedigreeChecked, $siblingsChecked );
    my @assetsToInclude = split( "\n", $self->assetsToInclude );
    my $afterScript;
    foreach my $item (@assetsToInclude) {
        if ( $item eq "self" ) {
            $selfChecked = 1;
        }
        elsif ( $item eq "descendants" ) {
            $descendantsChecked = 1;
            $afterScript        = "displayNavEndPoint = false;";
        }
        elsif ( $item eq "ancestors" ) {
            $ancestorsChecked = 1;
        }
        elsif ( $item eq "siblings" ) {
            $siblingsChecked = 1;
        }
        elsif ( $item eq "pedigree" ) {
            $pedigreeChecked = 1;
        }
    } ## end foreach my $item (@assetsToInclude)
    $fb->getTab("properties")->addField( "selectBox",
        name    => "startType",
        options => {
            specificUrl          => $i18n->get('Specific URL'),
            relativeToCurrentUrl => $i18n->get('Relative To Current URL'),
            relativeToRoot       => $i18n->get('Relative To Root')
        },
        value     => [ $self->startType ],
        label     => $i18n->get("Start Point Type"),
        hoverHelp => $i18n->get("Start Point Type description"),
        id        => "navStartType",
        extras    => 'onchange="changeStartPoint()"'
    );
    $fb->getTab("properties")->addField( "ReadOnly",
        label     => $i18n->get("Start Point"),
        hoverHelp => $i18n->get("Start Point description"),
        value     => '<div id="navStartPoint"></div>'
    );
    tie my %ancestorEndPointOptions, 'Tie::IxHash', (
        '1'  => '../ (-1)',
        '2'  => '../../ (-2)',
        '3'  => '../../../ (-3)',
        '4'  => '../../../../ (-4)',
        '5'  => '../../../../../ (-5)',
        '55' => $i18n->get('Infinity')
    );
    $fb->getTab("properties")->addField( "SelectBox" => 
        name        => "ancestorEndPoint",
        value       => [ $self->ancestorEndPoint ],
        options     => \%ancestorEndPointOptions,
        label       => $i18n->get('Ancestor End Point'),
        rowClass    => 'navAncestorEnd',
    );
    $fb->getTab("properties")->addField( "ReadOnly" => 
        label     => $i18n->get("Relatives To Include"),
        hoverHelp => $i18n->get("Relatives To Include description"),
        value     => WebGUI::Form::Checkbox->new(
            $self->session, {
                checked => $ancestorsChecked,
                name    => "assetsToInclude",
                extras  => 'onchange="toggleAncestorEndPoint()"',
                value   => "ancestors"
            }
            )->toHtml
            . $i18n->get('Ancestors')
            . '<br />'
            . WebGUI::Form::Checkbox->new(
            $self->session, {
                checked => $selfChecked,
                name    => "assetsToInclude",
                value   => "self"
            }
            )->toHtml
            . $i18n->get('Self')
            . '<br />'
            . WebGUI::Form::Checkbox->new(
            $self->session, {
                checked => $siblingsChecked,
                name    => "assetsToInclude",
                value   => "siblings"
            }
            )->toHtml
            . $i18n->get('Siblings')
            . '<br />'
            . WebGUI::Form::Checkbox->new(
            $self->session, {
                checked => $descendantsChecked,
                name    => "assetsToInclude",
                value   => "descendants",
                extras  => 'onchange="toggleDescendantEndPoint()"'
            }
            )->toHtml
            . $i18n->get('Descendants')
            . '<br />'
            . WebGUI::Form::Checkbox->new(
            $self->session, {
                checked => $pedigreeChecked,
                name    => "assetsToInclude",
                value   => "pedigree"
            }
            )->toHtml
            . $i18n->get('Pedigree')
            . '<br />'
    );
    tie my %descendantEndPointOptions, 'Tie::IxHash', (
        '1'  => './a/ (+1)',
        '2'  => './a/b/ (+2)',
        '3'  => './a/b/c/ (+3)',
        '4'  => './a/b/c/d/ (+4)',
        '5'  => './a/b/c/d/e/ (+5)',
        '55' => $i18n->get('Infinity')
    );
    $fb->getTab("properties")->addField( "selectBox",
        name    => "descendantEndPoint",
        label   => $i18n->get('Descendant End Point'),
        value   => [ $self->descendantEndPoint ],
        options => \%descendantEndPointOptions,
        rowClass => "navDescendantEnd",
    );
    my $start = $self->startPoint;
    $fb->addField( "ReadOnly",
        value => 
        "<script type=\"text/javascript\">
            //<![CDATA[
            var displayNavDescendantEndPoint = true;
            var displayNavAncestorEndPoint = true;
            function toggleDescendantEndPoint () {
                    if (displayNavDescendantEndPoint) {
                            document.getElementById('descendantEndPoint_formId_row').style.display='none';
                            displayNavDescendantEndPoint = false;
                    } else {
                            document.getElementById('descendantEndPoint_formId_row').style.display='';
                            displayNavDescendantEndPoint = true;
                    }
            }
            function toggleAncestorEndPoint () {
                    if (displayNavAncestorEndPoint) {
                            document.getElementById('ancestorEndPoint_formId_row').style.display='none';
                            displayNavAncestorEndPoint = false;
                    } else {
                            document.getElementById('ancestorEndPoint_formId_row').style.display='';
                            displayNavAncestorEndPoint = true;
                    }
            }
            function changeStartPoint () {
                    var types = new Array();
                    types['specificUrl']='<input type=\"text\" name=\"startPoint\" value=\"" . $start . "\" />';
                    types['relativeToRoot']='<select name=\"startPoint\"><option value=\"0\""
            . ( ( $start == 0 ) ? ' selected=\"1\"' : '' )
            . ">/ (0)</option><option value=\"1\""
            . ( ( $start eq "1" ) ? ' selected=\"1\"' : '' )
            . ">/a/ (+1)</option><option value=\"2\""
            . ( ( $start eq "2" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/ (+2)</option><option value=\"3\""
            . ( ( $start eq "3" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/c/ (+3)</option><option value=\"4\""
            . ( ( $start eq "4" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/c/d/ (+4)</option><option value=\"5\""
            . ( ( $start eq "5" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/c/d/e/ (+5)</option><option value=\"6\""
            . ( ( $start eq "6" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/c/d/e/f/ (+6)</option><option value=\"7\""
            . ( ( $start eq "7" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/c/d/e/f/g/ (+7)</option><option value=\"8\""
            . ( ( $start eq "8" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/c/d/e/f/g/h/ (+8)</option><option value=\"9\""
            . ( ( $start eq "9" ) ? ' selected=\"1\"' : '' )
            . ">/a/b/c/d/e/f/g/h/i/ (+9)</option></select>';
                    types['relativeToCurrentUrl']='<select name=\"startPoint\"><option value=\"-3\""
            . ( ( $start eq "-3" ) ? ' selected=\"1\"' : '' )
            . ">../../.././ (-3)</option><option value=\"-2\""
            . ( ( $start eq "-2" ) ? ' selected=\"1\"' : '' )
            . ">../.././ (-2)</option><option value=\"-1\""
            . ( ( $start eq "-1" ) ? ' selected=\"1\"' : '' )
            . ">.././ (-1)</option><option value=\"0\""
            . ( ( $start == 0 || $start > 0 ) ? ' selected=\"1\"' : '' )
            . ">./ (0)</option></select>';
                    document.getElementById('navStartPoint').innerHTML=types[document.getElementById('navStartType').options[document.getElementById('navStartType').selectedIndex].value];
            }
            " . $afterScript . "
            YAHOO.util.Event.onDOMReady( initWebGUINavigation );
            function initWebGUINavigation() {
            changeStartPoint();
            " . ( $descendantsChecked ? "" : "toggleDescendantEndPoint();" ) . "
            " . ( $ancestorsChecked   ? "" : "toggleAncestorEndPoint();" ) . "
            }
            //]]>
            </script>"
    );
    #document.getElementById('navStartPoint_formId').innerHTML=types[document.getElementById('navStartType').options[document.getElementById('navStartType').selectedIndex].value];
    return $fb;
};

#-------------------------------------------------------------------

=head2 prepareView ( )

Extend the superclass to add metadata and to preprocess the template.

=cut

override prepareView => sub {
    my $self = shift;
    super();
    my $template = WebGUI::Asset::Template->newById($self->session, $self->templateId); # part of Couldn't lookup className (param: PBtmpl0000000000000048)
    if (!$template) {
        WebGUI::Error::ObjectNotFound::Template->throw(
            error      => qq{Template not found},
            templateId => $self->templateId,
            assetId    => $self->getId,
        );
    }
    $template->prepare($self->getMetaDataAsTemplateVariables);
    $self->{_viewTemplate} = $template;
};


#-------------------------------------------------------------------

=head2 processEditForm ( )

Extend the super class to handle saving the form fields that we've drawn ourselves.

=cut

override processEditForm => sub {
    my $self = shift;
    my $form      = $self->session->form;
    my $overrides = $self->session->config->get( "assets/" . $self->get("className") . "/fields" );
    my %data;
    super();
    foreach my $property ( qw/assetsToInclude startType startPoint ancestorEndPoint descendantEndPoint/ ) {

        my $fieldType      = $self->meta->find_attribute_by_name($property)->fieldType;
        my $fieldOverrides = $overrides->{$property} || {};
        my $fieldHash      = {
            tab => "properties",
            %{ $self->getFormProperties($property) },
            %{$overrides},
            name  => $property,
            value => $self->$property,
        };


        # process the form element
        my $defaultValue = $overrides->{defaultValue} // $self->$property;
        $data{$property} = $form->process( $property, $fieldType, $defaultValue, $fieldHash );
    } ## end foreach my $property ( $self...)

    $self->session->db->beginTransaction;
    $self->update( \%data );
    $self->session->db->commit;

};


#-------------------------------------------------------------------

=head2 view ( )

See WebGUI::Asset::view() for details.

=cut

sub view {
	my $self = shift;
	# we've got to determine what our start point is based upon user conditions
	my $start;
	$self->session->asset(WebGUI::Asset->newByUrl($self->session)) unless ($self->session->asset);

	my $var = {'page_loop' => []};

	my $current = $self->session->asset;
    # no current asset is set
    unless (defined $current) {
        $current = WebGUI::Asset->getDefault($self->session);
    }

	my @interestingProperties = ('assetId', 'parentId', 'ownerUserId', 'synopsis', 'newWindow');
    # Add properties from current asset
    foreach my $property (@interestingProperties) {
		$var->{'currentPage.'.$property} = $current->$property;
	}
    $var->{'currentPage.menuTitle'} = $current->getMenuTitle;
    $var->{'currentPage.title'}     = $current->getTitle;
    $var->{'currentPage.isHome'} = ($current->getId eq $self->session->setting->get("defaultPage"));
    $var->{'currentPage.url'} = $current->getUrl;
    $var->{'currentPage.hasChild'} = $current->hasChildren;
    $var->{'currentPage.rank'} = $current->getRank;
    $var->{'currentPage.rankIs'.$current->getRank} = 1;

    # Build the asset tree
	if ($self->startType eq "specificUrl") {
		$start = WebGUI::Asset->newByUrl($self->session,$self->startPoint);
	}
    elsif ($self->startType eq "relativeToRoot") {
		unless (($self->startPoint+1) >= $current->getLineageLength) {
			$start = WebGUI::Asset->newByLineage($self->session,substr($current->lineage,0, ($self->startPoint + 1) * 6));
		}
	}
    elsif ($self->startType eq "relativeToCurrentUrl") {
		$start = WebGUI::Asset->newByLineage($self->session,substr($current->lineage,0, ($current->getLineageLength + $self->startPoint) * 6));
	}
	$start = $current unless (defined $start); # if none of the above results in a start point, then the current page must be it
	my @includedRelationships = split("\n",$self->assetsToInclude);

	my %rules;
	$rules{endingLineageLength} = $start->getLineageLength+$self->descendantEndPoint;
	$rules{assetToPedigree} = $current if ("pedigree" ~~ @includedRelationships);
	$rules{ancestorLimit} = $self->ancestorEndPoint;
	$rules{orderByClause} = 'rpad(asset.lineage, 255, 9) desc' if ($self->reversePageLoop);
	my $assetIter = $start->getLineageIterator(\@includedRelationships,\%rules);	
	my $currentLineage = $current->lineage;
	my $lineageToSkip = "noskip";
	my $absoluteDepthOfLastPage;
    my $absoluteDepthOfFirstPage;   # Will set on first iteration of loop, below
	my %lastChildren;
	my $previousPageData = undef;
	my $log = $self->session->log;
        while ( 1 ) {
            my $asset;
            eval { $asset = $assetIter->() };
            if ( my $x = WebGUI::Error->caught('WebGUI::Error::ObjectNotFound') ) {
                $self->session->log->error($x->full_message);
                next;
            }
            last unless $asset;

		# skip pages we shouldn't see
		my $pageLineage = $asset->lineage;
		next if ($pageLineage =~ m/^$lineageToSkip/);
		
		if ($asset->isHidden && !$self->showHiddenPages) {
			$lineageToSkip = $pageLineage unless ($pageLineage eq "000001");
			next;
		}
		if ($asset->isSystem && !$self->showSystemPages) {
			$lineageToSkip = $pageLineage unless ($pageLineage eq "000001");
			next;
		}
		unless ($self->showUnprivilegedPages || $asset->canView) {
			$lineageToSkip = $pageLineage unless ($pageLineage eq "000001");
			next;
		}

        # Set absoluteDepthOfFirstPage after we have determined if the first page is viewable!
        # Otherwise, the indent loop calculation below will be off by 1 (or more)
        if ( !defined $absoluteDepthOfFirstPage ) {
            $absoluteDepthOfFirstPage   = $asset->getLineageLength;
        }

		my $pageData = {};
        my $pageProperties = $asset->get;
        while (my ($property, $propertyValue) = each %{ $pageProperties }) {
			$pageData->{"page.".$property} = $propertyValue;
		}
		$pageData->{'page.menuTitle'} = $asset->getMenuTitle;
		$pageData->{'page.title'}     = $asset->getTitle;
		# build nav variables
		$pageData->{"page.rank"}     = $asset->getRank;
		$pageData->{"page.absDepth"} = $asset->getLineageLength;
		$pageData->{"page.relDepth"} = $asset->getLineageLength - $absoluteDepthOfFirstPage;
		$pageData->{"page.isSystem"} = $asset->isSystem;
		$pageData->{"page.isHidden"} = $asset->isHidden;
		$pageData->{"page.isViewable"} = $asset->canView;
		$pageData->{'page.isContainer'} = $self->session->config->get("assets/".$asset->className."/isContainer");
  		$pageData->{'page.isUtility'} = $self->session->config->get("assets/".$asset->className."/category") eq "utilities";
		$pageData->{"page.url"} = $asset->getUrl;
		my $indent = $asset->getLineageLength - $absoluteDepthOfFirstPage;
		$pageData->{"page.indent_loop"} = [];
		push(@{$pageData->{"page.indent_loop"}},{'indent'=>$_}) for(1..$indent);
		$pageData->{"page.indent"} = "&nbsp;&nbsp;&nbsp;" x $indent;
		$pageData->{"page.isBranchRoot"} = ($pageData->{"page.absDepth"} == 1);
		$pageData->{"page.isTopOfBranch"} = ($pageData->{"page.absDepth"} == 2);
		$pageData->{"page.isChild"} = ($asset->parentId eq $current->getId);
		$pageData->{"page.isParent"} = ($asset->getId eq $current->parentId);
		$pageData->{"page.isCurrent"} = ($asset->getId eq $current->getId);
		$pageData->{"page.isDescendant"} = ( $pageLineage =~ m/^$currentLineage/ && !$pageData->{"page.isCurrent"});
		$pageData->{"page.isAncestor"} = ( $currentLineage =~ m/^$pageLineage/ && !$pageData->{"page.isCurrent"});
		my $currentBranchLineage = substr($currentLineage,0,12);
		$pageData->{"page.inBranchRoot"} = ($pageLineage =~ m/^$currentBranchLineage/);
		$pageData->{"page.isSibling"} = (
			$asset->parentId eq $current->parentId &&
			$asset->getId ne $current->getId
			);
		$pageData->{"page.inBranch"} = ( 
			$pageData->{"page.isCurrent"} ||
			$pageData->{"page.isAncestor"} ||
			$pageData->{"page.isSibling"} ||
			$pageData->{"page.isDescendant"}
			);
		$pageData->{"page.depthIs".$pageData->{"page.absDepth"}} = 1;
		$pageData->{"page.relativeDepthIs".$pageData->{"page.relDepth"}} = 1;
		my $depthDiff = ($absoluteDepthOfLastPage) ? ($absoluteDepthOfLastPage - $pageData->{'page.absDepth'}) : 0;
		$pageData->{"page.depthDiff"} = $depthDiff;
		$pageData->{"page.depthDiffIs".$depthDiff} = 1;
		if ($depthDiff > 0) {
			push(@{$pageData->{"page.depthDiff_loop"}},{}) for(1..$depthDiff);
		}
		$absoluteDepthOfLastPage = $pageData->{"page.absDepth"};
		$pageData->{"page.hasChild"} = $asset->hasChildren;
                ++$var->{"currentPage.hasSibling"}
                        if $pageData->{"page.isSibling"};
                ++$var->{"currentPage.hasViewableSiblings"}
                        if ($pageData->{"page.isSibling"} && $pageData->{"page.isViewable"});
                ++$var->{"currentPage.hasViewableChildren"}
                        if ($pageData->{"page.isChild"} && $pageData->{"page.isViewable"});

		my $parent = $asset->getParent;
		if (defined $parent) {
            foreach my $property (@interestingProperties) {
				$pageData->{"page.parent.".$property} = $parent->$property;
			}
			$pageData->{'page.parent.menuTitle'} = $parent->getMenuTitle;
			$pageData->{'page.parent.title'} = $parent->getTitle;
			$pageData->{"page.parent.url"} = $parent->getUrl;
			$pageData->{"page.parent.rank"} = $parent->getRank;
			$pageData->{"page.isRankedFirst"} = 1 unless exists $lastChildren{$parent->getId};
			$lastChildren{$parent->getId} = $asset->getId;			
		}
		$previousPageData->{"page.hasViewableChildren"} = ($previousPageData->{"page.assetId"} eq $pageData->{"page.parentId"});
		push(@{$var->{page_loop}}, $pageData);	
		$previousPageData = $pageData;
	}
	my $counter;
	for($counter=0 ; $counter < scalar( @{$var->{page_loop}} ) ; $counter++) {
		@{$var->{page_loop}}[$counter]->{"page.isRankedLast"} = 1 if 
			($lastChildren{@{$var->{page_loop}}[$counter]->{"page.parent.assetId"}} 
				eq @{$var->{page_loop}}[$counter]->{"page.assetId"});
	}
	return $self->processTemplate($var,undef,$self->{_viewTemplate});
}

#-------------------------------------------------------------------

=head2 www_goBackToPage ( )

Do a redirect to the form parameter returnUrl if it exists.

=cut

sub www_goBackToPage {
	my $self = shift;
	$self->session->response->setRedirect($self->session->form->process("returnUrl")) if ($self->session->form->process("returnUrl"));
	return undef;
}

#-------------------------------------------------------------------

=head2 www_view

A web accessible version of the view method.  The SUPER method is overridden so that we can serve
other types aside from text/html.

=cut

override www_view => sub {
	my $self = shift;
	my $mimeType = $self->mimeType || 'text/html';
	if ($mimeType eq 'text/html') {
		return super();
	}
	else {
		$self->prepareView();
		$self->session->response->content_type($mimeType);
		return $self->view();
	}
};

__PACKAGE__->meta->make_immutable;
1;

