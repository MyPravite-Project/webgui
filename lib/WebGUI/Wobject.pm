package WebGUI::Wobject;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2004 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use CGI::Util qw(rearrange);
use DBI;
use strict qw(subs vars);
use Tie::IxHash;
use WebGUI::DateTime;
use WebGUI::FormProcessor;
use WebGUI::Grouping;
use WebGUI::HTML;
use WebGUI::HTMLForm;
use WebGUI::Icon;
use WebGUI::Id;
use WebGUI::International;
use WebGUI::Macro;
use WebGUI::Node;
use WebGUI::Page;
use WebGUI::Privilege;
use WebGUI::Session;
use WebGUI::SQL;
use WebGUI::TabForm;
use WebGUI::Template;
use WebGUI::URL;
use WebGUI::Utility;
use WebGUI::MetaData;
use WebGUI::Wobject::WobjectProxy;

=head1 NAME

Package WebGUI::Wobject

=head1 DESCRIPTION

An abstract class for all other wobjects to extend.

=head1 SYNOPSIS

 use WebGUI::Wobject;
 our @ISA = qw(WebGUI::Wobject);

See the subclasses in lib/WebGUI/Wobjects for details.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------
sub _reorderWobjects {
	my ($sth, $i, $wid);
	$sth = WebGUI::SQL->read("select wobjectId from wobject where pageId=".quote($_[0])." order by templatePosition,sequenceNumber");
	while (($wid) = $sth->array) {
		$i++;
		WebGUI::SQL->write("update wobject set sequenceNumber='$i' where wobjectId=".quote($wid));
	}
	$sth->finish;
}


#-------------------------------------------------------------------
sub _getNextSequenceNumber {
	my ($sequenceNumber);
	($sequenceNumber) = WebGUI::SQL->quickArray("select max(sequenceNumber) from wobject where pageId=".quote($_[0]));
	return ($sequenceNumber+1);
}

#-------------------------------------------------------------------

=head2 canEdit ( )

Returns a boolean (0|1) value signifying that the user has the required privileges.

=cut

sub canEdit {
	my $self = shift;
        return WebGUI::Page::canEdit() if ($session{page}{wobjectPrivileges} != 1 || $self->get("wobjectId") eq "new");
        if ($session{user}{userId} == $self->get("ownerId")) {
                return 1;
        } else {
		return WebGUI::Grouping::isInGroup($self->get("groupIdEdit"));
        }
}

#-------------------------------------------------------------------

=head2 canView ( )

Returns a boolean (0|1) value signifying that the user has the required privileges. Returns true for users that have the rights to edit this wobject.

=cut    
        
sub canView {
	my $self = shift;
        return WebGUI::Page::canView() unless ($session{page}{wobjectPrivileges} == 1);
        if ($session{user}{userId} == $self->get("ownerId")) {
          	return 1;
        } elsif ($self->get("startDate") < WebGUI::DateTime::time() && $self->get("endDate") > WebGUI::DateTime::time() && WebGUI::Grouping::isInGroup($self->get("groupIdView"))) {
          	return 1;
       	} else {
		return $self->canEdit;
       	}
}


#-------------------------------------------------------------------

=head2 confirm ( message, yesURL, [ , noURL, vitalComparison ] )

=head3 message

A string containing the message to prompt the user for this action.

=head3 yesURL

A URL to the web method to execute if the user confirms the action.

=head3 noURL

A URL to the web method to execute if the user denies the action.  Defaults back to the current page.

=head3 vitalComparison

A comparison expression to be used when checking whether the action should be allowed to continue. Typically this is used when the action is a delete of some sort.

=cut

sub confirm {
        return WebGUI::Privilege::vitalComponent() if ($_[4]);
	my $noURL = $_[3] || WebGUI::URL::page();
        my $output = '<h1>'.WebGUI::International::get(42).'</h1>';
        $output .= $_[1].'<p>';
        $output .= '<div align="center"><a href="'.$_[2].'">'.WebGUI::International::get(44).'</a>';
        $output .= ' &nbsp; <a href="'.$noURL.'">'.WebGUI::International::get(45).'</a></div>';
        return $output;
}


#-------------------------------------------------------------------

=head2 deleteCollateral ( tableName, keyName, keyValue )

Deletes a row of collateral data.

=head3 tableName

The name of the table you wish to delete the data from.

=head3 keyName

The name of the column that is the primary key in the table.

=head3 keyValue

An integer containing the key value.

=cut

sub deleteCollateral {
        WebGUI::SQL->write("delete from $_[1] where $_[2]=".quote($_[3]));
	WebGUI::ErrorHandler::audit("deleted ".$_[2]." ".$_[3]);
}


#-------------------------------------------------------------------

=head2 description ( )

Returns this instance's description if it exists.

=cut

sub description {
        if ($_[0]->get("description")) {
                return $_[0]->get("description").'<p>';
        }
}

#-------------------------------------------------------------------

=head2 displayTitle ( )

Returns this instance's title if displayTitle is set to yes.

=cut

sub displayTitle {
        if ($_[0]->get("displayTitle")) {
                return "<h1>".$_[0]->get("title")."</h1>";
        } else {
		return "";
	}
}

#-------------------------------------------------------------------

=head2 duplicate ( [ pageId ] )

Duplicates this wobject with a new wobject Id. Returns the new wobject Id.

B<NOTE:> This method is meant to be extended by all sub-classes.

=head3 pageId 

If specified the wobject will be duplicated to this pageId, otherwise it will be duplicated to the clipboard.

=cut

sub duplicate {
	my %properties;
	tie %properties, 'Tie::CPHash';
	%properties = %{$_[0]->get};
	$properties{pageId} = $_[1] || 2;
	$properties{sequenceNumber} = _getNextSequenceNumber($properties{pageId});
	my $page = WebGUI::SQL->quickHashRef("select groupIdView,ownerId,groupIdEdit from page where pageId=".quote($properties{pageId}));
	$properties{ownerId} = $page->{ownerId};
        $properties{groupIdView} = $page->{groupIdView};
        $properties{groupIdEdit} = $page->{groupIdEdit};
	if ($properties{pageId} == 2)  {
		$properties{bufferUserId} = $session{user}{userId};
		$properties{bufferDate} = time();
		$properties{bufferPrevId} = {};
	}
	my $orginalWid = $properties{wobjectId};
	delete $properties{wobjectId};
	my $cmd = "WebGUI::Wobject::".$properties{namespace};
        my $w = eval{$cmd->new({namespace=>$properties{namespace},wobjectId=>"new"})};
        if ($@) {
        	WebGUI::ErrorHandler::warn("Couldn't duplicate wobject ".$properties{namespace}." because: ".$@);
	}
	$w->set(\%properties);
	WebGUI::MetaData::MetaDataDuplicate($orginalWid, $w->get("wobjectId"));
        return $w->get("wobjectId");
}

