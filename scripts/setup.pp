class setup {
  $real_user = inline_template('<%= ENV["SUDO_USER"] %>')

  group { 'nix-users': ensure => present }
  group { 'input': ensure => present }

  if $real_user and $real_user != '' and $real_user != 'root' {
    user { $real_user:
      ensure     => present,
      groups     => ['nix-users', 'input'],
      membership => 'inclusive',
      require    => [Group['nix-users'], Group['input']],
    }
    notify { "Ensuring user ${real_user} is in groups [nix-users, input]": }
  } else {
    notify { "Skipping user group modification, could not determine non-root user from ENV['SUDO_USER']. Value: '${real_user}'": }
  }

  package { 'nix':
    ensure => installed,
  }

  if $real_user and $real_user != '' and $real_user != 'root' {
    $channel_name = 'nixpkgs'
    $channel_url = 'https://nixos.org/channels/nixos-25.11'

    exec { "add_nix_channel_${channel_name}":
      command => "/usr/bin/nix-channel --add ${channel_url} ${channel_name}",
      unless  => "/usr/bin/nix-channel --list | /bin/grep -qE \"^${channel_name}\\s+${channel_url}$\"",
      user    => $real_user,
      require => Package['nix'],
      notify  => Exec["update_nix_channel_${channel_name}"],
      path    => ['/bin', '/usr/bin', '/usr/sbin'],
    }

    exec { "update_nix_channel_${channel_name}":
      command => "/usr/bin/nix-channel --update ${channel_name}",
      user    => $real_user,
      require => Package['nix'],
      notify  => Exec["home_manager_switch"],
      path    => ['/bin', '/usr/bin', '/usr/sbin'],
    }

    exec { 'home_manager_switch':
      command => "/bin/su -c 'nix run --extra-experimental-features nix-command --extra-experimental-features flakes home-manager -- switch --flake \"path:/usr/local/google/home/bohdant/.config/nix\" -b backup' - ${real_user}",
      require => Exec["update_nix_channel_${channel_name}"],
      path    => ['/bin', '/usr/bin', '/usr/sbin'],
      logoutput => true,
    }
  } else {
    notify { 'Skipping Nix channel setup for root user': }
  }

  file { '/etc/modules-load.d/uinput.conf':
    ensure  => file,
    content => "uinput\n",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  exec { 'load_uinput_module':
    command => '/usr/sbin/modprobe uinput',
    unless  => '/usr/sbin/lsmod | /usr/bin/grep -q ^uinput',
    require => File['/etc/modules-load.d/uinput.conf'],
  }

  file { '/etc/udev/rules.d/input.rules':
    ensure  => file,
    content => 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Group['input'],
    notify  => [
      Exec['udevadm_reload_rules'],
      Exec['udevadm_trigger'],
    ],
  }

  exec { 'udevadm_reload_rules':
    command     => '/usr/bin/udevadm control --reload-rules',
    refreshonly => true,
  }

  exec { 'udevadm_trigger':
    command     => '/usr/bin/udevadm trigger',
    refreshonly => true,
  }

  exec { 'reboot_notice':
    command     => '/bin/echo "Bootstrap complete. A reboot may be required for all changes to take effect."',
    refreshonly => true,
    logoutput   => true,
  }

  Package['nix'] ~> Exec['reboot_notice']
  if $real_user and $real_user != '' and $real_user != 'root' {
    User[$real_user] ~> Exec['reboot_notice']
  }
}

include setup
