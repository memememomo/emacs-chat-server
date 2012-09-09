use strict;
use warnings;
use utf8;
use Amon2::Lite;
use Digest::MD5 ();


get '/' => sub {
    my $c = shift;
    my %args = (
        path => 'ws://'. $c->req->{env}->{HTTP_HOST} . '/chat/web'
    );
    return $c->render('index.tt', \%args);
};



my $clients = {};
any '/chat/:client_type' => sub {
    my ($c) = @_;
    my $id = Digest::SHA1::sha1_hex(rand() . $$ . {} . time);

    $c->websocket(
        sub {
            my $ws = shift;
            $clients->{$id} = {
                socket => $ws,
                type   => $c->req->param('client_type'),
            };

            $ws->on_receive_message(
                sub {
                    my ($c, $message) = @_;
                    for (keys %$clients) {
                        $clients->{$_}->{socket}->send_message(
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

