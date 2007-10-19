#
# This file is part of CPANPLUS::Dist::Mdv.
# Copyright (c) 2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

package CPANPLUS::Dist::Mdv;

use strict;
use warnings;

use base 'CPANPLUS::Dist::Base';

use CPANPLUS::Error; # imported subs: error(), msg()
use File::Basename;
use File::Copy      qw[ copy ];
use IPC::Cmd        qw[ run can_run ];
use Readonly;

our $VERSION = '0.1.1';

Readonly my $DATA_OFFSET => tell(DATA);
Readonly my $HOME => $ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7];


#--
# class methods

#
# my $bool = CPANPLUS::Dist::Mdv->format_available;
#
# Return a boolean indicating whether or not you can use this package to
# create and install modules in your environment.
#
sub format_available {
    # check mandriva release file
    if ( ! -f '/etc/mandriva-release' ) {
        error( 'not on a mandriva system' );
        return 0;
    }

    my $flag;

    # check rpm tree structure
    if ( ! -d "$HOME/rpm" ) {
        error( 'need to create rpm tree structure in your home' );
        return 0;
    }
    foreach my $subdir ( qw[ BUILD RPMS SOURCES SPECS SRPMS tmp ] ) {
        my $dir = "$HOME/rpm/$subdir";
        next if -d $dir;
        error( "missing directory '$dir'" );
        $flag++;
    }

    # check prereqs
    for my $prog ( qw[ rpm rpmbuild gcc ] ) {
        next if can_run($prog);
        error( "'$prog' is a required program to build mandriva packages" );
        $flag++;
    }

    return not $flag;
}

#--
# public methods

#
# my $bool = $mdv->init;
#
# Sets up the C<CPANPLUS::Dist::Mdv> object for use, and return true if
# everything went fine.
#
sub init {
    my ($self) = @_;
    my $status = $self->status; # an Object::Accessor
    # distname: Foo-Bar
    # distvers: 1.23
    # rpmname:  perl-Foo-Bar
    # rpm:      $HOME/rpm/RPMS/noarch/perl-Foo-Bar-1.23-1mdv2008.0.noarch.rpm
    # srpm:     $HOME/rpm/SRPMS/perl-Foo-Bar-1.23-1mdv2008.0.src.rpm
    # rpmvers:  1
    # specpath: $HOME/rpm/SPECS/perl-Foo-Bar.spec
    $status->mk_accessors(qw[ distname distvers rpmname rpm
        rpmvers srpm specpath ]);

    return 1;
}

sub prepare {
    my ($self, %args) = @_;

    # dry-run with makemaker: handles prereqs, .
    # note: we're also running create + install at this stage to know
    # the list of files to be installed. indeed, this will be needed for
    # the specfile creation.
    $self->SUPER::prepare( %args, verbose=>0 );

    my $status = $self->status;               # private hash
    my $module = $self->parent;               # CPANPLUS::Module
    my $intern = $module->parent;             # CPANPLUS::Internals
    my $conf   = $intern->configure_object;   # CPANPLUS::Configure
    my $distmm = $module->status->dist_cpan;  # CPANPLUS::Dist::MM

    # parse args.
    my %opts = (
        force   => $conf->get_conf('force'),  # force rebuild
        perl    => $^X,
        verbose => $conf->get_conf('verbose'),
        %args,
    );

    # compute & store package information
    my $distname    = $module->package_name;
    $status->distname( $distname );
    my $distvers    = $module->package_version;
    #my $distsummary    = 
    #my $distdescr      = 
    #my $distlicense    =
    my $disturl        = $module->package;
    my @reqs           = sort keys %{ $module->status->prereqs };
    my $distreqs       = join "\n", map { "Requires: perl($_)" } @reqs;
    my $distbreqs      = join "\n", map { "BuildRequires: perl($_)" } @reqs;
    my @docfiles =
        grep { /(README|Change(s|log)|LICENSE|META.yml)$/i }
        map { basename $_ }
        @{ $module->status->files };

    my $rpmname = _mk_pkg_name($module);
    $status->rpmname( $rpmname );


    # check whether package has been build.
    if ( my $pkg = $self->_has_been_build ) {
        my $modname = $module->module;
        msg( "already created package for '$modname' at '$pkg'" );

        if ( not $opts{force} ) {
            msg( "won't rebuild package since --force isn't in use" );
            $status->prepared(1);
            $status->created(1);
            $status->pkgpath($pkg);
            $status->dist($pkg);
            return $pkg;
            # XXX check if it works
        }

        msg( '--force in use, rebuilding anyway' );
    }

    # compute & store path of specfile.
    my $spec = "$HOME/rpm/SPECS/$rpmname.spec";
    $status->specpath($spec);

    my $vers = $module->version;
    msg($vers);

    # writing the spec file.
    seek DATA, $DATA_OFFSET, 0;
    open my $specfh, '>', $spec or die "can't open '$spec': $!";
    while ( defined( my $line = <DATA> ) ) {
        last if $line =~ /^__END__$/;

        $line =~ s/DISTNAME/$distname/;
        $line =~ s/DISTVERS/$distvers/;
        #$line =~ s/DISTSUMMARY/$distsummary/;
        $line =~ s/DISTURL/$disturl/;
        $line =~ s/DISTBUILDREQUIRES/$distbreqs/;
        $line =~ s/DISTREQUIRES/$distreqs/;
        #$line =~ s/DISTDESCR/$distdescr/;
        $line =~ s/DISTDOC/@docfiles ? "%doc @docfiles" : ''/e;
        #$line =~ s/DISTEXTRA/join( "\n", @{ $dist->extra_files || [] })/e;

        print $specfh $line;
    }
    close $specfh;

    # copy package.
    my $basename = basename $module->status->fetch;
    my $tarball = "$HOME/rpm/SOURCES/$basename";
    copy( $module->status->fetch, $tarball );

    # return success
    $status->prepared(1);
    return 1;
}


