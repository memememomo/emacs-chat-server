use strict;
use warnings;
use utf8;
use Amon2::Lite;
use Digest::MD5 ();


my %tag_stamp = (
    'stamp1' => 'stamp1.png',
    'stamp2' => 'stamp2.png',
);


get '/' => sub {
    my ($c, $args) = @_;
    my %args = (
        path => 'ws://'. $c->req->{env}->{HTTP_HOST} . '/chat/web',
    );
    return $c->render('index.tt', \%args);
};


my $clients = {};
any '/chat/:client_type' => sub {
    my ($c, $args) = @_;
    my $id = Digest::SHA1::sha1_hex(rand() . $$ . {} . time);

    $c->websocket(
        sub {
            my $ws = shift;
            $clients->{$id} = {
                socket     => $ws,
                type       => $args->{'client_type'},
                stamp_dir => './',
            };

            $ws->on_receive_message(
                sub {
                    my ($c, $original_message) = @_;

                    if ( $original_message =~ /^\:(.+?)\s/ ) {
                        my $cmd = $1;
                        if ( exec_command($clients->{$id}, $cmd, $original_message) ) {
                            return;
                        }
                    }

                    for my $id (keys %$clients) {
                        my $client = $clients->{$id};

                        my $message = $original_message;

                        if ( $client->{type} eq 'web' ) {
                            while ( $message =~ /\{(.+?)\}/g ) {
                                my $tag = $1;
                                if ( my $stamp = $tag_stamp{$tag} ) {
                                    $message =~ s#\{(.+?)\}#<img src="/static/stamp/$stamp"/>#g;
                                }
                            }
                        }
                        elsif ( $client->{type} eq 'emacs' ) {
                            my $path = $client->{stamp_dir};
                            while ( $message =~ /\{(.+?)\}/g ) {
                                my $tag = $1;
                                if ( my $stamp = $tag_stamp{$tag} ) {
                                    $message =~ s#\{$tag\}#[[$path/$stamp]]#g;
                                }
                            }
                        }

                        $client->{socket}->send_message(
                            "$message"
                        );
                    }
                }
            );
            $ws->on_eof(
                sub {
                    my ($c) = @_;
                    delete $clients->{$id};
                }
            );
            $ws->on_error(
                sub {
                    my ($c) = @_;
                    delete $clients->{$id};
                }
            );
        }
    );
};


sub exec_command {
    my ($client, $cmd, $message) = @_;

    if ( $cmd eq 'set_stamp_dir' ) {
        my ($cmd, $path) = split /\s+/, $message;
        $client->{stamp_dir} = $path;
        return 1;
    }
}


# load plugins
__PACKAGE__->load_plugin('Web::WebSocket');
__PACKAGE__->enable_middleware('AccessLog');
__PACKAGE__->enable_middleware('Lint');

__PACKAGE__->to_app(handle_static => 1);

