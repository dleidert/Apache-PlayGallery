# License text
package Apache2::PhotoGal;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = "0.0.1";

use mod_perl2 2.0;

use Apache2::Log;
use Apache2::Reload;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK DECLINED NOT_FOUND SERVER_ERROR :http :log);

#use POSIX;
#use Locale::TextDomain 'Apache2-PhotoGal';
use Template;

sub handler {
        my $r = shift;

	# don't handle these files / how to handle index.html if existing?
	if ($r->uri =~ m|/favicon.ico|i) {
		return Apache2::Const::DECLINED;
	}

	$r->log->debug(__PACKAGE__, " uri->" . $r->uri . ", filename->", $r->filename, ", path_info->", $r->path_info);

	# mod_dir and mod_autoindex tamper with these variables
	my $filename = $r->filename . $r->path_info;

	if (-d $filename) { # handle directory content
		# TODO
		# handle mod_dir by checking if APR->path is .*/$ ??!
		my $tpl = $r->dir_config('PhotoGalTemplatePageDir') ?
		          $r->dir_config('PhotoGalTemplatePageDir') : 'page_directory.tpl';
		return create_page($r, $tpl);
	}
	elsif (-f $filename) {
		# handle pages based on content
		# TODO
		# serve text files as is, only handle images, videos, ...?
		my $image_pattern = $r->dir_config('PhotoGalImagePattern') ?
		                    $r->dir_config('PhotoGalImagePattern') : '\.(jpe?g|png|svg|tiff?)$';
		my $video_pattern = $r->dir_config('PhotoGalVideoPattern') ?
		                    $r->dir_config('PhotoGalVideoPattern') : '\.(flv|mpe?g|mp4|ogg|webm)$';
		return Apache2::Const::OK;
	}
	# handle something like foo.jpg?width=... and show resized picture
	else {
		# serve 404
		return Apache2::Const::NOT_FOUND;
	}

	#get_language_list($r);

	# shouldn't get here
        return Apache2::Const::OK;
}

# show page and return HTTP code accordingly?
sub create_page {
	my ($r, $file) = @_;
	
	my $dir = $r->dir_config('PhotoGalTemplateDir');
	unless (-d $dir) {
		return log_message($r, Apache2::Const::SERVER_ERROR, 'PhotoGalTemplateDir not set or not existing', $dir);
	}

	my $template = Template->new({
		INCLUDE_PATH  => $dir,
		PRE_PROCESS   => 'config',
		OUTPUT        => $r,
	}) or return log_message($r, Apache2::Const::SERVER_ERROR, Template->error);

	my $vars = {
		TITLE => 'Mein Titel',
		MAIN => "<!-- " . __PACKAGE__ . "," . __LINE__ . ": directory = $dir -->",
		HOMEPAGE => 'https://github.com/dleidert/Apache2-PhotoGal.git',
		PACKAGE => '<a href="">' . __PACKAGE__ . " ($VERSION)" . '</a>',
	};

	$r->content_type('text/html');
	#$r->content_encoding('gzip');

	$template->process($file, $vars) ||
		return log_message($r, Apache2::Const::SERVER_ERROR, $template->error());
	return Apache2::Const::OK;
}

#sub get_language_list {
#	my $r = shift;
#	return unless $r;
#
#	my @list = grep(/^\w+(-\w+)?$/, split(/,|;/, $r->headers_in->get('Accept-Language')));
#	$r->log->debug(__PACKAGE__, "Extracted Language codes are: " . join(', ', @list) . "\n");
#	return @list;
#}

sub log_message {
	my ($r, $status, $message, $file) = @_;
	if ($file) {
		$r->log_reason(__PACKAGE__ . ": " . $message, $file);
	} else {
		$r->log_error(__PACKAGE__ . ": " . $message)
	}
	#$r->log->error(__PACKAGE__ . " (" . $file . ") " . $message);
	return $status;
}

#sub get_page_language {
#	my ($r, $lang) = @_;
#	return unless $r; 
#
#	my @acc_lang_string = grep(/^\w+(-\w+)?$/, split(/,|;/, $r->headers_in->get('Accept-Language')));
#	#my $gal_conf_lang = $r->dir_config('PhotoGalVideoPattern') ? $r->dir_config('PhotoGalVideoPattern') : '';
#	if ($r->dir_config('PhotoGalAcceptedLanguagePattern')) { # should be regex as seen above!
#		# now loop over join(@acc_lang_string) and find us first match
#	}
#	# if nothing matches, return default!
#	# maybe create sub that returns the list of supported languages 
#	# TODO loop @acc_ over existing translations and return first matching!
#	$r->print("Accept-Language: " . $r->headers_in->get('Accept-Language') . "\n");
#	$r->print("Language codes are: " . join(', ', @acc_lang_string) . "\n");
#	return;
#}

1;

=head1 NAME

Apache2::PhotoGal - The great new Apache2::PhotoGal!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Apache2::PhotoGal;

    my $foo = Apache2::PhotoGal->new();
    ...

=head1 AUTHOR

Danial Leidert, C<< <dleidert at wgdd.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-apache2-photogal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-PhotoGal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::PhotoGal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-PhotoGal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Apache2-PhotoGal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Apache2-PhotoGal>

=item * Search CPAN

L<http://search.cpan.org/dist/Apache2-PhotoGal/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Danial Leidert.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Apache2::PhotoGal
