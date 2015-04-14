class HtmlCompilator::Tables::Table
  include ActionView::Helpers::TagHelper

  attr_reader :node

  def self.compile(xml_file_path)
    file = File.open(xml_file_path)
    node = Nokogiri::XML(file).root
    new(node).to_html
  end

  def initialize(node)
    @node = node
  end

  def to_html
    h.content_tag(:table, :border => 1) {
      h.concat h.content_tag(:caption) {
        captions.each do |caption|
          h.concat caption.to_html
        end
      } if captions.present?

      h.concat h.content_tag(:thead) {
        header_rows.each do |row|
          h.concat row.to_html
        end
      }

      h.concat h.content_tag(:tbody) {
        body_rows.each do |row|
          h.concat row.to_html
        end
      }

      h.concat h.content_tag(:tfoot) {
        footers.each do |footer|
          h.concat footer.to_html
        end
      } if footers.present?
    }
  end

  def columns
    @columns ||= HtmlCompilator::Tables::Column.generate(:table => self)
  end

  def captions
    @captions ||= HtmlCompilator::Tables::Caption.generate(:table => self)
  end

  def footers
    @footers ||= HtmlCompilator::Tables::Footer.generate(:table => self)
  end

  def header_rows
    @header_rows ||= HtmlCompilator::Tables::HeaderRow.generate(:table => self, :node => node.xpath('BOXHD'))
  end

  def body_rows
    @body_rows ||= node.css('ROW').map do |row_node|
      HtmlCompilator::Tables::BodyRow.new(:table => self, :node => row_node)
    end
  end

  def num_columns
    node.attr("COLS").to_i
  end

  def h
    @h ||= ActionView::Base.new
  end

  def transform(xml)
    @text_transformer ||= Nokogiri::XSLT(
      File.read("#{Rails.root}/app/views/xslt/matchers/table_contents.html.xslt")
    )
    @text_transformer.transform(Nokogiri::XML(xml)).to_s.strip.html_safe
  end

  def options
    @options ||= (node.attr("OPTS") || '').split(',')
  end

  def rules
    return @rules if @rules
    rule_option = options.
      map{|x| x.sub(/\(.*\)/,'')}.
      detect{|x| %w(L0 L1 L2 L3 L4 L5 L6).include?(x) }
    @rules = case rule_option
    when "L0"
      []
    when "L1"
      [:horizonal]
    when "L2"
      [:horizonal, :down]
    when "L3"
      [:horizonal, :side]
    when "L4"
      [:horizonal, :down, :side]
    when "L5"
      # documented as "trim side only", but not really in use
      #  and doesn't make sense on the web
      [:horizonal, :side]
    when "L6"
      # documented as "trim side only", but not really in use
      #  and doesn't make sense on the web
      [:horizonal, :down, :side]
    else
      [] # not specified; what is the default?
    end
  end
end