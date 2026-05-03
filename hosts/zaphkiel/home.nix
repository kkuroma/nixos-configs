{ ... }:
{
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "default";
        profile.outputs = [
          {
            criteria = "HDMI-A-1";
            mode = "1920x1080@120Hz";
            position = "0,0";
            transform = "90";
          }
          {
            criteria = "HDMI-A-2";
            mode = "1920x1080@120Hz";
            position = "1080,700";
          }
        ];
      }
    ];
  };
}
