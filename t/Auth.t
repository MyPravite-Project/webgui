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
use Exception::Class;

use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Auth;
use WebGUI::Session;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;

my @cleanupUsernames    = ();   # Will be cleaned up when we're done
my $auth;   # will be used to create auth instances

#----------------------------------------------------------------------------
# Tests

plan tests => 11;        # Increment this number for each test you create

#----------------------------------------------------------------------------
# Test createAccountSave and returnUrl together
# Set up request
my $createAccountSession = WebGUI::Test->newSession(0, {
    returnUrl       => 'REDIRECT_URL',
});

$auth           = WebGUI::Auth->new( $createAccountSession );
my $username    = $createAccountSession->id->generate;
my $language	= "PigLatin";
push @cleanupUsernames, $username;
installPigLatin();
WebGUI::Test->addToCleanup(sub {
	unlink File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin WebGUI.pm/);
	unlink File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin.pm/);
	rmdir File::Spec->catdir(WebGUI::Test->lib, qw/WebGUI i18n PigLatin/);
});

$createAccountSession->scratch->setLanguageOverride($language);
my $output         = $auth->www_createAccountSave( $username, { }, "PASSWORD" ); 
WebGUI::Test->addToCleanup(sub {
    for my $username ( @cleanupUsernames ) {
        # We don't create actual, real users, so we have to cleanup by hand
        my $userId  = $session->db->quickScalar(
            "SELECT userId FROM users WHERE username=?",
            [ $username ]
        );

        my $addressBookId = $session->db->quickScalar(
            "select addressBookId from addressBook where userId=?",
            [ $userId ]
        );

        if($addressBookId) {
            $session->db->write(
                "delete from address where addressBookId=?",
                [$addressBookId]
            );
        }

        my @tableList
            = qw{authentication users userProfileData groupings inbox userLoginLog addressBook};

        for my $table ( @tableList ) {
            $session->db->write(
                "DELETE FROM $table WHERE userId=?",
                [ $userId ]
            );
        }
    }
});

is(
    $createAccountSession->response->location, 'REDIRECT_URL',
    "returnUrl field is used to set redirect after createAccountSave",
);

is $createAccountSession->user->get('language'), $language, 'languageOverride is taken in to account in createAccountSave';
$createAccountSession->scratch->delete('language');  ##Remove language override



#----------------------------------------------------------------------------
# Test login and returnUrl together
# Set up request

my $loginSession = WebGUI::Test->newSession(0, {
    returnUrl       => 'REDIRECT_LOGIN_URL',
});

$auth           = WebGUI::Auth->new( $loginSession, 3 );
my $username    = $loginSession->id->generate;
push @cleanupUsernames, $username;
$session->setting->set('showMessageOnLogin', 0);
$output         = $auth->www_login;

is(
    $loginSession->response->location, 'REDIRECT_LOGIN_URL',
    "returnUrl field is used to set redirect after login",
);
is $output, undef, 'login returns undef when showMessageOnLogin is false';

#----------------------------------------------------------------------------
# Test createAccountSave
$auth           = WebGUI::Auth->new( $session );
$username    = $session->id->generate;
push @cleanupUsernames, $username;

#Test updates to existing addresses
tie my %profile_info, "Tie::IxHash", (
    firstName       => "Andy",
    lastName        => "Dufresne",
    homeAddress     => "123 Shank Ave.",
    homeCity        => "Shawshank",
    homeState       => "PA",
    homeZip         => "11223",
    homeCountry     => "US",
    homePhone       => "111-111-1111",
    email           => 'andy@shawshank.com'
);

diag $auth->www_createAccountSave( $username, { }, "PASSWORD", \%profile_info );

#Reset andy to the session users since stuff has changed
my $andy = $session->user;

#Test that the address was saved to the profile
cmp_bag(
    [ map { $andy->get($_) } keys %profile_info ],
    [ values %profile_info ],
    'Profile fields were saved'
);

#Test that the addressBook was created
my $bookId = $session->db->quickScalar(
    q{ select addressBookId from addressBook where userId=? },
    [$andy->getId]
);

ok( ($bookId ne ""), "Address Book was created");

my $book   = WebGUI::Shop::AddressBook->new($session,$bookId);

my @addresses = @{ $book->getAddresses() };

is(scalar(@addresses), 1 , "One address was created in the address book");

my $address = $addresses[0];

tie my %address_info, "Tie::IxHash", (
    firstName       => $address->get("firstName"),
    lastName        => $address->get("lastName"),
    homeAddress     => $address->get("address1"),
    homeCity        => $address->get("city"),
    homeState       => $address->get("state"),
    homeZip         => $address->get("code"),
    homeCountry     => $address->get("country"),
    homePhone       => $address->get("phoneNumber"),
    email           => $address->get("email")
);

#Test that the address was saved properly to shop
cmp_bag(
    [ values %profile_info ],
    [ values %address_info ],
    'Shop address was has the right information'
);

#Test that the address is returned as the profile address
my $profileAddress = $book->getProfileAddress;
is($profileAddress->getId, $address->getId, "Profile linked properly to address");

#Test that the address is the default address
my $defaultAddress = $book->getDefaultAddress;
is(
    $defaultAddress->getId,
    $address->getId,
    "Profile address properly set to default address when created"
);

$username    = $session->id->generate;
push @cleanupUsernames, $username;

#Test updates to existing addresses
%profile_info = (
    firstName       => "Andy",
    lastName        => "Dufresne",
    email           => 'andy@shawshank.com'
);

$auth->createAccountSave( $username, { }, "PASSWORD", \%profile_info );

#Test that the addressBook was not created
my $bookCount = $session->db->quickScalar(
    q{ select count(addressBookId) from addressBook where userId=? },
    [$session->user->getId]
);

is( $bookCount, 0, "Address Book was not created for user without address fields");

sub installPigLatin {
    use File::Copy;
	mkdir File::Spec->catdir(WebGUI::Test->lib, 'WebGUI', 'i18n', 'PigLatin');
	copy( 
		WebGUI::Test->getTestCollateralPath('International/lib/WebGUI/i18n/PigLatin/WebGUI.pm'),
		File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin WebGUI.pm/)
	);
	copy(
		WebGUI::Test->getTestCollateralPath('International/lib/WebGUI/i18n/PigLatin.pm'),
		File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin.pm/)
	);
}

