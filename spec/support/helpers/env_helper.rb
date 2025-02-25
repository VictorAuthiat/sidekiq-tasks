module EnvHelper
  def stub_env(env_name, env_value)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with(env_name).and_return(env_value)
  end
end
