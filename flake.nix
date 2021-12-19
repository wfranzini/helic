{
  description = "Clipboard Manager";

  inputs.hix.url = github:tek/hix;
  inputs.polysemy-conc.url = github:tek/polysemy-conc;

  outputs = { hix, polysemy-conc, ... }:
  let
    gtkDeps = pkgs: with pkgs; [
      pkgconfig
      gobject-introspection
    ];

    all = { transform_, pkgs, unbreak, hackage, ... }: {
      exon = hackage "0.2.0.1" "0hs0xrh1v64l1n4zqx3rqfjdh6czxm7av85kj1awya9zxcfcy5cl";
      flatparse = hackage "0.3.1.0" "15nx2p08pqka0136xfppw344a60rn3fvsx4adiz15k37cyj25zi2";
      helic = transform_ (d: d.overrideAttrs (old: { buildInputs = old.buildInputs ++ gtkDeps pkgs; }));
      polysemy-chronos = hackage "0.2.0.1" "15j7x4jvigqji7gc6dr4fjlsv912sxzvfyb3jvll09p5j3rk4qc2";
      polysemy-conc = hackage "0.5.1.1" "1gqyskqkdavbzpqvlhxf3f5j130w06wc7cw8kxn2cayavzd9zl9b";
      polysemy-log = hackage "0.4.0.0" "1r9f925884ay06w44r1fvp8bh5nm642g49np2vybz8hjiia8ghdx";
      polysemy-process = hackage "0.5.1.1" "1yjqb8bccznvxihyi8lscn4nbfc7arazrrbh0zyl3vw6f99zj2cs";
      polysemy-http = hackage "0.5.0.0" "12kzq6910qwj7n1rwym3zibjm5cv7llfgk9iagcwd16vfysag6wp";
    };

    ghc901 = { hackage, ... }: {
      relude = hackage "1.0.0.1" "164p21334c3pyfzs839cv90438naxq9pmpyvy87113mwy51gm6xn";
    };

    ghc884 = { hackage, ... }: {
    };

    ghc8107 = { hackage, ... }: {
    };

    dev = { hackage, ... }: {
      polysemy = hackage "1.7.1.0" "0qwli1kx3hk68hqsgw65mk81bx0djw1wlk17v8ggym7mf3lailyc";
      polysemy-plugin = hackage "0.4.3.0" "1r7j1ffsd6z2q2fgpg78brl2gb0dg8r5ywfiwdrsjd2fxkinjcg1";
    };

    outputs = hix.flake {
      base = ./.;
      deps = [polysemy-conc];
      packages.helic = ./packages/helic;
      overrides = { inherit all ghc884 ghc8107 ghc901 dev; };
      ghci.extraArgs = ["-fplugin=Polysemy.Plugin"];
      shellConfig = { pkgs, ...}: {
        buildInputs = gtkDeps pkgs;
        haskellPackages = g: [g.hsc2hs];
      };
      modify = _: outputs: rec {
        apps.hel = {
          type = "app";
          program = "${outputs.packages.helic}/bin/hel";
        };
        defaultApp = apps.hel;
      };
    };

  in outputs // { nixosModule = import ./ops/nix/module.nix outputs.packages; };
}
