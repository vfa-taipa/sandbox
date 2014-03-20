require 'chunky_png'

png = ChunkyPNG::Image.new(50, 50, ChunkyPNG::Color::TRANSPARENT)
cells = 50

cells.times do |n|
  if n % 2 == 0
    cells.times do |x|
      if x % 2 != 0
        png[x,n] = ChunkyPNG::Color.rgba(10, 20, 30, 128)
      end
    end
  end
end

color = ChunkyPNG::Color.from_hex('#0066FF')

png.circle(15,10,5, color, color)
png.circle(35,10,5, color, color)
png.circle(25,20,3, color, color)

png.line(5,25,25,40, color, color)
png.line(25,40,45,25, color, color)

png.save('smile.png', :interlace => true)