sub create {
    my ($self, %args) = @_;

    $self->SUPER::create( %args, verbose=>0 );

    my $status = $self->status;               # private hash
    my $module = $self->parent;               # CPANPLUS::Module
    my $intern = $module->parent;             # CPANPLUS::Internals
    my $conf   = $intern->configure_object;   # CPANPLUS::Configure
    my $distmm = $module->status->dist_cpan;  # CPANPLUS::Dist::MM

    # parse args.
    my %opts = (
        force   => $conf->get_conf('force'),  # force rebuild
        perl    => $^X,
        verbose => $conf->get_conf('verbose'),
        %args,
    );

    my $spec     = $status->specpath;
    my $distname = $status->distname;
    my $rpmname  = $status->rpmname;

    # dry-run, to see if we forgot some files
    my ($buffer, $success);
    DRYRUN: {
        local $ENV{LC_ALL} = 'C';
        $success = run(
            command => "rpmbuild -ba $spec",
            verbose => $opts{verbose},
            buffer  => \$buffer,
        );
    }

    # check if the dry-run finished correctly
    if ( $success ) {
        my ($rpm)  = glob "$HOME/rpm/RPMS/*/$rpmname-*.rpm";
        my ($srpm) = glob "$HOME/rpm/SRPMS/$rpmname-*.src.rpm";
        msg( "rpm created successfully: $rpm" );
        msg( "srpm available: $srpm" );
        $status->rpm($rpm);
        $status->srpm($srpm);
        $status->dist($rpm);
        $status->created(1);

        return 1;
    }

    # unknown error, aborting.
    if ( not $buffer =~ /^\s+Installed .but unpackaged. file.s. found:\n(.*)\z/ms ) {
        error( "failed to create mandriva package for '$distname': $buffer" );
        $status->created(0);
        return 0;
    }

    msg( "extra files installed, fixing spec file" );
    # additional files to be packaged
    #my $files = $1;
    #$files =~ s/^\s+//mg; # remove spaces
    #my @files = split /\n/, $files;
    #$dist->extra_files( \@files );


}

sub install {
    my ($self, %args) = @_;
    use YAML; msg( Dump($self) );
    my $rpm = $self->status->rpm;
    error( "installing $rpm" );
    die;
    #$dist->status->installed
}



#--
# private methods

#
# my $bool = $self->_has_been_build;
#
# return true if there's already a package build for this module.
# 
sub _has_been_build {
    my ($self) = @_;

    my $name = $self->status->rpmname;
    my $vers = $self->parent->version;  # module version
    #return "/home/jquelin/rpm/RPMS/noarch/perl-POE-Component-Client-Keepalive-0.1000-1mdv2008.0.noarch.rpm";
    return 0; # FIXME do some real checks, including cooker.
}


#--
# private subs

