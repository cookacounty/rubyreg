 require 'anyway_config'

 Anyway::Settings.use_local_files = true

 class RubyRegCfg < Anyway::Config
    attr_config :autowire_modules,:autowire_enable,:register_width
    config_name :rubyreg

	describe_options(
	  # In this case, you should specify a hash with `type`
	  # and (optionally) `desc` keys
	  autowire_enable: {
	    desc: "Enable autowire",
	    type: String
	  }
	)

 end

 def load_config

 	if $options[:config]
		ENV['RUBYREG_CONF']= $options[:config]
	else
		ENV['RUBYREG_CONF']=__dir__+"/../../config/default.yml"
	end
	cfg = RubyRegCfg.new
	pp cfg
	$config = cfg
end