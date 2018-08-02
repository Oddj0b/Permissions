#!/usr/bin/env ruby

require "run_loop"
require "luffa"

cucumber_args = "#{ARGV.join(" ")}"

this_dir = File.expand_path(File.dirname(__FILE__))
working_directory = File.join(this_dir, "..", "..")

# on-simulator tests of features in test/cucumber
Dir.chdir(working_directory) do

  FileUtils.rm_rf("reports")
  FileUtils.mkdir_p("reports")

  Luffa.unix_command("make clean",
                     {:pass_msg => "cleaned",
                      :fail_msg => "could not clean"})

  Luffa.unix_command("make app",
                     {:pass_msg => "built app",
                      :fail_msg => "could not build app"})

  xcode = RunLoop::Xcode.new
  xcode_version = xcode.version
  sim_major = xcode_version.major + 2
  sim_minor = xcode_version.minor

  sim_version = RunLoop::Version.new("#{sim_major}.#{sim_minor}")

  if ENV["JENKINS_HOME"]
    devices = {
      :iphone7 => "iPhone 7"
    }
  else
    devices = {
      :iphoneSE => "iPhone SE"
    }
  end

  RunLoop::CoreSimulator.terminate_core_simulator_processes

  simulators = RunLoop::Simctl.new.simulators

  env_vars = {}

  passed_sims = []
  failed_sims = []
  devices.each do |key, name|
    args = [
      "bundle", "exec",
      "cucumber", "-p", "default",
      "-f", "json", "-o", "reports/#{key}.json",
      "-f", "junit", "-o", "reports/junit",
      "#{cucumber_args}"
    ]

    match = simulators.find do |sim|
      sim.name == name && sim.version == sim_version
    end

    env_vars = {"DEVICE_TARGET" => match.udid}

    exit_code = Luffa.unix_command(args.join(" "), {:exit_on_nonzero_status => false,
                                                  :env_vars => env_vars})
    if exit_code == 0
      passed_sims << name
    else
      failed_sims << name
    end
  end

  Luffa.log_info "=== SUMMARY ==="
  Luffa.log_info ""
  Luffa.log_info "PASSING SIMULATORS"
  passed_sims.each { |sim| Luffa.log_info(sim) }
  Luffa.log_info ""
  Luffa.log_info "FAILING SIMULATORS"
  failed_sims.each { |sim| Luffa.log_info(sim) }

  sims = devices.count
  passed = passed_sims.count
  failed = failed_sims.count

  puts ""
  Luffa.log_info "passed on "#{passed}" out of "#{sims}""

  # if none failed then we have success
  exit 0 if failed == 0

  # the travis ci environment is not stable enough to have all tests passing
  exit failed unless Luffa::Environment.travis_ci?

  # we"ll take 75% passing as good indicator of health
  expected = 75
  actual = ((passed.to_f/sims.to_f) * 100).to_i

  if actual >= expected
    Luffa.log_pass "We failed '#{failed}' sims, but passed '#{actual}%' so we say good enough"
    exit 0
  else
    Luffa.log_fail "We failed '#{failed}' sims, which is '#{actual}%' and not enough to pass"
    exit 1
  end
end