#-------------------------------------------------------------------

=head2 fileProperty ( name, labelId )

Returns a file property form row which can be used in any Wobject properties page. 

B<NOTE:> This method is meant for use with www_deleteFile.

=head3 name

The name of the property that stores the filename.

=head3 labelId

The internationalId of the form label for this file.

=cut

sub fileProperty {
        my ($self, $f, $labelId, $name);
	$self = shift;
        $name = shift;
        $labelId = shift;
        $f = WebGUI::HTMLForm->new;
        if ($self->get($name) ne "") {
                $f->readOnly('<a href="'.WebGUI::URL::page('func=deleteFile&file='.$name.'&wid='.$self->get("wobjectId")).'">'.
                        WebGUI::International::get(391).'</a>',
			WebGUI::International::get($labelId,$self->get("namespace")));
        } else {
                $f->file($name,WebGUI::International::get($labelId,$self->get("namespace")));
        }
        return $f->printRowsOnly;
}

#-------------------------------------------------------------------

=head2 get ( [ propertyName ] )

Returns a hash reference containing all of the properties of this wobject instance.

=head3 propertyName

If an individual propertyName is specified, then only that property value is returned as a scalar.

=cut

sub get {
        if ($_[1] ne "") {
                return $_[0]->{_property}{$_[1]};
        } else {
                return $_[0]->{_property};
        }
}


#-------------------------------------------------------------------

=head2 getCollateral ( tableName, keyName, keyValue ) 

Returns a hash reference containing a row of collateral data.

=head3 tableName

The name of the table you wish to retrieve the data from.

=head3 keyName

The name of the column that is the primary key in the table.

=head3 keyValue

An integer containing the key value. If key value is equal to "new" or null, then an empty hashRef containing only keyName=>"new" will be returned to avoid strict errors.

=cut

sub getCollateral {
	my ($class, $tableName, $keyName, $keyValue) = @_;
	if ($keyValue eq "new" || $keyValue eq "") {
		return {$keyName=>"new"};
	} else {
		return WebGUI::SQL->quickHashRef("select * from $tableName where $keyName=".quote($keyValue),WebGUI::SQL->getSlave);
	}
}


#-------------------------------------------------------------------

=head2 getDefaultValue ( propertyName )

Returns the default value for a wobject property.

=head3 propertyName

The name of the property to retrieve the default value for.

=cut

sub getDefaultValue {
	if (exists $_[0]->{_extendedProperties}{$_[1]}{defaultValue}) {
		return $_[0]->{_extendedProperties}{$_[1]}{defaultValue};
	} elsif (exists $_[0]->{_wobjectProperties}{$_[1]}{defaultValue}) {
		return $_[0]->{_wobjectProperties}{$_[1]}{defaultValue};
	} else {
		return undef;
	}
}


#-------------------------------------------------------------------

=head2 getIndexerParams ( )

Override this method and return a hash reference that includes the properties necessary to index the content of the wobject.

=cut

sub getIndexerParams {
	return {};
}

#-------------------------------------------------------------------

=head2 getValue ( propertyName )

Returns a value for a wobject property however possible. It first looks in form variables for the property, then looks to the value stored in the wobject instance, and if all else fails it returns the default value for the property.

=head3 propertyName

The name of the property to retrieve the value for.

=cut

sub getValue {
	my $currentValue = $_[0]->get($_[1]);
	if (exists $session{form}{$_[1]}) {
		return $session{form}{$_[1]};
	} elsif (defined $currentValue) {
		return $_[0]->get($_[1]);
	} else {
		return $_[0]->getDefaultValue($_[1]);
	}
}



#-------------------------------------------------------------------

