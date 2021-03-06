package WebGUI::PassiveAnalytics::Flow;

use strict;
use WebGUI::AdminConsole;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Pluggable;
use WebGUI::PassiveAnalytics::Rule;
use WebGUI::HTMLForm;
use WebGUI::Workflow;
use WebGUI::Workflow::Instance;
use WebGUI::User;
use WebGUI::Text;
use WebGUI::Fork;

=head1 NAME

Package WebGUI::PassiveAnalytics::Flow

=head1 DESCRIPTION

Web interface for making sets of rules for doing passive analytics, and
running them.

=cut

#----------------------------------------------------------------------------

=head2 analysisActive ( session )

Returns true if an instance of the PassiveAnalytics workflow is active.

=cut

sub analysisActive {
    my $session     = shift;
    my ($running, $startDate, $endDate, $userId) = $session->db->quickArray(q!select running, startDate, endDate, userId from passiveAnalyticsStatus!);
    if (wantarray) {
        return $running, $startDate, $endDate, WebGUI::User->new($session, $userId);
    }
    return $running;
}

#----------------------------------------------------------------------------

=head2 canView ( session [, user] )

Returns true if the user can administrate this operation. user defaults to 
the current user.

=cut

sub canView {
    my $session     = shift;
    my $user        = shift || $session->user;
    return $user->isInGroup( 3 );
}

#----------------------------------------------------------------------------

=head2 exportSomething ( $process, $data )

Generates CSV data from the supplied statement handle and generates
a temporary WebGUI::Storage object containing that data in the requested
filename.

This subroutine also does a setRedirect to the URL of the file in
the storage object.

=head3 $process

A WebGUI::Fork object, to let the user know what's going on.

=head3 $data

Hash ref of data.

=head3 tableName

The name of the table where data will be pulled and translated into CSV.

=head3 filename

The name of the file to generate

=cut

sub exportSomething {
    my ($process, $data) = @_;
    my $session = $process->session;
    my $i18n = WebGUI::International->new($session, 'Asset_Thingy');
    my $storage = WebGUI::Storage->createTemp($session);
    open my $CSV, '>', $storage->getPath($data->{filename});
    my $sth = $session->db->read('select SQL_CALC_FOUND_ROWS * from '.$data->{tableName});
    my %status = (
        current  => 0,
        message  => '',
        total    => $session->db->quickScalar('select found_rows()') + 0,
    );
    my $update = sub {
        $process->update( sub { JSON::to_json(\%status) } );
    };
    $update->();
    my @columns = $sth->getColumnNames;
    print $CSV WebGUI::Text::joinCSV( @columns ). "\n";
    my $rowCounter = 0;
    $status{message} = $i18n->get('Writing data');
    $update->();
    while (my $row = $sth->hashRef()) {
        my @row = @{ $row }{@columns};
        print $CSV WebGUI::Text::joinCSV(@row) . "\n";
        ++$status{current };
        $update->();
    }
    close $CSV;
    $sth->finish;
}

#-------------------------------------------------------------------

=head2 www_deleteRule ( )

Deletes an activity from a workflow.

=cut

sub www_deleteRule {
    my $session = shift;
    return $session->privilege->insufficient() unless canView($session);
    my $rule = WebGUI::PassiveAnalytics::Rule->new($session, $session->form->get("ruleId"));
    if (defined $rule) {
        $rule->delete;
    }
    return www_editRuleflow($session);
}

#------------------------------------------------------------------

=head2 www_demoteRule ( session )

Moves a Rule down one position in the execution order.

=head3 session

A reference to the current session.

=cut

sub www_demoteRule {
	my $session = shift;
	return $session->privilege->insufficient() unless canView($session);
    my $rule = WebGUI::PassiveAnalytics::Rule->new($session, $session->form->get("ruleId"));
    if (defined $rule) {
        $rule->demote;
    }
	return www_editRuleflow($session);
}

#-------------------------------------------------------------------

=head2 www_editRuleflow ( $session, $error )

Configure a set of analyses to run on the passive logs.  The analysis is destructive.

=head3 $error

Allows another method to pass an error into this method, to display to the user.

=cut

