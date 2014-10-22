package Pod::Weaver::Plugin::StopWords;
BEGIN {
  $Pod::Weaver::Plugin::StopWords::VERSION = '1.001005';
}
BEGIN {
  $Pod::Weaver::Plugin::StopWords::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Dynamically add stopwords to your woven pod


use strict;
use warnings;
use Moose;
use Moose::Autobox;
use namespace::autoclean;

use Pod::Weaver 3.101632 ();
with 'Pod::Weaver::Role::Finalizer';

sub mvp_multivalue_args { qw(exclude include) }
sub mvp_aliases { return {
	collect                    => 'gather',
	include_author             => 'include_authors',
	include_copyright_holders  => 'include_copyright_holder',
	stopwords                  => 'include'
} }

has exclude => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has gather => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1
);

has include => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has include_authors => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1
);

has include_copyright_holder => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1
);

has wrap => (
	is      => 'rw',
	isa     => 'Int',
	default => 76
);


sub finalize_document {
    my ($self, $document, $input) = @_;

	# are we weaving under Dist::Zilla?
	my $zilla = ($input && $input->{zilla});

	# our attributes are read-write
	if( $zilla and my $stash = $zilla->stash_named('%PodWeaver') ){
		$stash->merge_stashed_config($self);
	}

	my @stopwords = @{$self->include};

	# the attributes are probably the same between $input and $zilla,
	# but we'll add them both just in case. (duplicates are removed later.)

	if( $self->include_copyright_holder ){
		my @holders;

		push(@holders, $input->{license}->holder)
			if $input->{license};
		push(@holders, $zilla->copyright_holder)
			if $zilla;

		unshift(@stopwords, $self->separate_stopwords(@holders))
			if @holders;
	}

	if( $self->include_authors ){
		my @authors;

		push(@authors, $input->{authors})
			if $input->{authors};
		push(@authors, $zilla->authors)
			if $zilla;

		unshift(@stopwords, $self->author_stopwords(@authors))
			if @authors;
	}

	# TODO: keep different sections as separate lines
	push(@stopwords, $self->splice_stopwords_from_children($document->children))
		if $self->gather;

	my %seen;
	$seen{$_} = 1 foreach $self->separate_stopwords($self->exclude);

	@stopwords = grep { $_ && !$seen{$_}++ }
		$self->separate_stopwords(@stopwords);

	return unless @stopwords;

    $document->children->unshift(
        Pod::Elemental::Element::Pod5::Command->new({
            command => 'for :stopwords',
            content => $self->format_stopwords(\@stopwords)
        }),
    );
}


sub author_stopwords {
	my $self = shift;
	return grep { !/^<\S+\@\S+\.\S+>$/ } $self->separate_stopwords(@_);
}


sub format_stopwords {
	my ($self, $stopwords) = @_;
	my $paragraph = join(' ', @$stopwords);

	return $paragraph
		unless $self->wrap && eval "require Text::Wrap";

	local $Text::Wrap::columns = $self->wrap;
	return Text::Wrap::wrap('', '', $paragraph);
}


sub separate_stopwords {
	my $self = shift;
	# flatten any array refs and split each string on spaces
	map { split /\s+/ } map { ref($_) ? @$_ : $_ } @_;
}


sub splice_stopwords_from_children {
    my ($self, $children) = @_;
	my @stopwords;

	CHILDREN: foreach my $i ( 0 .. (@$children - 1) ){
		next unless my $para = $children->[$i];
		next unless $para->isa('Pod::Elemental::Element::Pod5::Region')
			and $para->format_name eq 'stopwords';

		push(@stopwords,
			map { split(/\s+/, $_->content) } $para->children->flatten);

		# remove paragraph from document since we've copied all of its stopwords
		splice(@$children, $i, 1);

		redo CHILDREN; # don't increment the counter
	}

	return @stopwords;
}

__PACKAGE__->meta->make_immutable;

1;



__END__
=pod

=for :stopwords Randy Stauner arrayrefs CPAN AnnoCPAN RT CPANTS Kwalitee diff IRC

=head1 NAME

Pod::Weaver::Plugin::StopWords - Dynamically add stopwords to your woven pod

=head1 VERSION

version 1.001005

