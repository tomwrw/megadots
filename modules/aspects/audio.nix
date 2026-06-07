{ ... }:
{
  # PipeWire audio stack (replaces PulseAudio). Realtime scheduling is granted
  # by rtkit, enabled in the `security` aspect.
  den.aspects.audio.nixos =
    { ... }:
    {
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };
}
