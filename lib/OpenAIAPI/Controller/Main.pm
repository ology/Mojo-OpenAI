package OpenAIAPI::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use OpenAI::API ();
use Storable qw(retrieve store);

use constant DATFILE => 'openaiapi.dat';

sub index ($self) {
  store [], DATFILE unless -e DATFILE;
  my $history = retrieve(DATFILE);
  $self->render(responses => $history);
}

sub update ($self) {
  store [], DATFILE unless -e DATFILE;
  my $history = retrieve(DATFILE);
  if (@$history && (time() - $history->[0]{stamp}) < 60) {
    $self->flash(error => 'One submission per minute allowed. Please be patient.');
    return $self->redirect_to('index');
  }

  my $v = $self->validation;
  $v->required('prompt')->size(1, 1024);
  if ($v->error('prompt')) {
    $self->flash(error => 'Invalid submission');
    return $self->redirect_to('index');
  }

  my @responses;
  my $prompt = $v->param('prompt');

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

  for my $choice ($response->{choices}->@*) {
      my $text = $choice->{text};
      $text =~ s/^\s*|\s*$//;
      if ($text =~ /  /) {
          $text = '<pre>' . $text . '</pre>';
      }
      else {
          $text =~ s/\n+/<p><\/p>/g;
      }
      push @responses, { prompt => $prompt, text => $text, stamp => time() };
  }

  $history = [ grep { defined $_ } @$history ];
  unshift @$history, @responses;
  my $n = $#$history > 19 ? 19 : $#$history;
  $history = [ @$history[0 .. $n] ];
  store $history, DATFILE;

  $self->redirect_to('index');
}

sub help ($self) { $self->render }

1;
