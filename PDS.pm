
=head1 NAME

PDS.pm

=head1 SYNOPSIS

    use PDS;
    PDS->login unless $pds_handle;
    my $pds = PDS->new( $pds_handle );
    my $error = PDS->error;
    if ( $error ) {
	print $error;
    } else {
	my $id = $pds->userid;
	my $group = $pds->group;
    }

=head1 DESCRIPTION

Allows scripts to use Ex Libris Patron Directory Service (PDS) to manage user logins.

Scripts can be run after login by adding the script URL as a parameter on the
PDS login link, e.g. from the URL:

    https://our.hosted.exlibrisgroup.com/pds
    ?func=load-login&institute=61ADELAIDEU&calling_system=primo&lang=eng
    &url=https://library.adelaide.edu.au/cgi/ourscript

Alternatively the script can force a login with PDS->login, which will return to the calling script.

Username is obtained by calling PDS back with the bor-info function, which should
return an XML data structure like so:

    <bor>
	<bor_id>
	    <id>1234567</id>
	    <handle>6820141643591607825054665244825</handle>
	    <institute>61ADELAIDE_INST</institute>
	</bor_id>
	<bor-info>
	    <id>1234567</id>
	    <id>Stephen</id>
	    <institute>61ADELAIDE_INST</institute>
	    <name>Stephen</name>
	    <group>STAFF</group>
	    <email_address>stephen.thomas@adelaide.edu.au</email_address>
	</bor-info>
    </bor>

=cut

package PDS;

use LWP::Simple;
use URI::Escape;
use XML::Simple;
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

##--------CONFIGURE-----------------------------------------------------
my $pds_url = "https://primo-direct-apac.hosted.exlibrisgroup.com/pds";
##----------------------------------------------------------------------

my $errstr = '';

=head1 METHODS

=head2 PDS->new( $pds_handle );

Retrieves the details of the logged in user from PDS.

If the script is called on return from PDS, there will be a handle,
otherwise we can redirect to PDS to get one.

=cut

sub new {
	my $class = shift;
	my $pds_handle = shift;
	my $pds = {};

	unless ( $pds_handle )
	{
		## No handle, so we haven't logged in yet.
		## Redirect to the login page 
		PDS->login;
	}

	## OK, we have already been authenticated 
	## Get the user details. Specifically, the user id
	my $result = get( "$pds_url?func=bor-info&pds_handle=$pds_handle" ); #&institute=$institute";

	if ( $result =~ /<bor>/ )
	{
		$pds = XMLin( $result );
	}
	else
	{
		$errstr = "Failed to get user details: $result";
	}

	bless $pds, $class;
	return $pds;
}

=head2 PDS->login

Redirect to PDS login form, returning to our calling script and preserving query parameters.

=cut

sub login {
	my $class = shift;
	print "Location: ", $pds_url,
	    "?func=load-login&institute=61ADELAIDEU&calling_system=primo&lang=eng&url=",
	    uri_escape("https://$ENV{'SERVER_NAME'}$ENV{'SCRIPT_NAME'}?$ENV{'QUERY_STRING'}"),
	    "\n\n";
	exit;
}

=head2 PDS->error

Return any error as a string. Returns the empty string if no errors.

=cut

sub error {
	my $pds = shift;
	return $errstr;
}

=head2 $pds->userid;

Return the id of the logged-in user.

=cut

sub userid {
	my $pds = shift;
	return $pds->{bor_id}->{id};
}

=head2 $pds->group;

Returns the group of the logged-in user.

=cut

sub group {
	my $pds = shift;
	return $pds->{'bor-info'}->{group};
}

1;

__END__

=head1 AUTHOR

Steve Thomas <stephen.thomas@adelaide.edu.au>

=head1 VERSION

This is version 2014.08.19

=head1 LICENCE

Copyright 2014 Steve Thomas

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

