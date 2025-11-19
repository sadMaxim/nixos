{ inputs, self, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {

      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
        ];
        shellHook = ''
        '';
      };

    };
}
