{ config, ... }:
{
  # Vivaldi custom UI CSS (Settings → Appearance → Custom UI Modifications)
  xdg.configFile."vivaldi-theme/theme.css".text =
    let
      ui = config.rice.fonts.ui;
      mono = config.rice.fonts.mono;
    in ''
      /* vivaldi font override bc funny hehe */
      * {
        font-family: '${ui}', system-ui, sans-serif !important;
      }

      /* keep icons from breaking */
      .vds-icon,
      .button-icon,
      [class^="icon-"] {
        font-family: 'Vivaldi Icons', vivaldi !important;
      }
    '';
}
