{ ... }:
{
  services.kanshi = {
    enable = true;
    profiles.default.outputs = [
      {
        criteria = "HDMI-A-2";
        mode = "1920x1080@120Hz";
        position = "0,0";
      }
      {
        criteria = "HDMI-A-1";
        mode = "1920x1080@120Hz";
        position = "1920,0";
        transform = "90";
      }
    ];
  };
}
