class Portlet < ActiveRecord::Base

  validates_presence_of :name

  #These are here simply to temporarily hold these values
  #Makes it easy to pass them through the process of selecting a portlet type
  attr_accessor :connect_to_page_id, :connect_to_container
  
  def self.inherited(subclass)
    super if defined? super
  ensure
    ( @subclasses ||= [] ).push(subclass).uniq!
    subclass.class_eval do
      
      has_dynamic_attributes
      
      acts_as_content_block(
        :versioned => false, 
        :publishable => false,
        :renderable => {:instance_variable_name_for_view => "@portlet"})
      
      def self.helper_path
        "app/portlets/helpers/#{name.underscore}_helper.rb"
      end

      def self.helper_class
        "#{name}Helper".constantize
      end      
    end      
  end

  # In Rails, Classes aren't loaded until you ask for them
  # This method will load all portlets that are defined
  # in a app/portlets directory on the load path
  def self.load_portlets
    ActiveSupport::Dependencies.load_paths.each do |d| 
      if d =~ /app\/portlets/
        Dir["#{d}/*_portlet.rb"].each{|p| require_dependency(p) }
      end
    end
  end

  def self.has_edit_link?
    false
  end
  
  def self.types
    load_portlets
    @subclasses || []
  end

  def self.get_subclass(type)
    raise "Unknown Portlet Type" unless types.map(&:name).include?(type)
    type.constantize 
  end

  def self.content_block_type
    "portlet"
  end 
  
  def self.content_block_type_for_list
    "portlet"
  end
  
  # For column in list
  def portlet_type_name
    type.titleize
  end

  def self.form
    "portlets/#{name.tableize.sub('_portlets','')}/form"
  end
  
  def self.default_template
    template_file = ActionController::Base.view_paths.map do |vp| 
      path = vp.to_s.first == "/" ? vp.to_s : File.join(Rails.root, vp.to_s)
      File.join(path, default_template_path)
    end.detect{|f| File.exists? f }
    template_file ? open(template_file){|f| f.read } : ""
  end
  
  def self.set_default_template_path(s)
    @default_template_path = s
  end
  
  def self.default_template_path
    @default_template_path ||= "portlets/#{name.tableize.sub('_portlets','')}/render.html.erb"
  end

  def inline_options
    {:inline => self.template}
  end

  def type_name
    type.to_s.titleize
  end

  def self.columns_for_index
    [ {:label => "Name", :method => :name, :order => "name" },
      {:label => "Type", :method => :type_name, :order => "type" },
      {:label => "Updated On", :method => :updated_on_string, :order => "updated_at"} ]
  end
  
  def instance_name
    "#{self.class.name.demodulize.underscore}_#{id}"
  end
  
end