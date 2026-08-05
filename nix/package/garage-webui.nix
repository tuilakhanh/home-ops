{
  autoPatchelfHook,
  fetchurl,
  glibc,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "garage-webui";
  version = "1.1.0";

  src = fetchurl {
    url = "https://github.com/khairul169/garage-webui/releases/download/${finalAttrs.version}/garage-webui-v${finalAttrs.version}-linux-amd64";
    hash = "sha256-GAtZRpV5KPbO8Wg8SEpp07bE8OwA4TJAKGP8j/gk50Y=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ glibc ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/garage-webui"
    runHook postInstall
  '';

  meta = {
    description = "Web interface for Garage object storage";
    homepage = "https://github.com/khairul169/garage-webui";
    license = lib.licenses.mit;
    mainProgram = "garage-webui";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
