# Command: gateway — start HTTP server

cmd_gateway() {
  config_init
  _load_env
  gateway_start "$@"
}
