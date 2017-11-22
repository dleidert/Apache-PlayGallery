# License text
package Apache2::PhotoGal;

use strict;
use warnings;

use vars qw($VERSION);

use mod_perl2 2.0;

use Apache2::Log;
use Apache2::Reload;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK DECLINED NOT_FOUND SERVER_ERROR :http :log);
use APR::Finfo;
use APR::Const -compile => qw(FILETYPE_DIR FILETYPE_REG FINFO_NORM);

use CGI qw(:standard);
use Data::Dumper qw(Dumper);
use File::Basename qw(dirname);
use File::stat;
BEGIN {
	use POSIX qw(:locale_h);
	use Locale::TextDomain qw(Apache2-PhotoGal);
	setlocale(LC_MESSAGES, '');
}
use Memoize;
use Template;

my %param;

sub handler {
        my $r = shift;

	$param{'IMG_PATT'}   ||= $r->dir_config('PhotoGalImagePattern') ?
	                         $r->dir_config('PhotoGalImagePattern') : '\.(jpe?g|png|svg|tiff?)$';
	$param{'VID_PATT'}   ||= $r->dir_config('PhotoGalVideoPattern') ?
	                         $r->dir_config('PhotoGalVideoPattern') : '\.(flv|mpe?g|mp4|ogg|webm)$';

	# don't handle these files
	if ( $r->uri =~ m|/favicon.ico|i ||
	    ($r->finfo->filetype == APR::Const::FILETYPE_REG &&
	     $r->uri !~ /$param{'IMG_PATT'}/i &&
	     $r->uri !~ /$param{'VID_PATT'}/i )) {
		return Apache2::Const::DECLINED;
	}

	my $cgi = CGI->new();
	if ($cgi->param('raw')) {
		# if image and width/height -> forward to resized image?
		return Apache2::Const::DECLINED;
	}

	# change to scalar context!
	if ($cgi->param('sort_by')) {
		my @list = $cgi->param('sort_by');
		@list = grep(/^(name|atime|mtime|size)$/, @list);
		$param{'SORT_ORDER'} = $list[0];
	}
	$param{'SORT_ORDER'} ||= 'name';
	$param{'SORT_REVERS'}  = ($cgi->param('rev') && $cgi->param('rev') =~ /^(1|on)$/) ? 1 : 0;
	$param{'ISROOT'}       = ($r->uri =~ m|^/$|) ? 1 : 0;

	# $r->parse_uri($r->uri) https://perl.apache.org/docs/2.0/api/Apache2/URI.html#C_parse_uri_
	# mod_dir and mod_autoindex tamper with these variables

	if ($r->finfo->filetype == APR::Const::FILETYPE_DIR) { # handle directory content
		# TODO
		# handle mod_dir by checking if APR->path is .*/$ ??!
		my $tpl = $r->dir_config('PhotoGalTemplatePageDir') ?
		          $r->dir_config('PhotoGalTemplatePageDir') : 'page_directory.tpl';
		return create_page($r, $tpl);
	}

	elsif ($r->finfo->filetype == APR::Const::FILETYPE_REG) {
		# handle pages based on content
		# TODO
		# serve text files as is, only handle images, videos, ...?
		if (defined($cgi->param('view'))) {
			my $viewsize = $cgi->param('view');
			return show_file($r, $viewsize);
		} else {
			$r->content_type('text/plain');
			$r->print("Image or video file!");
			return Apache2::Const::OK;
		}
	}
	else {
		return Apache2::Const::NOT_FOUND;
	}

	#get_language_list($r);

	# shouldn't get here
        return Apache2::Const::OK;
}

sub show_file {
	my ($r, $size) = @_;
	return Apache2::Const::DECLINED;
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

	my $filelist = get_files_in_curdir($r);
	my $vars = {
		TITLE => __("Directory"),
		MAIN => "<!-- " . __PACKAGE__ . "," . __LINE__ . ": directory = $dir -->",
		PACKAGE => __PACKAGE__ . " ($VERSION)",
		DIRLIST  => $filelist->{APR::Const::FILETYPE_DIR},
		FILELIST => $filelist->{APR::Const::FILETYPE_REG},
		PARAMETERS => \%param,
	};

	$r->content_type('text/html');
	#$r->content_encoding('gzip');

	$template->process($file, $vars) ||
		return log_message($r, Apache2::Const::SERVER_ERROR, $template->error());
	return Apache2::Const::OK;
}

