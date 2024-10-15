package OpenAIAPI::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Capture::Tiny qw(capture_stdout);
# use Geo::IP::PurePerl;
use JSON::MaybeXS qw(encode_json);
use Storable qw(retrieve store);

use constant DATFILE => 'openaiapi.dat';
# use constant GEODAT  => $ENV{HOME} . '/geoip/GeoLiteCity.dat';

sub index ($self) {
  my $prompt = $self->param('last_prompt') || '';
  store [], DATFILE unless -e DATFILE;
  my $history = retrieve(DATFILE);
  $self->render(
    responses   => $history,
    last_prompt => $prompt,
  );
}

sub update ($self) {
  my $v = $self->validation;
  $v->required('prompt')->size(1, 1024);
  if ($v->error('prompt')) {
    $self->flash(error => 'Invalid submission');
    return $self->redirect_to('index');
  }
  my $prompt = $v->param('prompt');

  store [], DATFILE unless -e DATFILE;
  my $history = retrieve(DATFILE);
  if (@$history && (time() - $history->[0]{stamp}) < 60) {
    $self->flash(error => 'One submission per minute allowed. Please be patient.');
    return $self->redirect_to($self->url_for('index')->query(last_prompt => $prompt));
  }

  my $response = _get_response('user', $prompt);

  $prompt =~ s/\n+/<p><\/p>/g;
  $response =~ s/\n+/<p><\/p>/g;

  # my $ip = $self->tx->remote_address;
  # my $gi = Geo::IP::PurePerl->new(GEODAT, GEOIP_STANDARD);
  # my @location = $gi->get_city_record($ip);
  # my $location = @location
      # ? join(', ', grep { $_ ne '' } @location[4,3,2])
      # : $ip;
  # $location =~ s/, United States//;

  my @responses;
  push @responses, {
    prompt => $prompt,
    text   => $response,
    stamp  => time(),
    ip     => '', #$ip,
    geo    => '', #$location,
  };

  $history = [ grep { defined $_ } @$history ];
  unshift @$history, @responses;
  my $n = $#$history > 19 ? 19 : $#$history; # only save the last 20
  $history = [ @$history[0 .. $n] ];
  store $history, DATFILE;

  $self->redirect_to('index');
}

sub help ($self) { $self->render }

sub _get_response ($role, $prompt) {
  return unless $prompt;
  my @message = { role => $role, content => $prompt };
  my $json_string = encode_json([@message]);
  my @cmd = (qw(python3 script/chat.py), $json_string);
  my $stdout = capture_stdout { system(@cmd) };
  chomp $stdout;
  return $stdout;
}

1;