sub www_editRuleflow {
    my $session = shift;
    my $error   = shift;
    return $session->privilege->insufficient() unless canView($session);
    my ($running, $startDate, $endDate, $user) = analysisActive($session);
    if ($error) {
        $error = qq|<div class="error">$error</div>\n|;
    }
    elsif (!$running) {
        $error = qq|<div class="error">Passive Analytics analysis completed on $endDate</div>\n|;
    }
    my $i18n = WebGUI::International->new($session, "PassiveAnalytics");
    my $addmenu = '<div style="float: left; width: 200px; font-size: 11px;">';
    $addmenu .= sprintf '<a href="%s">%s</a>',
        $session->url->page('op=passiveAnalytics;func=editRule'),
        $i18n->get('Add a bucket');
    $addmenu .= '</div>';
    my $f = WebGUI::HTMLForm->new($session);
    $f->hidden(
        name=>'op',
        value=>'passiveAnalytics'
    );
    $f->hidden(
        name=>'func',
        value=>'editRuleflowSave'
    );
    $f->integer(
        name      => 'pauseInterval',
        value     => $session->form->get('pauseInterval') || $session->setting->get('passiveAnalyticsInterval') || 300,
        label     => $i18n->get('pause interval'),
        hoverHelp => $i18n->get('pause interval help'),
    );
    if ($running) {
        $f->raw(sprintf <<EOD, $startDate, $user->username);
<tr><td colspan="2">Passive Analytics analysis is currently active.  Analysis was begun at %s by %s</td></tr>
EOD
    }
    else {
        $f->submit(value => $i18n->get('Begin analysis'));
    }
    my $steps = '<table class="content"><tbody>';
    my $getARule = WebGUI::PassiveAnalytics::Rule->getAllIterator($session);
    my $icon = $session->icon;
    while (my $rule = $getARule->()) {
        my $id     = $rule->getId;
        my $bucket = $rule->get('bucketName');
        $steps .= '<tr><td>'
               .  $icon->delete(  'op=passiveAnalytics;func=deleteRule;ruleId='.$id, undef, $i18n->get('confirm delete rule'))
               .  $icon->edit(    'op=passiveAnalytics;func=editRule;ruleId='.$id)
               .  $icon->moveDown('op=passiveAnalytics;func=demoteRule;ruleId='.$id)
               .  $icon->moveUp(  'op=passiveAnalytics;func=promoteRule;ruleId='.$id)
               .  '</td><td>'.$bucket.'</td></tr>';
               
    }
    $steps .= '<tr><td>&nbsp;</td><td>Other</td></tbody></table><div style="clear: both;"></div>';
    my $ac = WebGUI::AdminConsole->new($session,'passiveAnalytics');
    $ac->addSubmenuItem($session->url->page('op=passiveAnalytics;func=settings'), $i18n->get('Passive Analytics Settings'));
    if (!$running) {
        $ac->addSubmenuItem($session->url->page('op=passiveAnalytics;func=exportBucketData'), $i18n->get('Export bucket data'));
        $ac->addSubmenuItem($session->url->page('op=passiveAnalytics;func=exportDeltaData'), $i18n->get('Export delta data'));
        $ac->addSubmenuItem($session->url->page('op=passiveAnalytics;func=exportLogs'), $i18n->get('Export raw logs'));
    }
    return $ac->render($error.$f->print.$addmenu.$steps, 'Passive Analytics');
}

#-------------------------------------------------------------------

=head2 www_editRuleflowSave ( )

Saves the results of www_editRuleflow()

=cut

sub www_editRuleflowSave {
    my $session = shift;
    return $session->privilege->insufficient() unless canView($session);
    my $i18n = WebGUI::International->new($session, 'PassiveAnalytics');
    return www_editRuleflow($session, $i18n->get('already active'))
        if analysisActive($session);
    my $workflow = WebGUI::Workflow->new($session, 'PassiveAnalytics000001');
    return www_editRuleflow($session, $i18n->get('workflow deleted')) unless defined $workflow;
    my $delta = $session->form->process('pauseInterval','integer');
    my $activities = $workflow->getActivities();
    ##Note, they're in order, and the order is known.
    $activities->[0]->set('deltaInterval', $delta);
    $activities->[1]->set('userId', $session->user->userId);
    my $instance = WebGUI::Workflow::Instance->create($session, {
        workflowId => $workflow->getId,
        priority   => 1,
    });
    if (!defined $instance) {
        return www_editRuleflow($session, $i18n->get('currently running')) if $session->stow->get('singletonWorkflowClash');
        return www_editRuleflow($session, $i18n->get('error creating workflow'));
    }
    $instance->start('skipRealtime');
    $session->db->write('update passiveAnalyticsStatus set startDate=NOW(), userId=?, endDate=?, running=1', [$session->user->userId, '']);
    return www_editRuleflow($session);
}


