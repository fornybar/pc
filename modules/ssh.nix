{
  # Avoid ssh timeout
  programs.ssh.extraConfig = ''
    Host *
	  ServerAliveInterval 100
  '';
}