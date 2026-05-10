Vagrant.configure("2") do |config|

  # ── VICTIM ──────────────────────────────────
  config.vm.define "victim" do |victim|
    victim.vm.box = "ubuntu/jammy64"
    victim.vm.hostname = "victim"
    victim.vm.network "private_network", ip: "192.168.56.20"

    victim.vm.provider "virtualbox" do |vb|
      vb.name = "CTF-Victim"
      vb.memory = "512"
    end

    victim.vm.provision "shell", path: "setup_victim.sh"
  end

  # ── ATTACKER ────────────────────────────────
  config.vm.define "attacker" do |attacker|
    attacker.vm.box = "ubuntu/jammy64"
    attacker.vm.hostname = "attacker"
    attacker.vm.network "private_network", ip: "192.168.56.10"

    attacker.vm.provider "virtualbox" do |vb|
      vb.name = "CTF-Attacker"
      vb.memory = "512"
    end

    attacker.vm.provision "shell", path: "setup_attacker.sh"
  end

end