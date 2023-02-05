package OpenAIAPI::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Geo::IP::PurePerl;
use OpenAI::API ();
use Storable qw(retrieve store);

use constant DATFILE => 'openaiapi.dat';
use constant GEODAT  => $ENV{HOME} . '/geoip/GeoLiteCity.dat';

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

  my @responses;

  my $openai = OpenAI::API->new(api_key => $self->config('api-key'));
  my $response = $openai->completions(
      prompt            => $prompt,
      model             => 'text-davinci-003',#'code-davinci-002',
      max_tokens        => 2048,
      temperature       => 0.5,
      top_p             => 1,
      frequency_penalty => 0,
      presence_penalty  => 0,
  );

  $prompt =~ s/\n+/<p><\/p>/g;

  my $ip = $self->tx->remote_address;
  my $gi = Geo::IP::PurePerl->new(GEODAT, GEOIP_STANDARD);
  my @location = $gi->get_city_record($ip);
  my $location = @location
      ? join(', ', grep { $_ ne '' } @location[4,3,2])
      : $ip;
  $location =~ s/, United States//;

  for my $choice ($response->{choices}->@*) {
      my $text = $choice->{text};
      $text =~ s/^\s*|\s*$//;
      if ($text =~ /  /) {
          $text = '<pre>' . $text . '</pre>';
      }
      else {
          $text =~ s/\n+/<p><\/p>/g;
      }
      push @responses, {
        prompt => $prompt,
        text   => $text,
        stamp  => time(),
        ip     => $ip,
        geo    => $location,
      };
  }

  $history = [ grep { defined $_ } @$history ];
  unshift @$history, @responses;
  my $n = $#$history > 19 ? 19 : $#$history; # only save the last 20
  $history = [ @$history[0 .. $n] ];
  store $history, DATFILE;

  $self->redirect_to('index');
}

sub help ($self) { $self->render }

1;
