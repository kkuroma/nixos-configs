{
  description = "Kali Linux At Home";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
  let pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      shellHook = ''
        export DEV_SHELL=networking
        exec $SHELL
      '';
      packages = with pkgs; [
        # recon
        nmap masscan theharvester whatweb dnsutils whois mtr
        # web
        gobuster ffuf wfuzz sqlmap nikto
        # exploit / brute
        metasploit hydra
        # passwords / wireless
        john hashcat aircrack-ng
        # network
        tcpdump wireshark netcat-gnu proxychains-ng tor
        # forensics / reversing
        steghide binwalk exiftool radare2 ghidra
      ];
    };
  };
}