#
# my $name = _mk_pkg_name($module);
#
# given the CPANPLUS::Module object $module, return the name of the
# mandriva rpm package.
#
sub _mk_pkg_name {
    my ($module) = @_;
    my $name = 'perl-' . $module->module;
    $name =~ s/::/-/g;
    return $name;
}


1;

__DATA__

%define realname   DISTNAME

Name:		perl-%{realname}
Version:    DISTVERS
Release:    %mkrel 1
License:	GPL or Artistic
Group:		Development/Perl
Summary:    DISTSUMMARY
Source0:    DISTURL
Url:		http://search.cpan.org/dist/%{realname}
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildRequires:	perl-devel
DISTBUILDREQUIRES
DISTREQUIRES

BuildArch: noarch

%description
DISTDESCR

%prep
%setup -q -n %{realname}-%{version} 

%build
yes | %{__perl} Makefile.PL -n INSTALLDIRS=vendor
%make

%check
#make test

%install
rm -rf $RPM_BUILD_ROOT
%makeinstall_std

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
DISTDOC
%{_mandir}
%perl_vendorlib
#DISTEXTRA


%changelog

__END__


=head1 NAME

CPANPLUS::Dist::Mdv - a cpanplus backend to build mandriva rpms



=head1 SYNOPSYS

    cpan2dist --format=CPANPLUS::Dist::Mdv Some::Random::Package



=head1 DESCRIPTION

CPANPLUS::Dist::Mdv is a distribution class to create mandriva packages
from CPAN modules, and all its dependencies. This allows you to have
the most recent copies of CPAN modules installed, using your package
manager of choice, but without having to wait for central repositories
to be updated.

You can either install them using the API provided in this package, or
manually via rpm.

Some of the bleading edge CPAN modules have already been turned into
mandriva packages for you, and you can make use of them by adding the
cooker repositories (main & contrib).

Note that these packages are built automatically from CPAN and are
assumed to have the same license as perl and come without support.
Please always refer to the original CPAN package if you have questions.



=head1 CLASS METHODS

=head2 $bool = CPANPLUS::Dist::Mdv->format_available;

Return a boolean indicating whether or not you can use this package to
create and install modules in your environment.

It will verify if you are on a mandriva system, and if you have all the
necessary components avialable to build your own mandriva packages. You
will need at least these dependencies installed: C<rpm>, C<rpmbuild> and
C<gcc>.



=head1 PUBLIC METHODS

=head2 $bool = $mdv->init;

Sets up the C<CPANPLUS::Dist::Mdv> object for use. Effectively creates
all the needed status accessors.

Called automatically whenever you create a new C<CPANPLUS::Dist> object.


=head2 $boot = $mdv->prepare;

Prepares a distribution for creation. This means it will create the rpm
spec file needed to build the rpm and source rpm. This will also satisfy
any prerequisites the module may have.

Returns true on success and false on failure.

You may then call C<< $mdv->create >> on the object to create the rpm
from the spec file, and then C<< $mdv->install >> on the object to
actually install it.


=head2 $bool = $mdv->create;

Builds the rpm file from the spec file created during the C<create()>
step.

Returns true on success and false on failure.

You may then call C<< $mdv->install >> on the object to actually install it.


=head2 $bool = $mdv->install;

Installs the rpm using C<rpm -U>.

B</!\ Work in progress: not implemented.>

Returns true on success and false on failure



=head1 TODO

There are no TODOs of a technical nature currently, merely of an
administrative one;

=over

=item o Scan for proper license

Right now we assume that the license of every module is C<the same
as perl itself>. Although correct in almost all cases, it should 
really be probed rather than assumed.


=item o Long description

Right now we provided the description as given by the module in it's
meta data. However, not all modules provide this meta data and rather
than scanning the files in the package for it, we simply default to the
name of the module.


=back



=head1 BUGS

Please report any bugs or feature requests to C<< < cpanplus-dist-mdv at
rt.cpan.org> >>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-Mdv>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.



=head1 SEE ALSO

L<CPANPLUS::Backend>, L<CPANPLUS::Module>, L<CPANPLUS::Dist>,
C<cpan2dist>, C<rpm>, C<urpmi>


C<CPANPLUS::Dist::Mdv> development takes place on
L<http://cpanplus-dist-mdv.googlecode.com> - feel free to join us.


You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPANPLUS-Dist-Mdv>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPANPLUS-Dist-Mdv>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPANPLUS-Dist-Mdv>

=back



=head1 AUTHOR

Jerome Quelin, C<< <jquelin at cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2007 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
