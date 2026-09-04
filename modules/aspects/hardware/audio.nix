_: {
  # PipeWire, replacing PulseAudio, with ALSA and JACK compatibility.
  den.aspects.audio.nixos = _: {
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
