use strict;
use warnings;
use utf8;
use Amon2::Lite;
use Digest::MD5 ();

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
                socket   => $ws,
                type     => $args->{'client_type'},
            };

            $ws->on_receive_message(
                sub {
                    my ($c, $original_message) = @_;

                    for my $id (keys %$clients) {
                        my $client = $clients->{$id};

                        my $message = $original_message;

                        if ( $client->{type} eq 'web' ) {
                            $message =~ s#\[\[(.+?)\]\]#<img src="/static/stamp/$1"/>#g;
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

# load plugins
__PACKAGE__->load_plugin('Web::WebSocket');
__PACKAGE__->enable_middleware('AccessLog');
__PACKAGE__->enable_middleware('Lint');

__PACKAGE__->to_app(handle_static => 1);

