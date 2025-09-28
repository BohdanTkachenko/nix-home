{
  programs.manage-flatpaks = {
    enable = true;
    onUnmanaged = "delete";
    packages = [
      "com.brave.Browser"
      "com.github.tchx84.Flatseal"
      "com.google.Chrome"
      "com.mattjakeman.ExtensionManager"
      "com.ranfdev.DistroShelf"
      "com.spotify.Client"
      "dev.alextren.Spot"
      "hu.irl.cameractrls"
      "io.github.flattool.Warehouse"
      "io.missioncenter.MissionCenter"
      "it.mijorus.gearlever"
      "org.altlinux.Tuner"
      "org.gnome.baobab"
      "org.gnome.Calculator"
      "org.gnome.Calendar"
      "org.gnome.Characters"
      "org.gnome.clocks"
      "org.gnome.Contacts"
      "org.gnome.font-viewer"
      "org.gnome.Logs"
      "org.gnome.Loupe"
      "org.gnome.NautilusPreviewer"
      "org.gnome.Papers"
      "org.gnome.TextEditor"
      "org.gnome.Weather"
      "org.mozilla.firefox"
    ];
  };
}
