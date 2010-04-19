package Artemis::SimNow;

use Moose;
use common::sense;

use File::Basename;

use Artemis::Remote::Config;
use Artemis::Remote::Net;

extends 'Artemis::Base';

has cfg => (is      => 'rw',
            isa     => 'HashRef',
            default => sub { {} },
           );


=head1 NAME

Artemis::SimNow - Control running a SimNow session!

=head1 VERSION


=cut

our $VERSION = '1.000017';


=head1 SYNOPSIS

Artemis::SimNow controls running SimNow session with Artemis. With this
module Artemis is able to treat similar to virtualisation tests.

    use Artemis::SimNow;

    my $simnow = Artemis::SimNow->new();
    $simnow->run();

=head1 FUNCTIONS

=head2 create_console

Create console file for output of system under test in simnow.

@param hash ref - config

@return success - 0
@return error   - error string

=cut

sub create_console
{
        my ($self) = @_;
        my $test_run        = $self->cfg->{test_run};
        my $out_dir         = $self->cfg->{paths}{output_dir}."/$test_run/test/";
        $self->makedir($out_dir) unless -d $out_dir;
        my $outfile         = $out_dir."/simnow_console";
        open my $fh, ">", $outfile or return "Can not open $outfile: $!";
        close $fh;
        my $pipedir         = dirname($self->cfg->{files}{simnow_console});
        $self->makedir($pipedir) unless -d $pipedir;
        my $retval          = $self->log_and_exec("ln","-sf", $outfile, $self->cfg->{files}{simnow_console});
        return $retval;
}


=head2 start_simnow

Start the simnow process.

@param hash ref - config

@return success - 0
@return error   - error string

=cut

sub start_simnow
{
        my ($self) = @_;
        
        my $config_file     = $self->cfg->{files}{config_file};
        my $test_run        = $self->cfg->{test_run};
        my $out_dir         = $self->cfg->{paths}{output_dir}."/$test_run/test/";
        $self->makedir($out_dir) unless -d $out_dir;
        my $output          = $out_dir.'/simnow';

        open (STDOUT, ">>$output.stdout") or return("Can't open output file $output.stdout: $!");
        open (STDERR, ">>$output.stderr") or return("Can't open output file $output.stderr: $!");

        chdir $self->cfg->{paths}->{simnow_path};
        my $retval          = $self->run_one({command  => $self->cfg->{paths}->{simnow_path}."/simnow",
                                              argv     => [ "-e", $config_file, '--nogui' ],
                                              pid_file => $self->cfg->{paths}->{pids_path}."/simnow.pid",
                                             });
        return $retval;
}


=head2 start_mediator

Start the mediator process.

@param hash ref - config

@return success - 0
@return error   - error string

=cut

sub start_mediator
{
        my ($self) = @_;
        my $retval = $self->run_one({command  => $self->cfg->{paths}->{simnow_path}."/mediator",
                                     pid_file => $self->cfg->{paths}->{pids_path}."/mediator.pid",
                                    });
        return $retval;
}



=head2 run

Control a SimNow session. Handles getting config, sending status
messages to MCP and console handling.

@return success - 0
@return error   - error string


=cut

sub run
{
        my ($self) = @_;
        my $consumer = Artemis::Remote::Config->new();
        my $net      = Artemis::Remote::Net->new();
        my $config   = $consumer->get_local_data('simnow');
        die $config unless ref($config) eq 'HASH';
        $self->cfg( $config );
        $net->mcp_inform("start-test");

        my $retval;
        $retval = $self->create_console();
        $retval = $self->start_mediator();
        $retval = $self->start_simnow();

        $net->mcp_inform("end-test");
        return 0;
}


=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 OSRC SysInt Team, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Artemis::SimNow