# memoize function by adding mtime argument?
sub get_files_in_curdir {
	my $r = shift;

	my $dir = $r->finfo->fname;
	unless ((-d $dir) && (opendir (DIR, $dir))) {
		log_message ($r, Apache2::Const::SERVER_ERROR, 'Cannot open directory.', $dir);
		return;
	}

	my %list;
	my @files = grep { !/^\./ && -f "$dir/$_" } readdir(DIR);
	rewinddir (DIR);
	my @dirs  = grep { !/^\./ && -d "$dir/$_" } readdir(DIR);

	$list{APR::Const::FILETYPE_REG} = [ sort_files_in_order($r, $dir, \@files) ]; 
	$list{APR::Const::FILETYPE_DIR} = [ sort_files_in_order($r, $dir, \@dirs)  ];
	closedir(DIR);
	return \%list;
}

sub sort_files_in_order {
	my ($r, $dir, $listref) = @_;
	my @sorted;
	if ($param{'SORT_ORDER'} =~ /^(atime|mtime|size)$/) {
		my $sort = $param{'SORT_ORDER'};
		my %h;
		@sorted = sort { ($h{$a} ||= stat("$dir/$a")->$sort()) <=>
		                 ($h{$b} ||= stat("$dir/$b")->$sort())
		               } @{$listref};
	} else {
		@sorted = sort @{$listref};
	}
	if ($param{'SORT_REVERS'}) {
		return reverse @sorted;
	} else {
		return @sorted;
	}
}

=begin comment
# setlocale() is picky and needs charset too
# get charset from header?
# use Locale::Util to get requested langauges?
sub get_language_list {
	my $r = shift;
	return unless $r;

	my @list = grep(/^\w+(-\w+)?$/, split(/,|;/, $r->headers_in->get('Accept-Language')));
	$r->log->debug(__PACKAGE__, "Extracted Language codes are: " . join(', ', @list) . "\n");
	return @list;
}
=end comment

=cut

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

=begin comment
sub get_page_language {
	my ($r, $lang) = @_;
	return unless $r; 

	my @acc_lang_string = grep(/^\w+(-\w+)?$/, split(/,|;/, $r->headers_in->get('Accept-Language')));
	#my $gal_conf_lang = $r->dir_config('PhotoGalVideoPattern') ? $r->dir_config('PhotoGalVideoPattern') : '';
	if ($r->dir_config('PhotoGalAcceptedLanguagePattern')) { # should be regex as seen above!
		# now loop over join(@acc_lang_string) and find us first match
	}
	# if nothing matches, return default!
	# maybe create sub that returns the list of supported languages 
	# TODO loop @acc_ over existing translations and return first matching!
	$r->print("Accept-Language: " . $r->headers_in->get('Accept-Language') . "\n");
	$r->print("Language codes are: " . join(', ', @acc_lang_string) . "\n");
	return;
}
=end comment

=cut

=head1 NAME

Apache2::PhotoGal - mod_perl handler to create image and video galleries

=head1 VERSION

Version 0.01

=cut

our $VERSION = 0.01;


=head1 SYNOPSIS

This module can act as a mod_perl handler for Apache2 to serve nice image
galleries and image pages created on the fly, examining the webfolder and
the image properties. At the moment it is work-in-progress and not usable
for production.

This is how to enable and the handler and reload it automatically after
changing the source code. The latter is only interesting for writing the 
handler code itself.

    <Location />
        Options -Indexes
        DirectoryIndex disabled
        PerlSetVar PhotoGalTemplateDir '/usr/share/libapache2-photogal-perl/templates/default/'
        SetHandler perl-script
        PerlResponseHandler Apache2::PhotoGal
    </Location>

The templates can also be copied to a writeable place and adjusted to your
own specifications as long as the templates use the provided variables.
Knowledge of the perl template module might be necessary.

=head1 AUTHOR

Danial Leidert, C<< <dleidert at wgdd.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<dleidert at wgdd.de>, or through
the web interface at L<https://github.com/dleidert/Apache2-PhotoGal/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache2::PhotoGal

You can also look for information at:

=over 4

=item * issue tracker (report bugs here)

L<https://github.com/dleidert/Apache2-PhotoGal/issues>

=item * homepage

L<https://github.com/dleidert/Apache2-PhotoGal>

=back


=head1 ACKNOWLEDGEMENTS

The handler is based on the idea behind L<Apache::Gallery> written by
Michael Legart.


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

= head1 SEE ALSO

L<Template>

=cut

1; # End of Apache2::PhotoGal
