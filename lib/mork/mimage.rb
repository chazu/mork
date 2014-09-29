require 'RMagick'

module Mork
  # The class Mimage is a wrapper for the core image library, currently RMagick
  class Mimage
    def initialize(img, page=0)
      if img.class == String
        if File.extname(img) == '.pdf'
          @image = Magick::Image.read(img) { self.density = 200 }[page]
        else
          @image = Magick::ImageList.new(img)[page]
        end
      elsif img.class == Magick::ImageList
        @image = img[page]
      elsif img.class == Magick::Image
        @image = img
      else
        raise "Invalid initialization argument"
      end
    end
    
    # outline!(cells, roundedness)
    # 
    # draws on the Mimage a set of cell outlines
    # typically used to highlight the expected responses
    def outline!(cells, roundedness=nil)
      cells = [cells] if cells.is_a? Hash
      return if cells.empty?
      roundedness ||= [cells[0][:h], cells[0][:w]].min / 2
      out = Magick::Draw.new
      out.stroke 'green'
      out.stroke_width 4
      out.fill_opacity 0
      cells.each do |c|
        out.roundrectangle c[:x], c[:y], c[:x]+c[:w], c[:y]+c[:h], roundedness, roundedness
        out.draw @image
      end
    end
    
    # =============
    # = Highlight =
    # =============
    def highlight_cells!(cells, roundedness=nil)
      cells = [cells] if cells.is_a? Hash
      return if cells.empty?
      roundedness ||= [cells[0][:h], cells[0][:w]].min / 2
      cells.each do |c|
        out = Magick::Draw.new
        out.fill 'yellow'
        out.opacity '40%'
        out.roundrectangle c[:x], c[:y], c[:x]+c[:w], c[:y]+c[:h], roundedness, roundedness
        out.draw @image
      end
    end
    
    def highlight_rect!(areas)
      areas = [areas] if areas.is_a? Hash
      areas.each do |c|
        out = Magick::Draw.new
        out.fill_opacity 0
        out.stroke 'yellow'
        out.stroke_width 3
        out.rectangle c[:x], c[:y], c[:x]+c[:w], c[:y]+c[:h]
        out.draw @image
      end
    end
    
    def cross_cells!(cells)
      cells = [cells] if cells.is_a? Hash
      cells.each do |c|
        out = Magick::Draw.new
        out.stroke 'yellow'
        out.stroke_width 3
        out.line
      end
    end
    
    def join!(p)
      poly = Magick::Draw.new
      poly.fill_opacity 0
      poly.stroke 'green'
      poly.stroke_width 3
      poly.polygon p[0][:x], p[0][:y], p[1][:x], p[1][:y], p[2][:x], p[2][:y], p[3][:x], p[3][:y]
      poly.draw @image
    end
    
    # ============
    # = Cropping =
    # ============
    def crop(c)
      Mimage.new @image.crop(c[:x], c[:y], c[:w], c[:h])
    end
    
    def crop!(c)
      @image.crop!(c[:x], c[:y], c[:w], c[:h])
      self
    end
    
    # ============
    # = Blurring =
    # ============
    def blur(a, b)
      Mimage.new @image.blur_image(a, b)
    end

    def blur!(a, b)
      @image = @image.blur_image(a, b)
      self
    end
    
    # ==============
    # = Stretching =
    # ==============
    def stretch(points)
      Mimage.new @image.distort(Magick::PerspectiveDistortion, points)
    end
    
    def stretch!(points)
      @image = @image.distort(Magick::PerspectiveDistortion, points)
      self
    end
    
    # returns the raw pixels from the entire image or from the area
    # defined in opts
    def pixels(opts = {})
      c = {x: 0, y: 0, w: width, h: height}.merge(opts)
      @image.export_pixels(c[:x], c[:y], c[:w], c[:h], "I")
    end
    
    def width
      @image.columns
    end
    
    def height
      @image.rows
    end
    
    # write the underlying Magick::Image to disk
    def write(fname)
      @image.write fname
    end
  end
end