#-------------------------------------------------------------------

=head2 www_editRule ( )

Displays a form to edit the properties rule.

=cut

sub www_editRule {
    my ($session, $error) = @_;
    return $session->privilege->insufficient() unless canView($session);

    if ($error) {
        $error = qq|<div class="error">$error</div>\n|;
    }
    ##Make a PassiveAnalytics rule to use to populate the form.
    my $ruleId = $session->form->get('ruleId'); 
    my $rule;
    if ($ruleId) {
        $rule = WebGUI::PassiveAnalytics::Rule->new($session, $ruleId);
    }
    else {
        ##We need a temporary rule so that we can call dynamicForm, below
        $ruleId = 'new';
        $rule = WebGUI::PassiveAnalytics::Rule->new($session, {});
    }

    ##Build the form
	my $form = WebGUI::HTMLForm->new($session);
	$form->hidden( name=>"op",     value=>"passiveAnalytics");
	$form->hidden( name=>"func",   value=>"editRuleSave");
	$form->hidden( name=>"ruleId", value=>$ruleId);
    $rule->crud_form($form, $rule);
	$form->submit;

	my $i18n = WebGUI::International->new($session, 'PassiveAnalytics');
	my $ac   = WebGUI::AdminConsole->new($session,'passiveAnalytics');
	$ac->addSubmenuItem($session->url->page("op=passiveAnalytics;func=editRuleflow"), $i18n->get("manage ruleset"));
    if ($ruleId eq 'new') {
        $rule->delete;
    }
	return $ac->render($error.$form->print,$i18n->get('Edit Rule'));
}

#-------------------------------------------------------------------

=head2 www_editRuleSave ( )

Saves the results of www_editRule().

=cut

sub www_editRuleSave {
    my $session = shift;
    my $form    = $session->form;
    return $session->privilege->insufficient() unless canView($session);
    my $regexp = $form->get('regexp');
    eval {
        'fooBarBaz' =~ qr/$regexp/;
    };
    if ($@) {
        my $error = $@;
        $error =~ s/at \S+?\.pm line \d+.*$//;
        my $i18n = WebGUI::International->new($session, 'PassiveAnalytics');
        $error = join ' ', $i18n->get('Regular Expression Error:'), $error;
        return www_editRule($session, $error);
    }
    my $ruleId = $form->get('ruleId');
    my $rule;
    if ($ruleId eq 'new') {
        $rule = WebGUI::PassiveAnalytics::Rule->new($session, {});
    }
    else {
        $rule = WebGUI::PassiveAnalytics::Rule->new($session, $ruleId);
    }
    $rule->updateFromFormPost if $rule;
    return www_editRuleflow($session);
}

#-------------------------------------------------------------------

=head2 www_exportBucketData ( )

Dump the contents of the bucket log.

=cut

sub www_exportBucketData {
    my ($session) = @_;

    my $process = WebGUI::Fork->start(
        $session,
        __PACKAGE__, 'exportSomething',
        { tableName => 'bucketLog', filename => 'bucketData.csv', },
    );
    my $i18n = WebGUI::International->new($session, 'PassiveAnalytics');
    $session->http->setRedirect(
        $session->url->page(
            $process->contentPairs(
                'ProgressBar', {
                    icon => 'passiveAnalytics',
                    title => $i18n->get('Export bucket data'),
                    proceed => $session->url->page('op=passiveAnalytics;func=editRuleflow'),
                },
            ),
        ),
    );
    return "redirect";
}

#-------------------------------------------------------------------

=head2 www_exportDeltaData ( )

Dump the contents of the delta log.

=cut

