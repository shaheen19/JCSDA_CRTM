require 'rexml/document'

module SrcGen

  class Dimension
    def initialize
    end
  end
  
  class Config
    
    attr_reader :name, :type_name
    attr_reader :dimensions, :dimvectors, :scalardata, :arraydata
    attr_reader :xml
    attr_reader :release,
                :version
    
    
    # Class method to load configuration
    def initialize(xml_config_file,debug=false)
      load(xml_config_file,debug=debug)
      @name       = extract_name("type")
      @type_name  = "#{@name}_type"
      @release    = extract_value("type/release")
      @version    = extract_value("type/version")
      @dimensions = extract_group("type/dimensions/dim").sort_by {|d| d[:index]}
      @dimvectors = extract_group("type/dimvectors/array").sort_by {|v| v[:dimindex]}
      @scalardata = extract_group("type/scalardata/scalar")
      @arraydata  = extract_group("type/arraydata/array")

    end

    def max_dim_name_length
      @dimensions.collect {|d| d[:name].length}.max
    end

    def dim_names
      @dimensions.collect {|d| d[:name]}
    end
    

    
    def max_dimvec_name_length
      @dimvectors.collect {|v| v[:name].length}.max
    end
    
  private

    # Load the original XML data into its own component  
    def load(config_file,debug=false)
      begin
        @xml = REXML::Document.new(File.open(config_file))
        if debug
          puts("\n---BEGIN-DEBUG-OUTPUT---")
          puts("\n#{self.class} #{__method__} method output:")
          puts("\n#{@xml.elements["*"]}")
          puts("\n----END-DEBUG-OUTPUT----")
        end
      rescue REXML::ParseException => error_message
        puts("\n#{error_message}")
        raise(RuntimeError,"Error loading XML config file #{config_file}") 
      end
    end
    
    def extract_attribute(key,name)
      @xml.elements[key].attributes[name]
    end
    
    def extract_name(key)
      extract_attribute(key,"name")
    end

    def extract_value(key)
      extract_attribute(key,"value")
    end

    def extract_group(key)
      group = []
      @xml.elements.each(key) do |e|
        hash = Hash.new
        e.attributes.each {|k,v| hash[k.to_sym] = v}
        group << hash
      end
      group
    end

  end
end
