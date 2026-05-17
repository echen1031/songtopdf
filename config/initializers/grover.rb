# frozen_string_literal: true

# Grover shells out to Node for Puppeteer. GUI-launched consoles often lack nvm/fnm on PATH.
# Set NODE_BINARY (or GROVER_NODE) to an absolute path if `node` is not found, e.g.:
#   ~/.nvm/versions/node/v22.14.0/bin/node
#   /opt/homebrew/bin/node
grover_node_executable = lambda do
  from_env = ENV["NODE_BINARY"].presence || ENV["GROVER_NODE"].presence
  return from_env if from_env && File.executable?(from_env)

  %w[/opt/homebrew/bin/node /usr/local/bin/node].each do |p|
    return p if File.executable?(p)
  end

  ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
    next if dir.empty?

    candidate = File.join(dir, "node")
    return candidate if File.executable?(candidate)
  end

  "node"
end

Grover.configure do |config|
  config.js_runtime_bin = [grover_node_executable.call]

  config.options = {
    format: "A4",
    emulate_media: "print",
    print_background: true,
    margin: {
      top: "5mm",
      bottom: "5mm",
      left: "5mm",
      right: "5mm"
    },
    # Helpful in Docker / CI; harmless on macOS dev.
    launch_args: %w[--no-sandbox --disable-setuid-sandbox]
  }

  if (path = ENV["GROVER_EXECUTABLE_PATH"].presence)
    config.options[:executable_path] = path
  end
end