sub www_exportDeltaData {
    my ($session) = @_;
    my $process = WebGUI::Fork->start(
        $session,
        __PACKAGE__, 'exportSomething',
        { tableName => 'deltaLog', filename => 'deltaData.csv', },
    );
    my $i18n = WebGUI::International->new($session, 'PassiveAnalytics');
    $session->http->setRedirect(
        $session->url->page(
            $process->contentPairs(
                'ProgressBar', {
                    icon => 'passiveAnalytics',
                    title => $i18n->get('Export delta data'),
                    proceed => $session->url->page('op=passiveAnalytics;func=editRuleflow'),
                },
            ),
        ),
    );
    return "redirect";
}

#-------------------------------------------------------------------

=head2 www_exportLogs ( )

Dump the contents of the raw log.

=cut

sub www_exportLogs {
    my ($session) = @_;
    my $process = WebGUI::Fork->start(
        $session,
        __PACKAGE__, 'exportSomething',
        { tableName => 'passiveLog', filename => 'passiveData.csv', },
    );
    my $i18n = WebGUI::International->new($session, 'PassiveAnalytics');
    $session->http->setRedirect(
        $session->url->page(
            $process->contentPairs(
                'ProgressBar', {
                    icon => 'passiveAnalytics',
                    title => $i18n->get('Export raw logs'),
                    proceed => $session->url->page('op=passiveAnalytics;func=editRuleflow'),
                },
            ),
        ),
    );
    return "redirect";
}

#------------------------------------------------------------------

=head2 www_promoteRule ( session )

Moves a rule up one position in the execution order.

=head3 session

A reference to the current session.

=cut

sub www_promoteRule {
	my $session = shift;
	return $session->privilege->insufficient() unless canView($session);
    my $rule = WebGUI::PassiveAnalytics::Rule->new($session, $session->form->get("ruleId"));
    if (defined $rule) {
        $rule->promote;
    }
	return www_editRuleflow($session);
}

#-------------------------------------------------------------------

=head2 www_settings ( session )

Configure Passive Analytics settings.

=cut

sub www_settings {
    my $session = shift;
    my $error   = shift;
    return $session->privilege->insufficient() unless canView($session);
    if ($error) {
        $error = qq|<div class="error">$error</div>\n|;
    }
    my $i18n = WebGUI::International->new($session, "PassiveAnalytics");
    my $f = WebGUI::HTMLForm->new($session);
    $f->hidden(
        name=>'op',
        value=>'passiveAnalytics'
    );
    $f->hidden(
        name=>'func',
        value=>'settingsSave'
    );
    $f->integer(
        name      => 'pauseInterval',
        value     => $session->form->get('pauseInterval') || $session->setting->get('passiveAnalyticsInterval') || 300,
        label     => $i18n->get('default pause interval'),
        hoverHelp => $i18n->get('default pause interval help'),
    );
    $f->yesNo(
        name      => 'deleteDelta',
        value     => $session->form->get('deleteDelta') || $session->setting->get('passiveAnalyticsDeleteDelta') || 0,
        label     => $i18n->get('Delete Delta Table?'),
        hoverHelp => $i18n->get('Delete Delta Table? help'),
    );
    $f->yesNo(
        name      => 'enabled',
        value     => $session->form->get('enabled') || $session->setting->get('passiveAnalyticsEnabled') || 0,
        label     => $i18n->get('Enabled?'),
        hoverHelp => $i18n->get('Enabled? help'),
    );
    $f->submit();
    my $ac = WebGUI::AdminConsole->new($session,'passiveAnalytics');
    $ac->addSubmenuItem($session->url->page('op=passiveAnalytics;func=editRuleflow'), $i18n->get('Passive Analytics'));
    return $ac->render($error.$f->print, 'Passive Analytics Settings');
}

#-------------------------------------------------------------------

=head2 www_settingsSave ( session )

Save Passive Analytics settings.

=cut

sub www_settingsSave {
    my $session = shift;
    return $session->privilege->insufficient() unless canView($session);
    my $form = $session->form;
    $session->setting->set('passiveAnalyticsInterval',    $form->process('pauseInterval', 'integer'));
    $session->setting->set('passiveAnalyticsDeleteDelta', $form->process('deleteDelta',   'yesNo'  ));
    $session->setting->set('passiveAnalyticsEnabled',     $form->process('enabled',       'yesNo'  ));
    return www_settings($session);
}

1;