=head2 i18n ( id [, namespace ]) {

Returns an internationalized message.

=head3 id

The identifier for the internationalized message.

=head3 namespace

The namespace for the internationalized message. Defaults to the namespace of the wobject.

=cut

sub i18n {
	my $self = shift;
	my $id = shift;
	my $namespace = shift || $self->get("namespace");
	return WebGUI::International::get($id,$namespace);
}

#-------------------------------------------------------------------

=head2 inDateRange ( )

Returns a boolean value of whether the wobject should be displayed based upon it's start and end dates.

=cut

sub inDateRange {
	if ($_[0]->get("startDate") < time() && $_[0]->get("endDate") > time()) {
		return 1;
	} else {
		return 0;
	}
}

#-------------------------------------------------------------------
                                                                                                                             
=head2 logView ( )
              
Logs the view of the wobject to the passive profiling mechanism.                                                                                                               
=cut

sub logView {
	my $self = shift;
	WebGUI::PassiveProfiling::add($self->get("wobjectId"));
	return;
}

#-------------------------------------------------------------------

=head2 moveCollateralDown ( tableName, idName, id [ , setName, setValue ] )

Moves a collateral data item down one position. This assumes that the collateral data table has a column called "wobjectId" that identifies the wobject, and a column called "sequenceNumber" that determines the position of the data item.

=head3 tableName

A string indicating the table that contains the collateral data.

=head3 idName

A string indicating the name of the column that uniquely identifies this collateral data item.

=head3 id

An integer that uniquely identifies this collateral data item.

=head3 setName

By default this method assumes that the collateral will have a wobject id in the table. However, since there is not always a wobject id to separate one data set from another, you may specify another field to do that.

=head3 setValue

The value of the column defined by "setName" to select a data set from.

=cut

### NOTE: There is a redundant use of wobjectId in some of these statements on purpose to support
### two different types of collateral data.

sub moveCollateralDown {
        my ($id, $seq, $setName, $setValue);
	$setName = $_[4] || "wobjectId";
        $setValue = $_[5];
	unless (defined $setValue) {
		$setValue = $_[0]->get($setName);
	}
        ($seq) = WebGUI::SQL->quickArray("select sequenceNumber from $_[1] where $_[2]=".quote($_[3])." and $setName=".quote($setValue));
        ($id) = WebGUI::SQL->quickArray("select $_[2] from $_[1] where $setName=".quote($setValue)." and sequenceNumber=$seq+1");
        if ($id ne "") {
                WebGUI::SQL->write("update $_[1] set sequenceNumber=sequenceNumber+1 where $_[2]=".quote($_[3])." and $setName=" .quote($setValue));
                WebGUI::SQL->write("update $_[1] set sequenceNumber=sequenceNumber-1 where $_[2]=".quote($id)." and $setName=" .quote($setValue));
         }
}

#-------------------------------------------------------------------

=head2 moveCollateralUp ( tableName, idName, id [ , setName, setValue ] )

Moves a collateral data item up one position. This assumes that the collateral data table has a column called "wobjectId" that identifies the wobject, and a column called "sequenceNumber" that determines the position of the data item.

=head3 tableName

A string indicating the table that contains the collateral data.

=head3 idName

A string indicating the name of the column that uniquely identifies this collateral data item.

=head3 id

An integer that uniquely identifies this collateral data item.

=head3 setName

By default this method assumes that the collateral will have a wobject id in the table. However, since there is not always a wobject id to separate one data set from another, you may specify another field to do that.

=head3 setValue

The value of the column defined by "setName" to select a data set from.

=cut

### NOTE: There is a redundant use of wobjectId in some of these statements on purpose to support
### two different types of collateral data.

sub moveCollateralUp {
        my ($id, $seq, $setValue, $setName);
        $setName = $_[4] || "wobjectId";
        $setValue = $_[5];
	unless (defined $setValue) {
		$setValue = $_[0]->get($setName);
	}
        ($seq) = WebGUI::SQL->quickArray("select sequenceNumber from $_[1] where $_[2]=".quote($_[3])." and $setName=".quote($setValue));
        ($id) = WebGUI::SQL->quickArray("select $_[2] from $_[1] where $setName=".quote($setValue)
		." and sequenceNumber=$seq-1");
        if ($id ne "") {
                WebGUI::SQL->write("update $_[1] set sequenceNumber=sequenceNumber-1 where $_[2]=".quote($_[3])." and $setName="
			.quote($setValue));
                WebGUI::SQL->write("update $_[1] set sequenceNumber=sequenceNumber+1 where $_[2]=".quote($id)." and $setName="
			.quote($setValue));
        }
}

#-------------------------------------------------------------------

=head2 name ( )

This method should be overridden by all wobjects and should return an internationalized human friendly name for the wobject. This method only exists in the super class for reverse compatibility and will try to look up the name based on the old name definition.

=cut

sub name {
	my $namespace = $_[0]->get("namespace");
	if ($namespace eq "") {
		WebGUI::ErrorHandler::warn("No namespace available in this wobject instance.");
		return "! Unknown Wobject !";
	} else {
		my $cmd = "\$WebGUI::Wobject::".$namespace."::name";
		my $name = eval($cmd);
		if ($name eq "") {
			WebGUI::ErrorHandler::warn($namespace." does not appear to have any sort of name definition at all.");
			return $namespace;
		}
		return $name;
	}
} 


#-------------------------------------------------------------------

=head2 namespace ( )

Returns the namespace of this wobject. This is a shortcut for $self->get("namespace");

=cut

sub namespace {
	my $self = shift;
	return $self->get("namespace");
}


#-------------------------------------------------------------------

=head2 new ( -properties, -extendedProperties [, -useDiscussion , -useTemplate , -useMetaData ] )

Constructor.

B<NOTE:> This method should never need to be overridden or extended.

=head3 -properties

A hash reference containing at minimum "wobjectId" and "namespace". wobjectId may be set to "new" if you're creating a new instance. This hash reference should be the one created by WebGUI.pm and passed to the wobject subclass.

B<NOTE:> It may seem a little weird that the initial data for the wobject instance is coming from WebGUI.pm, but this was done to lessen database traffic thus increasing the speed of all wobjects.

=head3 -extendedProperties

A hash reference containing the properties that extend the wobject class. They should match the properties that are added to this wobject's namespace table in the database. So if this wobject has a namespace of "MyWobject" and a table definition that looks like this:

 create MyWobject (
	wobjectId int not null primary key,
	something varchar(25),
	isCool int not null default 0,
	foo int not null default 1,
	bar text
 );

Then the extended property list would be:
 	{
 		something=>{
			fieldType=>"text"
			},
		isCool=>{
			fieldType=>"yesNo",
			defaultValue=>1
			},
		counter=>{
			fieldType=>"integer",
			defaultValue=>1,
			autoIncrement=>1
			},
		someId=>{
			autoId=>1
			},
		foo=>{
			fieldType=>"integer",
			defaultValue=>1
			},
		bar=>{
			fieldType=>"textarea"
			}
 	}

B<NOTE:> This is used to define the wobject and should only be passed in by a wobject subclass.

=head3 -useDiscussion

Defaults to "0". If set to "1" this will add a discussion properties tab to this wobject to enable content managers to set the properties of a discussion attached to this wobject.

B<NOTE:> This is used to define the wobject and should only be passed in by a wobject subclass.

=head3 -useTemplate

Defaults to "0". If set to "1" this will add a template field to the wobject to enable content managers to select a template to layout this wobject.

=head3 -useMetaData
                                                                                                                             
Defaults to "0". If set to "1" this will add a Metadata properties tab to this wobject to enable content managers to set Metadata values.

B<NOTE:> This is used to define the wobject and should only be passed in by a wobject subclass.

=cut

sub new {
	my ($self, @p) = @_;
 	my ($properties, $extendedProperties, $useTemplate, $useDiscussion, $useMetaData);
	if (ref $_[1] eq "HASH") {
		$properties = $_[1]; # reverse compatibility prior to 5.2
	} else {
		($properties, $extendedProperties, $useDiscussion, $useTemplate, $useMetaData) = 
			rearrange([qw(properties extendedProperties useDiscussion useTemplate useMetaData)], @p);
	} 
	$useDiscussion = 0 unless ($useDiscussion);
	$useTemplate = 0 unless ($useTemplate);
	$useMetaData = 0 unless ($useMetaData && $session{setting}{metaDataEnabled});
	my $wobjectProperties = {
		userDefined1=>{
			fieldType=>"text"
		},
		userDefined2=>{
			fieldType=>"text"
			}, 
		userDefined3=>{
			fieldType=>"text"
			}, 
		userDefined4=>{
			fieldType=>"text"
			}, 
		userDefined5=>{
			fieldType=>"text"
			}, 
		bufferUserId=>{
			fieldType=>"hidden"
			}, 
		bufferDate=>{
			fieldType=>"hidden"
			}, 
		bufferPrevId=>{
			fieldType=>"hidden"
			}, 
		forumId=>{
			fieldType=>"hidden"
			},
		allowDiscussion=>{
			fieldType=>"yesNo",
			defaultValue=>0
			},
		title=>{
			fieldType=>"text",
			defaultValue=>$_[0]->get("namespace")
			}, 
		templateId=>{
			fieldType=>"template",
			defaultValue=>1
			},
		displayTitle=>{
			fieldType=>"yesNo",
			defaultValue=>1
			}, 
		description=>{
			fieldType=>"textarea",
			fieldType=>"HTMLArea"
			},
 		pageId=>{
			fieldType=>"hidden",
			defaultValue=>$session{page}{pageId}
			}, 
		templatePosition=>{
			fieldType=>"selectList",
			defaultValue=>1
			}, 
		startDate=>{
			defaultValue=>$session{page}{startDate},
			fieldType=>"dateTime"
			},
		endDate=>{
			defaultValue=>$session{page}{endDate},
			fieldType=>"dateTime"
			},
		ownerId=>{
		    defaultValue=>$session{page}{ownerId},
			fieldType=>"group" 
		    }, 
		groupIdView=>{
		    defaultValue=>$session{page}{groupIdView},
			fieldType=>"group" 
		    }, 
		groupIdEdit=>{
		    defaultValue=>$session{page}{groupIdEdit},
			fieldType=>"group" 
		    }, 
		sequenceNumber=>{
			fieldType=>"hidden"
			}
		};
	my %fullProperties;
	my $extra;
	unless ($properties->{wobjectId} eq "new") {
		$extra = WebGUI::SQL->quickHashRef("select * from ".$properties->{namespace}." where wobjectId=".quote($properties->{wobjectId}),WebGUI::SQL->getSlave);
	}
        tie %fullProperties, 'Tie::CPHash';
        %fullProperties = (%{$properties},%{$extra});
        bless({
		_property=>\%fullProperties, 
		_useTemplate=>$useTemplate,
		_useDiscussion=>$useDiscussion,
		_useMetaData=>$useMetaData,
		_wobjectProperties=>$wobjectProperties,
		_extendedProperties=>$extendedProperties
		}, 
		$self);
}

#-------------------------------------------------------------------

=head2 processMacros ( output )

 Decides whether or not macros should be processed and returns the
 appropriate output.

=head3 output

 An HTML blob to be processed for macros.

=cut

sub processMacros {
	return WebGUI::Macro::process($_[1]);
}

#-------------------------------------------------------------------

=head2 processTemplate ( templateId, vars [ , namespace ] ) 

Returns the content generated from this template.

B<NOTE:> Only for use in wobjects that support templates.

=head3 templateId

An id referring to a particular template in the templates table.

=head3 hashRef

A hash reference containing variables and loops to pass to the template engine.

=head3 namespace

A namespace to use for the template. Defaults to the wobject's namespace.

=cut

sub processTemplate {
	my $self = shift;
	my $templateId = shift;
	my $var = shift;
	my $namespace = shift || $self->get("namespace");
	if ($self->{_useMetaData}) {
                my $meta = WebGUI::MetaData::getMetaDataFields($self->get("wobjectId"));
                foreach my $field (keys %$meta) {
			$var->{$meta->{$field}{fieldName}} = $meta->{$field}{value};
		}
	}
	my %vars = (
		%{$self->{_property}},
		%{$var}
		);
	if (defined $self->get("_WobjectProxy")) {
		$vars{isShortcut} = 1;
		my ($originalPageURL) = WebGUI::SQL->quickArray("select urlizedTitle from page where pageId=".quote($self->get("pageId")),WebGUI::SQL->getSlave);
		$vars{originalURL} = WebGUI::URL::gateway($originalPageURL."#".$self->get("wobjectId"));
	}
	return WebGUI::Template::process($templateId,$namespace, \%vars);
}

#-------------------------------------------------------------------

=head2 purge ( )

Removes this wobject from the database and all it's attachments from the filesystem.

B<NOTE:> This method is meant to be extended by all sub-classes.

=cut

sub purge {
	if ($_[0]->get("forumId")) {
		my ($inUseElsewhere) = WebGUI::SQL->quickArray("select count(*) from wobject where forumId=".quote($_[0]->get("forumId")));
                unless ($inUseElsewhere > 1) {
			my $forum = WebGUI::Forum->new($_[0]->get("forumId"));
			$forum->purge;
		}
	}
	WebGUI::SQL->write("delete from ".$_[0]->get("namespace")." where wobjectId=".quote($_[0]->get("wobjectId")));
        WebGUI::SQL->write("delete from wobject where wobjectId=".quote($_[0]->get("wobjectId")));
	WebGUI::MetaData::metaDataDelete($_[0]->get("wobjectId"));
	my $node = WebGUI::Node->new($_[0]->get("wobjectId"));
	$node->delete;
}


#-------------------------------------------------------------------

=head2 reorderCollateral ( tableName, keyName [ , setName, setValue ] )

Resequences collateral data. Typically useful after deleting a collateral item to remove the gap created by the deletion.

=head3 tableName

The name of the table to resequence.

=head3 keyName

The key column name used to determine which data needs sorting within the table.

=head3 setName

Defaults to "wobjectId". This is used to define which data set to reorder.

=head3 setValue

Used to define which data set to reorder. Defaults to the wobjectId for this instance. Defaults to the value of "setName" in the wobject properties.

=cut

sub reorderCollateral {
        my ($sth, $i, $id, $setName, $setValue);
	$i = 1;
	$setName = $_[3] || "wobjectId";
	$setValue = $_[4] || $_[0]->get($setName);
        $sth = WebGUI::SQL->read("select $_[2] from $_[1] where $setName=".quote($setValue)." order by sequenceNumber");
        while (($id) = $sth->array) {
                WebGUI::SQL->write("update $_[1] set sequenceNumber=$i where $setName=".quote($setValue)." and $_[2]=".quote($id));
                $i++;
        }
        $sth->finish;
}



#-------------------------------------------------------------------

=head2 set ( [ hashRef ] )

Stores the values specified in hashRef to the database.

=head3 hashRef 

A hash reference of the properties to set for this wobject instance. 

=cut

sub set {
	my ($key, $sql, @update, $i);
	my $self = shift;
	my $properties = shift;
	my $extendedProperties = shift; # shift for backward compatibility.
	unless (defined $extendedProperties) {
		my @temp;
		foreach (keys %{$self->{_extendedProperties}}) {
			push(@temp,$_);
		}
		$extendedProperties = \@temp;
	}
	my @temp;
        foreach (keys %{$self->{_wobjectProperties}}) {
        	push(@temp,$_);
        }
        my $wobjectProperties = \@temp;
	if ($self->{_property}{wobjectId} eq "new") {
		$self->{_property}{wobjectId} = WebGUI::Id::generate();
		$self->{_property}{pageId} = ${$_[1]}{pageId} || $session{page}{pageId};
		$self->{_property}{sequenceNumber} = _getNextSequenceNumber($self->{_property}{pageId});
		$self->{_property}{addedBy} = $session{user}{userId};
		$self->{_property}{dateAdded} = time();
		WebGUI::SQL->write("insert into wobject 
			(wobjectId, namespace, dateAdded, addedBy, sequenceNumber, pageId) 
			values (
			".quote($self->{_property}{wobjectId}).", 
			".quote($self->{_property}{namespace}).",
			".$self->{_property}{dateAdded}.",
			".quote($self->{_property}{addedBy}).",
			".$self->{_property}{sequenceNumber}.",
			".quote($self->{_property}{pageId})."
			)");
		WebGUI::SQL->write("insert into ".$self->{_property}{namespace}." (wobjectId) 
			values (".quote($self->{_property}{wobjectId}).")");
		foreach my $key (keys %{$self->{_extendedProperties}}) {
			if ($self->{_extendedProperties}{$key}{autoIncrement}) {
				$properties->{$key} = getNextId($key);
			}
			if ($self->{_extendedProperties}{$key}{autoId}) {
				$properties->{$key} = WebGUI::Id::generate();
			}
		}
	}
	$self->{_property}{lastEdited} = time();
	$self->{_property}{editedBy} = $session{user}{userId};
	$sql = "update wobject set";
	foreach $key (keys %{$properties}) {
		$self->{_property}{$key} = ${$properties}{$key};
		if (isIn($key, @{$wobjectProperties})) {
        		$sql .= " ".$key."=".quote(${$properties}{$key}).",";
		}
                if (isIn($key, @{$extendedProperties})) {
                        $update[$i] .= " ".$key."=".quote($properties->{$key});
                        $i++;
                }
	}
	$sql .= " lastEdited=".$self->{_property}{lastEdited}.", 
		editedBy=".quote($self->{_property}{editedBy})." 
		where wobjectId=".quote($self->{_property}{wobjectId});
	WebGUI::SQL->write($sql);
	if (@update) {
        	WebGUI::SQL->write("update ".$self->{_property}{namespace}." set ".join(",",@update)." 
			where wobjectId=".quote($self->{_property}{wobjectId}));
	}
	WebGUI::ErrorHandler::audit("edited Wobject ".$self->{_property}{wobjectId});	
}


#-----------------------------------------------------------------

=head2 setCollateral ( tableName, keyName, properties [ , useSequenceNumber, useWobjectId, setName, setValue ] )

Performs and insert/update of collateral data for any wobject's collateral data. Returns the primary key value for that row of data.

=head3 tableName

The name of the table to insert the data.

=head3 keyName

The column name of the primary key in the table specified above.  This must also be an incrementerId in the incrementer table.

=head3 properties

A hash reference containing the name/value pairs to be inserted into the database where the name is the column name. Note that the primary key should be specified in this list, and if it's value is "new" or null a new row will be created.

=head3 useSequenceNumber

If set to "1", a new sequenceNumber will be generated and inserted into the row. Note that this means you must have a sequenceNumber column in the table. Also note that this requires the presence of the wobjectId column. Defaults to "1".

=head3 useWobjectId

If set to "1", the current wobjectId will be inserted into the table upon creation of a new row. Note that this means the table better have a wobjectId column. Defaults to "1".  

=head3 setName

If this collateral data set is not grouped by wobjectId, but by another column then specify that column here. The useSequenceNumber parameter will then use this column name instead of wobjectId to generate the sequenceNumber.

=head3 setValue

If you've specified a setName you may also set a value for that set.  Defaults to the value for this id from the wobject properties.

=cut

sub setCollateral {
	my ($key, $sql, $seq, $dbkeys, $dbvalues, $counter);
	my ($class, $table, $keyName, $properties, $useSequence, $useWobjectId, $setName, $setValue) = @_;
	$counter = 0;
	$setName = $setName || "wobjectId";
	$setValue = $setValue || $_[0]->get($setName);
	if ($properties->{$keyName} eq "new" || $properties->{$keyName} eq "") {
		$properties->{$keyName} = WebGUI::Id::generate();
		$sql = "insert into $table (";
		$dbkeys = "";
     		$dbvalues = "";
		unless ($useSequence eq "0") {
			unless (exists $properties->{sequenceNumber}) {
				($seq) = WebGUI::SQL->quickArray("select max(sequenceNumber) from $table 
                               		where $setName=".quote($setValue));
				$properties->{sequenceNumber} = $seq+1;
			}
		} 
		unless ($useWobjectId eq "0") {
			$properties->{wobjectId} = $_[0]->get("wobjectId");
		}
		foreach $key (keys %{$properties}) {
			if ($counter++ > 0) {
				$dbkeys .= ',';
				$dbvalues .= ',';
			}
			$dbkeys .= $key;
			$dbvalues .= quote($properties->{$key});
		}
		$sql .= $dbkeys.') values ('.$dbvalues.')';
		WebGUI::ErrorHandler::audit("added ".$table." ".$properties->{$keyName});
	} else {
		$sql = "update $table set ";
		foreach $key (keys %{$properties}) {
			unless ($key eq "sequenceNumber") {
				$sql .= ',' if ($counter++ > 0);
				$sql .= $key."=".quote($properties->{$key});
			}
		}
		$sql .= " where $keyName=".quote($properties->{$keyName});
		WebGUI::ErrorHandler::audit("edited ".$table." ".$properties->{$keyName});
	}
  	WebGUI::SQL->write($sql);
	$_[0]->{_property}{lastEdited} = time();
        $_[0]->{_property}{editedBy} = $session{user}{userId};
	WebGUI::SQL->write("update wobject set lastEdited=".$_[0]->{_property}{lastEdited}
		.", editedBy=".quote($_[0]->{_property}{editedBy})." where wobjectId=".quote($_[0]->wid));
	$_[0]->reorderCollateral($table,$keyName,$setName,$setValue) if ($properties->{sequenceNumber} < 0);
	return $properties->{$keyName};
}


#-------------------------------------------------------------------

=head2 uiLevel

Returns the UI Level of a wobject. Defaults to "0" for all wobjects.  Override to set the UI Level higher for a given wobject.

=cut

sub uiLevel {
	return 0;
}

#-------------------------------------------------------------------

=head2 wid ( )

Returns the wobject id of this wobject. This is a shortcut for $self->get("wobjectId");

=cut

sub wid {
	my $self = shift;
	return $self->get("wobjectId");
}

#-------------------------------------------------------------------

=head2 www_copy ( )

Copies this instance to the clipboard.

B<NOTE:> Should never need to be overridden or extended.

=cut

sub www_copy {
	my $self = shift;
        return WebGUI::Privilege::insufficient() unless ($self->canEdit);
        $self->duplicate;
        return "";
}

#-------------------------------------------------------------------

=head2 www_createShortcut ( )

Creates a shortcut (using the wobject proxy) of this wobject on the clipboard.

B<NOTE:> Should never need to be overridden or extended.

=cut

sub www_createShortcut {
	my $self = shift;
        return WebGUI::Privilege::insufficient() unless ($self->canEdit);
	my $w = WebGUI::Wobject::WobjectProxy->new({wobjectId=>"new",namespace=>"WobjectProxy"});
	$w->set({
		pageId=>2,
		templatePosition=>1,
		title=>$self->getValue("title"),
		proxiedNamespace=>$self->get("namespace"),
		proxiedWobjectId=>$self->get("wobjectId"),
	    	bufferUserId=>$session{user}{userId},
		bufferDate=>WebGUI::DateTime::time(),
		bufferPrevId=>$session{page}{pageId}
		});
        return "";
}

#-------------------------------------------------------------------

=head2 www_cut ( )

Moves this instance to the clipboard.

=cut

sub www_cut {
	my $self = shift;
        return WebGUI::Privilege::insufficient() unless ($self->canEdit);
	$self->set({
		pageId=>2, 
		templatePosition=>1,
	    	bufferUserId=>$session{user}{userId},
		bufferDate=>WebGUI::DateTime::time(),
		bufferPrevId=>$session{page}{pageId}
		});
	_reorderWobjects($session{page}{pageId});
        return "";
}

#-------------------------------------------------------------------

=head2 www_delete ( )

Prompts a user to confirm whether they wish to delete this instance.

=cut

sub www_delete {
	my $self = shift;
        my ($output);
        if ($self->canEdit) {
                $output = helpIcon("wobject delete");
		$output .= '<h1>'.WebGUI::International::get(42).'</h1>';
                $output .= WebGUI::International::get(43);
		$output .= '<p>';
                $output .= '<div align="center"><a href="'.WebGUI::URL::page('func=deleteConfirm&wid='.
			$self->get("wobjectId")).'">';
		$output .= WebGUI::International::get(44); 
		$output .= '</a>';
                $output .= '&nbsp;&nbsp;&nbsp;&nbsp;<a href="'.WebGUI::URL::page().'">';
		$output .= WebGUI::International::get(45);
		$output .= '</a></div>';
                return $output;
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------

=head2  www_deleteConfirm ( )

Moves this instance to the trash.

=cut

sub www_deleteConfirm {
	my $self = shift;
        if ($self->canEdit) {
		$self->set({pageId=>3, templatePosition=>1,
                        bufferUserId=>$session{user}{userId},
                        bufferDate=>WebGUI::DateTime::time(),
                        bufferPrevId=>$session{page}{pageId}});
		WebGUI::ErrorHandler::audit("moved Wobject ".$self->{_property}{wobjectId}." to the trash.");
		_reorderWobjects($self->get("pageId"));
                return "";
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------

=head2 www_deleteFile ( )

Displays a confirmation message relating to the deletion of a file.

=cut

sub www_deleteFile {
	my $self = shift;
	return WebGUI::Privilege::insufficient() unless ($self->canEdit);
        return $self->confirm(WebGUI::International::get(728),
                WebGUI::URL::page('func=deleteFileConfirm&wid='.$self->get("wobjectId").'&file='.$session{form}{file}),
                WebGUI::URL::page('func=edit&wid='.$self->get("wobjectId"))
                );
}

#-------------------------------------------------------------------

=head2 www_deleteFileConfirm ( )

Deletes a file from this instance.

=cut

sub www_deleteFileConfirm {
	my $self = shift;
	return WebGUI::Privilege::insufficient() unless ($self->canEdit);
        $self->set({$session{form}{file}=>''});
        return $self->www_edit();
}

#-------------------------------------------------------------------

=head2 www_edit ( [ -properties, -layout, -privileges, -helpId, -heading, -headingId ] ) 

Displays the common properties of any/all wobjects. 

=head3 -properties, -layout, -privileges 

WebGUI::HTMLForm objects that extend these tabs.

=head3 -helpId

An id in this namespace in the WebGUI help system for this edit page. If specified a help link will be created on the edit page.

=head3 -heading

A text string to put in the heading of this page.

=head3 -headingId

An id this namespace of the WebGUI international system. This message will be retrieved and displayed in the heading of this edit page.

=cut

sub www_edit {
	my $self = shift;
	return WebGUI::Privilege::insufficient() unless ($self->canEdit);
	$session{page}{useAdminStyle} = 1;
	my (@p) = @_;
        my ($properties, $layout, $privileges, $heading, $helpId, $headingId) = 
		rearrange([qw(properties layout privileges heading helpId headingId)], @p);
        my ($f, $startDate, $displayTitle, $templatePosition, $endDate);
        if ($self->get("wobjectId") eq "new") {
               	$displayTitle = 1;
        } else {
        	$displayTitle = $self->get("displayTitle");
        }
	my $title = $self->get("title") || $self->name;
	$templatePosition = $self->get("templatePosition") || 1;
	$startDate = $self->get("startDate") || $session{page}{startDate};
	$endDate = $self->get("endDate") || $session{page}{endDate};
	my %tabs;
	tie %tabs, 'Tie::IxHash';
	%tabs = (	
		properties=>{
			label=>WebGUI::International::get(893)
			},
		layout=>{
                        label=>WebGUI::International::get(105),
                        uiLevel=>5
                        },
                privileges=>{
                        label=>WebGUI::International::get(107),
                        uiLevel=>6
                        }
		);
	if ($self->{_useDiscussion}) {
		$tabs{discussion} = {
			label=>WebGUI::International::get(892),
			uiLevel=>5
			};
	}
	if($self->{_useMetaData}) {
		$tabs{metadata} = {
			label=>WebGUI::International::get('Metadata','MetaData'),
			uiLevel=>5
			};
	}
	$f = WebGUI::TabForm->new(\%tabs);
	$f->hidden({name=>"wid",value=>$self->get("wobjectId")});
	$f->hidden({name=>"namespace",value=>$self->get("namespace")}) if ($self->get("wobjectId") eq "new");
	$f->hidden({name=>"func",value=>"editSave"});
	$f->getTab("properties")->readOnly(
		-value=>$self->get("wobjectId"),
		-label=>WebGUI::International::get(499),
		-uiLevel=>3
		);
	$f->getTab("properties")->text("title",WebGUI::International::get(99),$title);
	$f->getTab("layout")->yesNo(
		-name=>"displayTitle",
		-label=>WebGUI::International::get(174),
		-value=>$displayTitle,
		-uiLevel=>5
		);
	if ($self->{_useTemplate}) {
		$f->getTab("layout")->template(
                	-value=>$self->getValue("templateId"),
                	-namespace=>$self->get("namespace"),
                	-afterEdit=>'func=edit&amp;wid='.$self->get("wobjectId")."&amp;namespace=".$self->get("namespace")
                	);
	}
	$f->getTab("layout")->selectList(
		-name=>"templatePosition",
		-label=>WebGUI::International::get(363),
		-value=>[$templatePosition],
		-uiLevel=>5,
		-options=>WebGUI::Page::getTemplatePositions($session{page}{templateId}),
		-subtext=>WebGUI::Page::drawTemplate($session{page}{templateId})
		);
	$f->getTab("privileges")->dateTime(
		-name=>"startDate",
		-label=>WebGUI::International::get(497),
		-value=>$startDate,
		-uiLevel=>6
		);
	$f->getTab("privileges")->dateTime(
		-name=>"endDate",
		-label=>WebGUI::International::get(498),
		-value=>$endDate,
		-uiLevel=>6
		);
	my $subtext;
	if (WebGUI::Grouping::isInGroup(3)) {
		$subtext = ' &nbsp; <a href="'.WebGUI::URL::page('op=listUsers').'">'.WebGUI::International::get(7).'</a>';
	} else {
	   $subtext = "";
    	}
	if ($session{page}{wobjectPrivileges}) {
	    	my $clause; 
		if (WebGUI::Grouping::isInGroup(3)) {
	   		my $contentManagers = WebGUI::Grouping::getUsersInGroup(4,1);
		   	push (@$contentManagers, $session{user}{userId});
		   	$clause = "userId in (".quoteAndJoin($contentManagers).")";
	    	} else {
		   	$clause = "userId=".quote($self->getValue("ownerId"));
	    	}
		my $users = WebGUI::SQL->buildHashRef("select userId,username from users where $clause order by username");
		$f->getTab("privileges")->selectList(
		   -name=>"ownerId",
		   -options=>$users,
		   -label=>WebGUI::International::get(108),
		   -value=>[$self->getValue("ownerId")],
		   -subtext=>$subtext,
		   -uiLevel=>6
		);
		if (WebGUI::Grouping::isInGroup(3)) {
		   $subtext = ' &nbsp; <a href="'.WebGUI::URL::page('op=listGroups').'">'.WebGUI::International::get(5).'</a>';
		} else {
		   $subtext = "";
		}
		$f->getTab("privileges")->group(
			-name=>"groupIdView",
			-label=>WebGUI::International::get(872),
			-value=>[$self->getValue("groupIdView")],
			-subtext=>$subtext,
			-uiLevel=>6
		);
	    	$f->getTab("privileges")->group(
        		-name=>"groupIdEdit",
	        	-label=>WebGUI::International::get(871),
	        	-value=>[$self->getValue("groupIdEdit")],
		        -subtext=>$subtext,
	    		-excludeGroups=>[1,7],
	        	-uiLevel=>6
   		);
	} else {
		$f->hidden({name=>"ownerId",value=>$self->getValue("ownerId")});
		$f->hidden({name=>"groupIdView",value=>$self->getValue("groupIdView")});
		$f->hidden({name=>"groupIdEdit",value=>$self->getValue("groupIdEdit")});
	}
	$f->getTab("properties")->HTMLArea(
		-name=>"description",
		-label=>WebGUI::International::get(85),
		-value=>$self->get("description")
		);
	$f->getTab("properties")->raw($properties);
	$f->getTab("layout")->raw($layout);
	$f->getTab("privileges")->raw($privileges);
	if ($self->{_useDiscussion}) {
		$f->getTab("discussion")->yesNo(
                	-name=>"allowDiscussion",
                	-label=>WebGUI::International::get(894),
                	-value=>$self->get("allowDiscussion"),
                	-uiLevel=>5
                	);
		$f->getTab("discussion")->raw(WebGUI::Forum::UI::forumProperties($self->get("forumId")));
	}
	if ($self->{_useMetaData}) {
		my $meta = WebGUI::MetaData::getMetaDataFields($self->get("wobjectId"));
		foreach my $field (keys %$meta) {
			my $fieldType = $meta->{$field}{fieldType} || "text";
			my $options;
			# Add a "Select..." option on top of a select list to prevent from
			# saving the value on top of the list when no choice is made.
			if($fieldType eq "selectList") {
				$options = {"", WebGUI::International::get("Select...","MetaData")};
			}
			$f->getTab("metadata")->dynamicField($fieldType,
						-name=>"metadata_".$meta->{$field}{fieldId},
						-label=>$meta->{$field}{fieldName},
						-uiLevel=>5,
						-value=>$meta->{$field}{value},
						-extras=>qq/title="$meta->{$field}{description}"/,
						-possibleValues=>$meta->{$field}{possibleValues},
						-options=>$options
				);
        	}
		# Add a quick link to add field
		$f->getTab("metadata")->readOnly(
					-value=>'<p><a href="'.WebGUI::URL::page("op=editMetaDataField&fid=new").'">'.
				                        WebGUI::International::get('Add new field','MetaData').
     					                '</a></p>'
		);
	}
	my $output;
	$output = helpIcon($helpId,$self->get("namespace")) if ($helpId);
	$heading = WebGUI::International::get($headingId,$self->get("namespace")) if ($headingId);
        $output .= '<h1>'.$heading.'</h1>' if ($heading);
	return $output.$f->print; 
}

#-------------------------------------------------------------------

=head2 www_editSave ( [ hashRef ] )

Saves the default properties of any/all wobjects.

B<NOTE:> This method should only need to be extended if you need to do some special validation.

=head3 hashRef

A hash reference of extra properties to set.

=cut

sub www_editSave {
	my $self = shift;
	my $extras = shift;
	return WebGUI::Privilege::insufficient() unless ($self->canEdit);
	my %set;
	foreach my $key (keys %{$self->{_wobjectProperties}}) {
		my $temp = WebGUI::FormProcessor::process(
			$key,
			$self->{_wobjectProperties}{$key}{fieldType},
			$self->{_wobjectProperties}{$key}{defaultValue}
			);
		$set{$key} = $temp if (defined $temp);
	}
	$set{title} = $session{form}{title} || $self->name;
	foreach my $key (keys %{$self->{_extendedProperties}}) {
		my $temp = WebGUI::FormProcessor::process(
			$key,
			$self->{_extendedProperties}{$key}{fieldType},
			$self->{_extendedProperties}{$key}{defaultValue}
			);
		$set{$key} = $temp if (defined $temp);
	}
	%set = (%set, %{$extras});
	$set{forumId} = WebGUI::Forum::UI::forumPropertiesSave()  if ($self->{_useDiscussion});
	$self->set(\%set);
	WebGUI::MetaData::metaDataSave($self->get("wobjectId")) if ($self->{_useMetaData});
	return "";
}

#-------------------------------------------------------------------

=head2 www_moveBottom ( )

Moves this instance to the bottom of the page.

=cut

sub www_moveBottom {
	my $self = shift;
        if ($self->canEdit) {
		$self->set({sequenceNumber=>99999});
		_reorderWobjects($self->get("pageId"));
                return "";
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------

=head2 www_moveDown ( )

Moves this instance down one spot on the page.

=cut

sub www_moveDown {
	my ($wid, $thisSeq);
	my $self = shift;
        if ($self->canEdit) {
		($thisSeq) = WebGUI::SQL->quickArray("select sequenceNumber from wobject where wobjectId=".quote($self->get("wobjectId")));
		($wid) = WebGUI::SQL->quickArray("select wobjectId from wobject where pageId=".quote($self->get("pageId"))
			." and sequenceNumber=".($thisSeq+1));
		if ($wid ne "") {
                	WebGUI::SQL->write("update wobject set sequenceNumber=sequenceNumber+1 where wobjectId=".quote($self->get("wobjectId")));
                	WebGUI::SQL->write("update wobject set sequenceNumber=sequenceNumber-1 where wobjectId=".quote($wid));
                	_reorderWobjects($self->get("pageId"));
		}
                return "";
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------

=head2 www_moveTop ( )

Moves this instance to the top of the page.

=cut

sub www_moveTop {
	my $self = shift;
        if ($self->canEdit) {
                $self->set({sequenceNumber=>0});
                _reorderWobjects($self->get("pageId"));
                return "";
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------

=head2 www_moveUp ( )

Moves this instance up one spot on the page.

=cut

sub www_moveUp {
	my $self = shift;
        my ($wid, $thisSeq);
        if ($self->canEdit) {
                ($thisSeq) = WebGUI::SQL->quickArray("select sequenceNumber from wobject where wobjectId=".quote($self->get("wobjectId")));
                ($wid) = WebGUI::SQL->quickArray("select wobjectId from wobject where pageId=".quote($self->get("pageId"))
			." and sequenceNumber=".($thisSeq-1));
                if ($wid ne "") {
                        WebGUI::SQL->write("update wobject set sequenceNumber=sequenceNumber-1 where wobjectId=".quote($self->get("wobjectId")));
                        WebGUI::SQL->write("update wobject set sequenceNumber=sequenceNumber+1 where wobjectId=".quote($wid));
                	_reorderWobjects($self->get("pageId"));
                }
                return "";
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------

=head2 www_paste ( )

Moves this instance from the clipboard to the current page.

=cut

sub www_paste {
	my $self = shift;
        my ($output, $nextSeq);
        if ($self->canEdit) {
		($nextSeq) = WebGUI::SQL->quickArray("select max(sequenceNumber) from wobject where pageId=".quote($session{page}{pageId}));
		$nextSeq += 1;
		WebGUI::SQL->write("UPDATE wobject SET "
					."pageId=".quote($session{page}{pageId}).", "
					."templatePosition=1, "
					."sequenceNumber=". $nextSeq .", "
                            		."bufferUserId=NULL, bufferDate=NULL, bufferPrevId=NULL "
					."WHERE wobjectId=".quote($self->get("wobjectId")));
                return "";
        } else {
                return WebGUI::Privilege::insufficient();
        }
}

#-------------------------------------------------------------------

=head2 www_view ( )

The default display mechanism for any wobject. This web method MUST be overridden.

=cut

sub www_view {
	my $self = shift;
	return WebGUI::Privilege::insufficient unless ($self->canView);
	return $self->displayTitle.$self->description;
}

1;

