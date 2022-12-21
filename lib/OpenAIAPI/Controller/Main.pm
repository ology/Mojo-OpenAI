package OpenAIAPI::Controller::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use OpenAI::API ();
use Storable qw(retrieve store);

use constant DATFILE => 'openaiapi.dat';

sub index ($self) {
  store [], DATFILE unless -e DATFILE;
  my $history = retrieve(DATFILE);
  $self->render(
    responses => $history,
  );
}

sub update ($self) {
  my @responses;
  my $v = $self->validation;
  $v->required('prompt')->size(1, 1024);
  my $prompt = $v->param('prompt');
  if ($v->error('prompt')) {
    $self->flash(error => 'Invalid submission');
  }
  else {
    my $openai = OpenAI::API->new(api_key => $self->config('api-key'));
    my $response = $openai->completions(
        prompt            => $prompt,
        model             => 'text-davinci-003',
        max_tokens        => 2048,
        temperature       => 0.5,
        top_p             => 1,
        frequency_penalty => 0,
        presence_penalty  => 0
    );
    for my $choice ($response->{choices}->@*) {
        $choice->{text} =~ s/^\s+//;
        $choice->{text} =~ s/\s+$//;
        (my $text = $choice->{text}) =~ s/\n/<p><\/p>/g;
        push @responses, { prompt => $prompt, text => $text, stamp => time() };
    }
    store [], DATFILE unless -e DATFILE;
    my $history = retrieve(DATFILE);
    unshift @$history, @responses;
    store $history, DATFILE;
  }
  $self->redirect_to(
    $self->url_for('index')
  );
}

sub help ($self) { $self->render }

# transform the given string into a data structure
sub _transform {
  my ($string) = @_;
  my @chunks = split /\//, ($string || '');
  my @data;
  for my $chunk (@chunks) {
    my @parts = split /\|/, $chunk;
    push @data, {
      prompt => $parts[0],
      text   => $parts[1],
      stamp  => $parts[2],
    };
  }
  return @data;
}

# remap a string from the datastructure
sub _remap {
  my (@data) = @_;
  my @remapped;
  for my $datum (@data) {
    push @remapped, join('|', $datum->{prompt}, $datum->{text}, $datum->{stamp});
  }
  return join('/', @remapped);
}

1;
