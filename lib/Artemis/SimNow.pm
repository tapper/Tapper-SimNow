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

our $VERSION = '1.000036';


=head1 SYNOPSIS

Artemis::SimNow controls running SimNow session with Artemis. With this
module Artemis is able to treat similar to virtualisation tests.

    use Artemis::SimNow;

    my $simnow = Artemis::SimNow->new();
    $simnow->run();

=head1 FUNCTIONS

=head2 get_static_tap_headers

Create a report hash that contains all headers that don't need to be
produced somehow. This includes suite-name and suite-version for
example.

@return string - tap headers

=cut

sub get_static_tap_headers
{
        my ($self, $report) = @_;
        $report->{headers}{'Artemis-reportgroup-testrun'} = $self->cfg->{test_run};
        $report->{headers}{'Artemis-suite-name'}          = "SimNow-Metainfo";
        $report->{headers}{'Artemis-suite-version'}       = $VERSION;
        $report->{headers}{'Artemis-machine-name'}        = $self->cfg->{hostname};
        return $report;
}

=head2 generate_meta_report

Generate a report containing metainformation about the SimNow we use.

@return hash ref - report data as expected by Remote::Net->tap_report_create()

=cut

sub generate_meta_report
{

        my ($self) = @_;
        my $report;
        $report = $self->get_static_tap_headers($report);

        my $error  = 0;
        my ($success, $retval) = $self->log_and_exec($self->cfg->{paths}->{simnow_path}."/simnow","--version");
        if ($success != 1) {
                push @{$report->{tests}}, {error => 1, test => "Getting SimNow version"};
        } else {
                push @{$report->{tests}}, {test => "Getting SimNow version"};

                if ($retval =~ m/This is AMD SimNow version (\d+\.\d+\.\d+(-NDA)?)/) {
                        $report->{headers}{'Artemis-SimNow-Version'} = $1;
                } else {
                        $report->{headers}{'Artemis-SimNow-Version'} = 'Not set';
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Parsing SimNow version"};


                $error = 0;
                if ($retval =~ m/This internal release is built from revision: (.+) of SVN URL: (.+)/) {
                        $report->{headers}{'Artemis-SimNow-SVN-Version'}    =  $1;
                        $report->{headers}{'Artemis-SimNow-SVN-Repository'} =  $2;
                } elsif ($retval =~ m/Build number: (.+)/) {
                        $report->{headers}{'Artemis-SimNow-SVN-Version'}    =  $1;
                        $report->{headers}{'Artemis-SimNow-SVN-Repository'} =  'Not set';
                } else {
                        $report->{headers}{'Artemis-SimNow-SVN-Version'}    =  'Not set';
                        $report->{headers}{'Artemis-SimNow-SVN-Repository'} =  'Not set';
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Parsing SVN version"};

                $error = 0;
                if ($retval =~ m/supporting version (\d+) of the AMD SimNow Device Interface/) {
                        $report->{headers}{'Artemis-SimNow-Device-Interface-Version'} = $1;
                } else {
                        $report->{headers}{'Artemis-SimNow-Device-Interface-Version'} = 'Not set';
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Parsing device interface version"};
        }

        $error = 0;
        if (open my $fh ,"<", $self->cfg->{files}{config_file}) {
                my $content = do {local $/; <$fh>};
                close $fh;

                if ($content =~ m|open bsds/(\w+)\.bsd|) {
                        $report->{headers}{'Artemis-SimNow-BSD-File'} = $1;
                } else {
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Getting BSD file information"};

                $error = 0;
                if ($content =~ m|ide:0.image master .*/((?:\w\|\.)+?)(?:\.[a-zA-Z]+)?$|m) {
                        $report->{headers}{'Artemis-SimNow-Image-File'} = $1;
                } else {
                        $error = 1;
                }
                push @{$report->{tests}}, {error => $error, test => "Getting image file information"};

                $error = 0;
        } else {
                $report->{headers}{'Artemis-SimNow-BSD-File'} = 'Not set';
                $report->{headers}{'Artemis-SimNow-Image-File'} = 'Not set';
                $error = 1;
        }
        push @{$report->{tests}}, {error => $error, test => "Reading Simnow config file"};
        return $report;

}



=head2 create_console

Create console file for output of system under test in simnow.

@param hash ref - config

@return success - 0
@return error   - error string

=cut

sub create_console
{
        my ($self) = @_;
        $self->log->debug("Creating console links");
        my $test_run        = $self->cfg->{test_run};
        my $out_dir         = $self->cfg->{paths}{output_dir}."/$test_run/test/";
        $self->makedir($out_dir) unless -d $out_dir;
        my $outfile         = $out_dir."/simnow_console";

        # create the file, otherwise simnow can't write to it
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
        $self->log->debug("starting simnow");

        my $config_file     = $self->cfg->{files}{config_file};
        my $test_run        = $self->cfg->{test_run};
        my $out_dir         = $self->cfg->{paths}{output_dir}."/$test_run/test/";
        $self->makedir($out_dir) unless -d $out_dir;
        my $output          = $out_dir.'/simnow';

        open (STDOUT, ">>$output.stdout") or return("Can't open output file $output.stdout: $!");
        open (STDERR, ">>$output.stderr") or return("Can't open output file $output.stderr: $!");

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
        $self->log->debug("starting mediator");

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
        $self->log->info("Starting Simnow");

        my $consumer = Artemis::Remote::Config->new();
        my $config   = $consumer->get_local_data('simnow');
        die $config unless ref($config) eq 'HASH';
        my $net      = Artemis::Remote::Net->new($config);
        $self->cfg( $config );
        $net->mcp_inform("start-test");

        # simnow only runs in its own directory due to lib issues
        chdir $self->cfg->{paths}->{simnow_path};

        my $retval;
        {
                $retval = $self->kill_instance($self->cfg->{paths}->{pids_path}."/simnow.pid");
                last if $retval;

                $retval = $self->create_console();
                last if $retval;

                my $report = $self->generate_meta_report();
                my $tap = $net->tap_report_create($report);
                my $error;
                ($error, $retval) = $net->tap_report_away($tap);
                last if $error;

                $retval = $self->start_mediator();
                last if $retval;

                $retval = $self->start_simnow();
                last if $retval;

        }
        if ($retval) {
                $net->mcp_send({state => 'error-guest', error => $retval});
                $self->log->logdie($retval);
        }
        $net->mcp_inform("end-test");

        $self->log->info("Simnow prepared and running");
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
