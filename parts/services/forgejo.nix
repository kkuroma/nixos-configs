{ config, lib, pkgs, ... }:
let
  cfg = config.host.services.forgejo or null;
  customDir = "${config.services.forgejo.stateDir}/custom";
  fontFile = ../../config/fonts/GoogleSansFlex-VariableFont.ttf;
  mapleTtf = "${pkgs.maple-mono.truetype}/share/fonts/truetype"; # plain Maple Mono (~260K/weight); self-host Regular+Bold
  iconPng = pkgs.runCommand "forgejo-icon.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    convert ${./icon.webp} $out
  '';
  # Forgejo requests logo.svg/favicon.svg first; source is raster (.webp) → vectorize with vtracer.
  # vtracer omits viewBox, so the SVG can't rasterize as a tab favicon — inject one from width/height.
  iconSvg = pkgs.runCommand "forgejo-icon.svg" { nativeBuildInputs = [ pkgs.libwebp pkgs.vtracer ]; } ''
    dwebp ${./icon.webp} -o icon.png
    vtracer -i icon.png -o raw.svg --mode spline --filter_speckle 4 --color_precision 6
    sed -E 's/(width="([0-9]+)" height="([0-9]+)")/\1 viewBox="0 0 \2 \3"/' raw.svg > $out
  '';

  # Standalone Forgejo theme — placed at {customDir}/public/assets/css/theme-natsumikan.css
  # and declared in ui.THEMES so Forgejo registers it.
  themeCSS = pkgs.writeText "theme-natsumikan.css" ''
    @font-face {
      font-family: 'Google Sans Flex';
      src: url('/assets/fonts/GoogleSansFlex-VariableFont.ttf') format('truetype');
      font-weight: 100 900;
      font-style: normal;
      font-display: swap;
    }

    :root {
      /* Natsumikan dark surface scale */
      --ns-900: #0A0C12;
      --ns-850: #0D1017;
      --ns-800: #101520;
      --ns-750: #141A22;
      --ns-700: #171D26;
      --ns-650: #1D2530;
      --ns-600: #222C38;
      --ns-550: #242C3A;
      --ns-500: #2C3545;
      --ns-450: #384250;
      --ns-400: #454F5E;
      --ns-350: #535D6D;
      --ns-300: #626C7C;
      --ns-250: #717C8C;
      --ns-200: #8E959E;
      --ns-150: #B0B8C1;
      --ns-100: #D1D1C7;

      /* Map steel-* to ns-* so any steel references in base CSS still resolve */
      --steel-900: var(--ns-900);
      --steel-850: var(--ns-850);
      --steel-800: var(--ns-800);
      --steel-750: var(--ns-750);
      --steel-700: var(--ns-700);
      --steel-650: var(--ns-650);
      --steel-600: var(--ns-600);
      --steel-550: var(--ns-550);
      --steel-500: var(--ns-500);
      --steel-450: var(--ns-450);
      --steel-400: var(--ns-400);
      --steel-350: var(--ns-350);
      --steel-300: var(--ns-300);
      --steel-250: var(--ns-250);
      --steel-200: var(--ns-200);
      --steel-150: var(--ns-150);
      --steel-100: var(--ns-100);

      --is-dark-theme: true;

      /* Primary — Natsumikan orange */
      --color-primary:           #F5803E;
      --color-primary-contrast:  #0D1017;
      --color-primary-dark-1:    #F9B070;
      --color-primary-dark-2:    #F9B070;
      --color-primary-dark-3:    #FAC090;
      --color-primary-dark-4:    #FAC090;
      --color-primary-dark-5:    #FBD0B0;
      --color-primary-dark-6:    #FBD0B0;
      --color-primary-dark-7:    #FDE8D5;
      --color-primary-light-1:   #F06428;
      --color-primary-light-2:   #E04D10;
      --color-primary-light-3:   #C43D00;
      --color-primary-light-4:   #A33000;
      --color-primary-light-5:   #A33000;
      --color-primary-light-6:   #852500;
      --color-primary-light-7:   #852500;
      --color-primary-alpha-10:  #F5803E19;
      --color-primary-alpha-20:  #F5803E33;
      --color-primary-alpha-30:  #F5803E4B;
      --color-primary-alpha-40:  #F5803E66;
      --color-primary-alpha-50:  #F5803E80;
      --color-primary-alpha-60:  #F5803E99;
      --color-primary-alpha-70:  #F5803EB3;
      --color-primary-alpha-80:  #F5803ECC;
      --color-primary-alpha-90:  #F5803EE1;
      --color-primary-hover:     var(--color-primary-light-1);
      --color-primary-active:    var(--color-primary-light-2);

      /* Secondary */
      --color-secondary:          var(--ns-700);
      --color-secondary-dark-1:   var(--ns-550);
      --color-secondary-dark-2:   var(--ns-500);
      --color-secondary-dark-3:   var(--ns-450);
      --color-secondary-dark-4:   var(--ns-400);
      --color-secondary-dark-5:   var(--ns-350);
      --color-secondary-dark-6:   var(--ns-300);
      --color-secondary-dark-7:   var(--ns-250);
      --color-secondary-dark-8:   var(--ns-200);
      --color-secondary-dark-9:   var(--ns-150);
      --color-secondary-dark-10:  var(--ns-100);
      --color-secondary-dark-11:  var(--ns-100);
      --color-secondary-dark-12:  var(--ns-100);
      --color-secondary-dark-13:  var(--ns-100);
      --color-secondary-light-1:  var(--ns-650);
      --color-secondary-light-2:  var(--ns-700);
      --color-secondary-light-3:  var(--ns-750);
      --color-secondary-light-4:  var(--ns-800);
      --color-secondary-alpha-10: #1D253019;
      --color-secondary-alpha-20: #1D253033;
      --color-secondary-alpha-30: #1D25304B;
      --color-secondary-alpha-40: #1D253066;
      --color-secondary-alpha-50: #1D253080;
      --color-secondary-alpha-60: #1D253099;
      --color-secondary-alpha-70: #1D2530B3;
      --color-secondary-alpha-80: #1D2530CC;
      --color-secondary-alpha-90: #1D2530E1;
      --color-secondary-hover:    var(--color-secondary-light-1);
      --color-secondary-active:   var(--color-secondary-light-2);

      /* Semantic colors */
      --color-red:          #b91c1c;
      --color-orange:       #F5803E;
      --color-yellow:       #ca8a04;
      --color-olive:        #91a313;
      --color-green:        #15803d;
      --color-teal:         #0d9488;
      --color-blue:         #2563eb;
      --color-violet:       #7c3aed;
      --color-purple:       #9333ea;
      --color-pink:         #db2777;
      --color-brown:        #a47252;
      --color-grey:         var(--ns-500);
      --color-black:        #111827;
      --color-red-light:    #FF5370;
      --color-orange-light: #F5803E;
      --color-yellow-light: #FFB454;
      --color-olive-light:  #839311;
      --color-green-light:  #AAD94C;
      --color-teal-light:   #39BAE6;
      --color-blue-light:   #82AAFF;
      --color-violet-light: #C792EA;
      --color-purple-light: #C792EA;
      --color-pink-light:   #ec4899;
      --color-brown-light:  #94674a;
      --color-grey-light:   var(--ns-300);
      --color-black-light:  #1f2937;
      --color-red-dark-1:   #a71919;
      --color-orange-dark-1:#d34f0b;
      --color-yellow-dark-1:#b67c04;
      --color-green-dark-1: #137337;
      --color-teal-dark-1:  #0c857a;
      --color-blue-dark-1:  #1554e0;
      --color-violet-dark-1:#6a1feb;
      --color-purple-dark-1:#8519e7;
      --color-red-dark-2:   #941616;
      --color-orange-dark-2:#bb460a;
      --color-yellow-dark-2:#ca8a04;
      --color-green-dark-2: #15803d;
      --color-teal-dark-2:  #0a766d;
      --color-blue-dark-2:  #2563eb;
      --color-violet-dark-2:#5c14d8;
      --color-purple-dark-2:#7c3aed;
      --color-black-dark-1: #0f1623;
      --color-black-dark-2: #111827;

      /* Console / terminal */
      --color-console-fg:           #eeeff2;
      --color-console-fg-subtle:    #959cab;
      --color-console-bg:           var(--ns-650);
      --color-console-border:       var(--ns-500);
      --color-console-hover-bg:     #ffffff16;
      --color-console-active-bg:    var(--ns-450);
      --color-console-menu-bg:      var(--ns-500);
      --color-console-menu-border:  var(--ns-400);
      --color-ansi-black:           #1d2328;
      --color-ansi-red:             #FF5370;
      --color-ansi-green:           #AAD94C;
      --color-ansi-yellow:          #FFB454;
      --color-ansi-blue:            #82AAFF;
      --color-ansi-magenta:         #C792EA;
      --color-ansi-cyan:            #39BAE6;
      --color-ansi-white:           var(--color-console-fg-subtle);
      --color-ansi-bright-black:    #424851;
      --color-ansi-bright-red:      #FF5370;
      --color-ansi-bright-green:    #C3E88D;
      --color-ansi-bright-yellow:   #F5803E;
      --color-ansi-bright-blue:     #82AAFF;
      --color-ansi-bright-magenta:  #C792EA;
      --color-ansi-bright-cyan:     #89DDFF;
      --color-ansi-bright-white:    var(--color-console-fg);

      /* Diff */
      --color-diff-removed-word-bg:   #783030;
      --color-diff-added-word-bg:     #255c39;
      --color-diff-removed-row-bg:    #432121;
      --color-diff-moved-row-bg:      #825718;
      --color-diff-added-row-bg:      #1b3625;
      --color-diff-removed-row-border:#783030;
      --color-diff-moved-row-border:  #a67a1d;
      --color-diff-added-row-border:  #255c39;
      --color-diff-inactive:          var(--ns-650);

      /* Status */
      --color-error-border:     #783030;
      --color-error-bg:         #5f2525;
      --color-error-bg-active:  #783030;
      --color-error-bg-hover:   #783030;
      --color-error-text:       #fef2f2;
      --color-success-border:   #1f6e3c;
      --color-success-bg:       #1d462c;
      --color-success-text:     #aef0c2;
      --color-warning-border:   #a67a1d;
      --color-warning-bg:       #644821;
      --color-warning-text:     #fff388;
      --color-info-border:      #2e50b0;
      --color-info-bg:          #2a396b;
      --color-info-text:        var(--ns-100);

      /* Badges */
      --color-red-badge:              #b91c1c;
      --color-red-badge-bg:           #b91c1c22;
      --color-red-badge-hover-bg:     #b91c1c44;
      --color-green-badge:            #16a34a;
      --color-green-badge-bg:         #16a34a22;
      --color-green-badge-hover-bg:   #16a34a44;
      --color-yellow-badge:           #ca8a04;
      --color-yellow-badge-bg:        #ca8a0422;
      --color-yellow-badge-hover-bg:  #ca8a0444;
      --color-orange-badge:           #F5803E;
      --color-orange-badge-bg:        #F5803E22;
      --color-orange-badge-hover-bg:  #F5803E44;

      /* Layout */
      --color-git:                #f05133;
      --color-icon-green:         #3fb950;
      --color-icon-red:           #f85149;
      --color-icon-purple:        #C792EA;
      --color-gold:               #b1983b;
      --color-white:              #ffffff;
      --color-pure-black:         #000000;
      --color-body:               var(--ns-850);
      --color-box-header:         var(--ns-700);
      --color-box-body:           var(--ns-750);
      --color-box-body-highlight: var(--ns-650);
      --color-text-dark:          #fff;
      --color-text:               var(--ns-100);
      --color-text-light:         var(--ns-150);
      --color-text-light-1:       var(--ns-150);
      --color-text-light-2:       var(--ns-200);
      --color-text-light-3:       var(--ns-200);
      --color-footer:             var(--ns-900);
      --color-timeline:           var(--ns-650);
      --color-input-text:         var(--ns-100);
      --color-input-background:   var(--ns-650);
      --color-input-toggle-background: var(--ns-650);
      --color-input-border:       var(--ns-550);
      --color-input-border-hover: var(--ns-450);
      --color-header-wrapper:     var(--ns-900);
      --color-header-wrapper-transparent: #0A0C1200;
      --color-light:              #00000028;
      --color-light-border:       #ffffff28;
      --color-hover:              var(--ns-600);
      --color-active:             var(--ns-650);
      --color-menu:               var(--ns-700);
      --color-card:               var(--ns-700);
      --color-markup-table-row:   #ffffff06;
      --color-markup-code-block:  var(--ns-800);
      --color-markup-code-inline: var(--ns-850);
      --color-button:             var(--ns-600);
      --color-code-bg:            var(--ns-750);
      --color-shadow:             #00000060;
      --color-secondary-bg:       var(--ns-700);
      --color-text-focus:         #fff;
      --color-expand-button:      var(--ns-550);
      --color-placeholder-text:   var(--color-text-light-3);
      --color-editor-line-highlight: var(--ns-700);
      --color-project-board-bg:   var(--color-secondary-light-3);
      --color-project-board-dark-label: var(--color-text-light-3);
      --color-caret:              var(--color-text);
      --color-reaction-bg:        #ffffff12;
      --color-reaction-active-bg: var(--color-primary-alpha-30);
      --color-reaction-hover-bg:  var(--color-primary-alpha-40);
      --color-tooltip-text:       #ffffff;
      --color-tooltip-bg:         #000000f0;
      --color-nav-bg:             var(--ns-900);
      --color-nav-hover-bg:       var(--ns-600);
      --color-nav-text:           var(--color-text);
      --color-secondary-nav-bg:   var(--color-body);
      --color-label-text:         #fff;
      --color-label-bg:           var(--ns-600);
      --color-label-hover-bg:     var(--ns-550);
      --color-label-active-bg:    var(--ns-500);
      --color-label-bg-alt:       var(--ns-550);
      --color-accent:             var(--color-primary-light-1);
      --color-small-accent:       var(--color-primary-light-5);
      --color-highlight-fg:       var(--color-primary-light-4);
      --color-highlight-bg:       var(--color-primary-alpha-20);
      --color-overlay-backdrop:   #080808c0;
      --checkerboard-color-1:     #474747;
      --checkerboard-color-2:     #313131;

      accent-color: var(--color-accent);
      color-scheme: dark;
    }

    * { font-family: 'Google Sans Flex', system-ui, sans-serif !important; }
    code, pre, kbd, .mono { font-family: 'Maple Mono NF CN', monospace !important; }
  '';

  # Haruhana — Material Design 3 palette (config/noctalia/palettes/Haruhana.json) mapped to
  # Forgejo vars. Google Sans Flex UI, Maple Mono code, ANSI + chroma from the palette terminal block.
  haruhanaCSS = pkgs.writeText "theme-haruhana.css" ''
    @font-face {
      font-family: 'Google Sans Flex';
      src: url('/assets/fonts/GoogleSansFlex-VariableFont.ttf') format('truetype');
      font-weight: 100 900; font-style: normal; font-display: swap;
    }
    @font-face {
      font-family: 'Maple Mono';
      src: url('/assets/fonts/MapleMono-Regular.ttf') format('truetype');
      font-weight: 400; font-style: normal; font-display: swap;
    }
    @font-face {
      font-family: 'Maple Mono';
      src: url('/assets/fonts/MapleMono-Bold.ttf') format('truetype');
      font-weight: 700; font-style: normal; font-display: swap;
    }

    :root {
      /* Haruhana neutral scale (deep navy surface -> text) */
      --h-0:  #090B15;  /* nav / footer / code bg */
      --h-1:  #0C0F1E;  /* body (mSurface) */
      --h-2:  #11162A;  /* elevated */
      --h-3:  #171D36;  /* box body (mSurfaceVariant) */
      --h-4:  #1C2340;  /* box header / active */
      --h-5:  #232E4C;  /* borders (mOutline) */
      --h-6:  #2B3758;  /* border hover (selectionBg) */
      --h-7:  #374472;
      --h-8:  #45537F;
      --h-9:  #5A6788;  /* placeholder / comments */
      --h-10: #8B95A8;  /* muted text (mOnSurfaceVariant) */
      --h-11: #A8B0C0;
      --h-12: #C4C8DC;
      --h-13: #D4D0EA;  /* text (mOnSurface) */

      --is-dark-theme: true;

      /* Primary — Haruhana pink (mPrimary). dark-N lighter, light-N darker (Forgejo dark convention) */
      --color-primary:           #F07898;
      --color-primary-contrast:  #0C0F1E;
      --color-primary-dark-1:    #F28AA5;
      --color-primary-dark-2:    #F49CB3;
      --color-primary-dark-3:    #F6AEC1;
      --color-primary-dark-4:    #F8C0CF;
      --color-primary-dark-5:    #FAD2DC;
      --color-primary-dark-6:    #FCE4EA;
      --color-primary-dark-7:    #FEF3F6;
      --color-primary-light-1:   #E56488;
      --color-primary-light-2:   #D75478;
      --color-primary-light-3:   #C34868;
      --color-primary-light-4:   #A93C58;
      --color-primary-light-5:   #8F3148;
      --color-primary-light-6:   #762739;
      --color-primary-light-7:   #5E1F2E;
      --color-primary-alpha-10:  #F0789819;
      --color-primary-alpha-20:  #F0789833;
      --color-primary-alpha-30:  #F078984B;
      --color-primary-alpha-40:  #F0789866;
      --color-primary-alpha-50:  #F0789880;
      --color-primary-alpha-60:  #F0789899;
      --color-primary-alpha-70:  #F07898B3;
      --color-primary-alpha-80:  #F07898CC;
      --color-primary-alpha-90:  #F07898E1;
      --color-primary-hover:     var(--color-primary-light-1);
      --color-primary-active:    var(--color-primary-light-2);

      /* Secondary — neutral surface scale */
      --color-secondary:          var(--h-4);
      --color-secondary-dark-1:   var(--h-6);
      --color-secondary-dark-2:   var(--h-7);
      --color-secondary-dark-3:   var(--h-8);
      --color-secondary-dark-4:   var(--h-9);
      --color-secondary-dark-5:   var(--h-10);
      --color-secondary-dark-6:   var(--h-11);
      --color-secondary-dark-7:   var(--h-11);
      --color-secondary-dark-8:   var(--h-12);
      --color-secondary-dark-9:   var(--h-12);
      --color-secondary-dark-10:  var(--h-13);
      --color-secondary-dark-11:  var(--h-13);
      --color-secondary-dark-12:  var(--h-13);
      --color-secondary-dark-13:  var(--h-13);
      --color-secondary-light-1:  var(--h-3);
      --color-secondary-light-2:  var(--h-2);
      --color-secondary-light-3:  var(--h-1);
      --color-secondary-light-4:  var(--h-0);
      --color-secondary-alpha-10: #1C234019;
      --color-secondary-alpha-20: #1C234033;
      --color-secondary-alpha-30: #1C23404B;
      --color-secondary-alpha-40: #1C234066;
      --color-secondary-alpha-50: #1C234080;
      --color-secondary-alpha-60: #1C234099;
      --color-secondary-alpha-70: #1C2340B3;
      --color-secondary-alpha-80: #1C2340CC;
      --color-secondary-alpha-90: #1C2340E1;
      --color-secondary-hover:    var(--color-secondary-dark-1);
      --color-secondary-active:   var(--color-secondary-dark-2);

      /* Semantic — from palette ANSI (green=mSecondary, purple=mTertiary, red=mError) */
      --color-red:          #FF5370;
      --color-orange:       #F5A25D;
      --color-yellow:       #F8D06A;
      --color-olive:        #6FC898;
      --color-green:        #6FC898;
      --color-teal:         #6BCAD8;
      --color-blue:         #82AAFF;
      --color-violet:       #B4A2E8;
      --color-purple:       #B4A2E8;
      --color-pink:         #F07898;
      --color-brown:        #C08A6A;
      --color-grey:         var(--h-8);
      --color-black:        #090B15;
      --color-red-light:    #FF8298;
      --color-orange-light: #F8BC86;
      --color-yellow-light: #FBDE92;
      --color-olive-light:  #A8E8C0;
      --color-green-light:  #A8E8C0;
      --color-teal-light:   #A0E0F0;
      --color-blue-light:   #A9C6FF;
      --color-violet-light: #CDBFF2;
      --color-purple-light: #CDBFF2;
      --color-pink-light:   #F49CB3;
      --color-brown-light:  #D3A98F;
      --color-grey-light:   var(--h-10);
      --color-black-light:  #171D36;
      --color-red-dark-1:   #E63E5C;
      --color-orange-dark-1:#DE8A45;
      --color-yellow-dark-1:#E0B84E;
      --color-green-dark-1: #58B082;
      --color-teal-dark-1:  #52B2C0;
      --color-blue-dark-1:  #6490E8;
      --color-violet-dark-1:#9A88D0;
      --color-purple-dark-1:#9A88D0;
      --color-red-dark-2:   #CC3450;
      --color-green-dark-2: #489870;
      --color-blue-dark-2:  #5580D8;
      --color-black-dark-1: #06070F;
      --color-black-dark-2: #090B15;

      /* Console / ANSI (faithful to palette terminal block) */
      --color-console-fg:           #D4D0EA;
      --color-console-fg-subtle:    #8B95A8;
      --color-console-bg:           #090B15;
      --color-console-border:       #232E4C;
      --color-console-hover-bg:     #ffffff12;
      --color-console-active-bg:    var(--h-4);
      --color-console-menu-bg:      var(--h-2);
      --color-console-menu-border:  var(--h-5);
      --color-ansi-black:           #090B15;
      --color-ansi-red:             #FF5370;
      --color-ansi-green:           #6FC898;
      --color-ansi-yellow:          #F8D06A;
      --color-ansi-blue:            #82AAFF;
      --color-ansi-magenta:         #B4A2E8;
      --color-ansi-cyan:            #6BCAD8;
      --color-ansi-white:           #8B95A8;
      --color-ansi-bright-black:    #424D68;
      --color-ansi-bright-red:      #FF5370;
      --color-ansi-bright-green:    #A8E8C0;
      --color-ansi-bright-yellow:   #F07898;
      --color-ansi-bright-blue:     #82AAFF;
      --color-ansi-bright-magenta:  #B4A2E8;
      --color-ansi-bright-cyan:     #A0E0F0;
      --color-ansi-bright-white:    #D4D0EA;

      /* Diff */
      --color-diff-removed-word-bg:   #5A2733;
      --color-diff-added-word-bg:     #234B37;
      --color-diff-removed-row-bg:    #2A1822;
      --color-diff-moved-row-bg:      #2A2740;
      --color-diff-added-row-bg:      #14261C;
      --color-diff-removed-row-border:#5A2733;
      --color-diff-moved-row-border:  #3A3760;
      --color-diff-added-row-border:  #234B37;
      --color-diff-inactive:          var(--h-2);

      /* Status */
      --color-error-border:     #7A2A3A;
      --color-error-bg:         #3A1E28;
      --color-error-bg-active:  #4E2634;
      --color-error-bg-hover:   #46222E;
      --color-error-text:       #FFC9D3;
      --color-success-border:   #2E6B4E;
      --color-success-bg:       #163326;
      --color-success-text:     #A8E8C0;
      --color-warning-border:   #8A7A3A;
      --color-warning-bg:       #2E2A1A;
      --color-warning-text:     #F8D06A;
      --color-info-border:      #34518A;
      --color-info-bg:          #1A2540;
      --color-info-text:        #82AAFF;

      /* Badges */
      --color-red-badge:              #FF5370;
      --color-red-badge-bg:           #FF537022;
      --color-red-badge-hover-bg:     #FF537044;
      --color-green-badge:            #6FC898;
      --color-green-badge-bg:         #6FC89822;
      --color-green-badge-hover-bg:   #6FC89844;
      --color-yellow-badge:           #F8D06A;
      --color-yellow-badge-bg:        #F8D06A22;
      --color-yellow-badge-hover-bg:  #F8D06A44;
      --color-orange-badge:           #F07898;
      --color-orange-badge-bg:        #F0789822;
      --color-orange-badge-hover-bg:  #F0789844;

      /* Layout */
      --color-git:                #f05133;
      --color-icon-green:         #6FC898;
      --color-icon-red:           #FF5370;
      --color-icon-purple:        #B4A2E8;
      --color-gold:               #F8D06A;
      --color-white:              #ffffff;
      --color-pure-black:         #000000;
      --color-body:               var(--h-1);
      --color-box-header:         var(--h-3);
      --color-box-body:           var(--h-2);
      --color-box-body-highlight: var(--h-3);
      --color-text-dark:          #F4F2FB;
      --color-text:               var(--h-13);
      --color-text-light:         var(--h-12);
      --color-text-light-1:       var(--h-11);
      --color-text-light-2:       var(--h-10);
      --color-text-light-3:       var(--h-9);
      --color-footer:             var(--h-0);
      --color-timeline:           var(--h-4);
      --color-input-text:         var(--h-13);
      --color-input-background:   var(--h-2);
      --color-input-toggle-background: var(--h-4);
      --color-input-border:       var(--h-5);
      --color-input-border-hover: var(--h-6);
      --color-header-wrapper:     var(--h-0);
      --color-header-wrapper-transparent: #090B1500;
      --color-light:              #00000028;
      --color-light-border:       #ffffff16;
      --color-hover:              #ffffff0c;
      --color-active:             var(--h-4);
      --color-menu:               var(--h-2);
      --color-card:               var(--h-2);
      --color-markup-table-row:   #ffffff06;
      --color-markup-code-block:  var(--h-0);
      --color-markup-code-inline: var(--h-3);
      --color-button:             var(--h-3);
      --color-code-bg:            var(--h-0);
      --color-shadow:             #00000070;
      --color-secondary-bg:       var(--h-3);
      --color-text-focus:         #F4F2FB;
      --color-expand-button:      var(--h-4);
      --color-placeholder-text:   var(--h-9);
      --color-editor-line-highlight: var(--h-3);
      --color-caret:              var(--color-primary);
      --color-reaction-bg:        #ffffff10;
      --color-reaction-active-bg: var(--color-primary-alpha-30);
      --color-reaction-hover-bg:  var(--color-primary-alpha-20);
      --color-tooltip-text:       #F4F2FB;
      --color-tooltip-bg:         #090B15f5;
      --color-nav-bg:             var(--h-3);
      --color-nav-hover-bg:       var(--h-4);
      --color-nav-text:           var(--h-13);
      --color-secondary-nav-bg:   var(--h-2);
      --color-label-text:         #F4F2FB;
      --color-label-bg:           var(--h-5);
      --color-label-hover-bg:     var(--h-6);
      --color-label-active-bg:    var(--h-7);
      --color-accent:             var(--color-primary);
      --color-small-accent:       var(--color-primary-alpha-30);
      --color-highlight-fg:       var(--color-primary-dark-2);
      --color-highlight-bg:       var(--color-primary-alpha-20);
      --color-overlay-backdrop:   #05070Ecc;

      /* Material 3 rounding */
      --border-radius:        8px;
      --border-radius-medium: 12px;
      --border-radius-full:   9999px;

      accent-color: var(--color-accent);
      color-scheme: dark;
    }

    /* Fonts: Google Sans Flex UI, Maple Mono code (prefers installed NF-CN, else self-hosted).
       Descendants (*) are covered so the `*` UI-font rule doesn't leak onto .chroma syntax spans. */
    * { font-family: 'Google Sans Flex', system-ui, -apple-system, sans-serif !important; }
    code, code *, pre, pre *, kbd, samp, tt, var,
    .mono, .mono *, .chroma, .chroma *,
    .file-view .lines-code, .file-view .lines-code *,
    .code-view, .code-view *, .code-inner, .code-inner *,
    .CodeMirror, .CodeMirror *, .cm-editor, .cm-editor *,
    .monaco-editor .view-lines, .monaco-editor .view-lines * {
      font-family: 'Maple Mono NF CN', 'Maple Mono', ui-monospace, SFMono-Regular, monospace !important;
    }

    /* Google-ish: pill primary actions */
    .ui.primary.button, .ui.primary.buttons .button { border-radius: var(--border-radius-full) !important; }

    /* Syntax highlighting (chroma) from the Haruhana palette */
    .chroma .c, .chroma .ch, .chroma .cm, .chroma .c1, .chroma .cs, .chroma .cp, .chroma .cpf { color: #5A6788; font-style: italic; }
    .chroma .k, .chroma .kd, .chroma .kn, .chroma .kp, .chroma .kr { color: #B4A2E8; }
    .chroma .kc, .chroma .no, .chroma .nl, .chroma .nc { color: #F8D06A; }
    .chroma .kt { color: #6BCAD8; }
    .chroma .o, .chroma .ow { color: #6BCAD8; }
    .chroma .p { color: #8B95A8; }
    .chroma .n { color: #D4D0EA; }
    .chroma .nb, .chroma .bp, .chroma .nn { color: #6BCAD8; }
    .chroma .nf, .chroma .fm { color: #82AAFF; }
    .chroma .nd { color: #F07898; }
    .chroma .nt { color: #FF5370; }
    .chroma .na { color: #B4A2E8; }
    .chroma .nv, .chroma .vc, .chroma .vg, .chroma .vi, .chroma .ne { color: #FF5370; }
    .chroma .s, .chroma .s1, .chroma .s2, .chroma .sb, .chroma .sc, .chroma .sd,
    .chroma .sh, .chroma .si, .chroma .sx, .chroma .ss, .chroma .sa, .chroma .dl { color: #6FC898; }
    .chroma .se, .chroma .sr { color: #6BCAD8; }
    .chroma .m, .chroma .mb, .chroma .mf, .chroma .mh, .chroma .mi, .chroma .mo, .chroma .il { color: #F8D06A; }
    .chroma .gd { color: #FF5370; background-color: #FF537014; }
    .chroma .gi { color: #6FC898; background-color: #6FC89814; }
    .chroma .gh, .chroma .gu { color: #82AAFF; font-weight: bold; }
    .chroma .ge { font-style: italic; }
    .chroma .gs { font-weight: bold; }
    .chroma .err { color: #FF5370; }
    ::selection { background: #2B3758; }
  '';

  # Script run as root in forgejo.service ExecStartPre — creates dirs and symlinks
  # into the Nix store so they auto-update on rebuild without a separate service.
  setupAssets = pkgs.writeShellScript "forgejo-setup-assets.sh" ''
    install -d -m 755 \
      ${customDir}/public/assets/css \
      ${customDir}/public/assets/fonts \
      ${customDir}/public/assets/img
    ln -sf ${themeCSS}    ${customDir}/public/assets/css/theme-natsumikan.css
    ln -sf ${haruhanaCSS} ${customDir}/public/assets/css/theme-haruhana.css
    ln -sf ${fontFile}    ${customDir}/public/assets/fonts/GoogleSansFlex-VariableFont.ttf
    ln -sf ${mapleTtf}/MapleMono-Regular.ttf ${customDir}/public/assets/fonts/MapleMono-Regular.ttf
    ln -sf ${mapleTtf}/MapleMono-Bold.ttf    ${customDir}/public/assets/fonts/MapleMono-Bold.ttf
    ln -sf ${iconPng}     ${customDir}/public/assets/img/favicon.png
    ln -sf ${iconPng}     ${customDir}/public/assets/img/logo.png
    ln -sf ${iconSvg}     ${customDir}/public/assets/img/favicon.svg
    ln -sf ${iconSvg}     ${customDir}/public/assets/img/logo.svg
  '';
in
lib.mkIf (cfg != null && cfg.enable) {
  sops.secrets."forgejo/secret-key" = { owner = "forgejo"; };
  sops.secrets."forgejo/internal-token" = { owner = "forgejo"; };
  sops.secrets."forgejo/oauth2-jwt-secret" = { owner = "forgejo"; };
  sops.secrets."forgejo/runner-token" = { mode = "0444"; };
  sops.templates."forgejo-runner-env" = {
    mode = "0444";
    content = "TOKEN=${config.sops.placeholder."forgejo/runner-token"}";
  };

  services.forgejo = {
    enable = true;
    stateDir = cfg.dataDir;
    database = {
      type = "postgres";
      createDatabase = true;
    };
    secrets = {
      security = {
        SECRET_KEY = lib.mkForce config.sops.secrets."forgejo/secret-key".path;
        INTERNAL_TOKEN = lib.mkForce config.sops.secrets."forgejo/internal-token".path;
      };
      oauth2 = {
        JWT_SECRET = lib.mkForce config.sops.secrets."forgejo/oauth2-jwt-secret".path;
      };
    };
    settings = {
      server = {
        DOMAIN = cfg.publicHost;
        ROOT_URL = "https://${cfg.publicHost}";
        HTTP_PORT = cfg.port;
        SSH_PORT = 22;
        SSH_DOMAIN = config.networking.hostName;
        SSH_USER = "forgejo";
        LANDING_PAGE = "explore"; # anonymous visitors land on /explore, not the marketing home
      };
      actions.ENABLED = true;
      service.DISABLE_REGISTRATION = true;
      DEFAULT.APP_NAME = "Kuroma's Vault of Code";
      ui = {
        DEFAULT_THEME = "haruhana";
        THEMES = "gitea,arc-green,forgejo-dark,forgejo-light,forgejo-auto,natsumikan,haruhana";
      };
    };
  };

  # forgejo-secrets.service only writes if files are empty — sops secrets never are,
  # so it's a no-op. Clear ReadWritePaths so it doesn't need customDir to exist first.
  systemd.services.forgejo-secrets = {
    after = [ "sops-install-secrets.service" ];
    serviceConfig.ReadWritePaths = lib.mkForce [];
  };

  # Create custom/conf dirs on ZFS after dataset is mounted (needed by forgejo-secrets)
  systemd.services.forgejo-init-dirs = {
    description = "Create Forgejo directory structure on ZFS";
    after = [ "zfs-datasets.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/install -d -m 750 -o forgejo -g forgejo ${cfg.dataDir}/custom ${cfg.dataDir}/custom/conf";
    };
  };

  systemd.services.forgejo = {
    after = [ "postgresql-setup.service" "forgejo-init-dirs.service" ];
    requires = [ "postgresql-setup.service" "forgejo-init-dirs.service" ];
    serviceConfig.ExecStartPre = lib.mkAfter [
      # Symlink theme CSS, font, and icon from Nix store — auto-updates on rebuild
      "+${setupAssets}"
      # Re-enable write on app.ini (forgejo-secrets sets it read-only after injection)
      "+${pkgs.coreutils}/bin/chmod u+w ${customDir}/conf/app.ini"
    ];
  };

  # git SSH uses system sshd on port 22 (already open on tailscale0 via networking.nix).
  # Defense-in-depth: even if a key lands in forgejo's authorized_keys without the
  # standard `command="forgejo serv …"` prefix, this Match block keeps the session
  # from being weaponized as a pivot (no port/agent forwarding, no PTY, no X11).
  # Forgejo's own SSH operations (push/pull) don't need any of these.
  services.openssh.extraConfig = ''
    Match User forgejo
      AllowAgentForwarding no
      AllowTcpForwarding no
      AllowStreamLocalForwarding no
      PermitTTY no
      X11Forwarding no
      PermitTunnel no
      GatewayPorts no
  '';

  # Actions runner — register token from https://git.kuroma.dev/-/admin/runners then add to sops
  services.gitea-actions-runner.instances.${config.networking.hostName} = {
    enable = true;
    name = config.networking.hostName;
    url = "https://${cfg.publicHost}";
    tokenFile = config.sops.templates."forgejo-runner-env".path;
    labels = [ "native:host" "ubuntu-latest:docker://ubuntu:latest" ];
    settings = {
      log.level = "warn";
      runner.capacity = 2;
      cache.enabled = false;
    };
  };
}
