{ src, buildGoModule }:
buildGoModule {
  inherit src;

  pname = "envctl";
  version = "0.0.9";

  vendorHash = "sha256-D9/UE5iHLQtykVJi5HL7ioYM6fZUDCwk5oA+WsAPzKM=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
