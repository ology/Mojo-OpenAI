package OpenAIAPI::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use OpenAI::API ();

sub index ($self) {
  my $prompt = $self->param('prompt') || '';
  my $responses = $self->every_param('responses');
  $self->render(
    prompt    => $prompt,
    responses => $responses,
  );
}

sub update ($self) {
  my $v = $self->validation;
  $v->required('prompt')->size(0, 10);
  $v->required('prompt', 'trim');
  my $prompt = $v->param('prompt');
  if ($v->error('prompt')) {
    $self->flash(error => 'Invalid prompt!');
    $prompt = '';
  }
  else {
    my $openai = OpenAI::API->new(api_key => $self->config('api-key'));
    my $response = $openai->completions(
        model             => 'text-davinci-003',
        prompt            => $prompt,
        max_tokens        => 2048,
        temperature       => 0.5,
        top_p             => 1,
        frequency_penalty => 0,
        presence_penalty  => 0
    );
    my @responses;
    for my $choice ($response->{choices}->@*) {
        push @responses, $choice->{text};
    }
  }
  $self->redirect_to(
    $self->url_for('index')->query(prompt => $prompt, responses => \@responses)
  );
}

sub help ($self) { $self->render }

1;
