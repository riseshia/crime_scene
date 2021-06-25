module CrimeScene
  module ConstantPathResolver
    module_function

    # @return [String] const_path
    def resolve(const_name)
      const_name.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase + ".rb"
    end
  end
end