=head1 SYNOPSIS

	# weaver.ini
	[-StopWords]
	gather = 1     ; default
	include = MyExtraWord1 exword2

=head1 DESCRIPTION

This is a L<Pod::Weaver> plugin for dynamically adding stopwords
to help pass the Pod Spelling test.
It does the L<Pod::Weaver::Role::Finalizer> role.

Author names will be included along with any
L<stopwords|/include> specified in the plugin config (F<weaver.ini>).

Additionally the plugin can gather any other stopwords
listed in the POD and compile them all into one paragraph
at the top of the document.

=head2 Using with Dist::Zilla

If you're using L<Dist::Zilla> this plugin will check for the
C<%PodWeaver> Stash (L<Dist::Zilla::Stash::PodWeaver>)
and load any additional configuration found there.
So you can specify additional stopwords
(or any other attributes) in your F<dist.ini>:

	; dist.ini
	[@YourFavoriteBundle]
	[%PodWeaver]
	-StopWords:include = favorite_fake_word

=head1 ATTRIBUTES

=head2 exclude

List of stopwords to explicitly exclude.

This can be set multiple times.

If combined with 'gather' this can remove stopwords
previously found in the Pod.

=head2 gather

Gather up all other C< =for stopwords > sections and combine them into a
single paragraph at the top of the document.

If set to false the plugin will not search the document but will simply
put any new stopwords in a new paragraph at the top.

Defaults to true.

Aliased as C<collect>.

=head2 include

List of stopwords to include.

This can be set multiple times.

Aliased as C<stopwords>.

=head2 include_authors

A boolean value to indicate whether or not to include Author names
as stopwords.  The pod spell check always complained about my last name
appearing in the AUTHOR section.  It's one of the primary reasons for
developing this plugin.

Defaults to true.

=head2 include_copyright_holder

A boolean value to indicate whether or not to include stopwords for
the license/copyright holder.  This can be different than the author
and will show up in the default LICENSE Section.

This way you don't have to remember to put your company name
into the L<%PodWeaver Stash|Dist::Zilla::Stash::PodWeaver>
for every single F<dist.ini> you have at C<$work>.

Defaults to true.

=head2 wrap

This is an integer for the number of columns at which to wrap the resulting
paragraph.

It defaults to C<76> which is the default in
L<Text::Wrap> (version 2009.0305).

No wrapping will be done if L<Text::Wrap> is not found
or if you set this value to C<0>.

=head1 METHODS

=head2 author_stopwords

Collect names of authors from provided authors array.
Ignore email addresses (since Pod::Spell will ignore them anyway).

=head2 format_stopwords

Format the final paragraph to be added to the document.
Uses L<Text::Wrap> if available and the I<wrap> attribute is set
to a positive number (the column at which to wrap text).

=head2 separate_stopwords

Flatten passed arrays and arrayrefs and split the strings inside
by whitespace to return a flat list of words.

=head2 splice_stopwords_from_children

Look for any previous stopwords paragraphs in the document,
capture the stopwords inside,
and remove the paragraphs from the document.

This is only called if I<gather> is true.

=for Pod::Coverage finalize_document mvp_aliases mvp_multivalue_args

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=item *

L<Pod::Spell>

=item *

L<Test::Spelling>

=item *

L<Dist::Zilla::Plugin::PodSpellingTests>

=item *

L<Dist::Zilla::Stash::PodWeaver>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Pod::Weaver::Plugin::StopWords

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/Pod-Weaver-Plugin-StopWords>

=item *

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Weaver-Plugin-StopWords>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-Weaver-Plugin-StopWords>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-Weaver-Plugin-StopWords>

=item *

CPAN Forum

L<http://cpanforum.com/dist/Pod-Weaver-Plugin-StopWords>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/Pod-Weaver-Plugin-StopWords>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/P/Pod-Weaver-Plugin-StopWords.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Pod-Weaver-Plugin-StopWords>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-pod-weaver-plugin-stopwords at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Weaver-Plugin-StopWords>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head2 Source Code


L<http://github.com/magnificent-tears/Pod-Weaver-Plugin-StopWords/tree>

  git clone git://github.com/magnificent-tears/Pod-Weaver-Plugin-StopWords.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

