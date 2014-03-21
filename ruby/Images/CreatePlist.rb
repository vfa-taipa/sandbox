#!/usr/bin/env ruby
require 'chunky_png'

class CreatePlist
	def initialize(pngfile)
		@image = ChunkyPNG::Image.from_file(pngfile)
		puts("height : #{@image.dimension.height}")
		puts("width  : #{@image.dimension.width}")
	end

	def findFirstPoint
		i = 0
		while (i <= @image.dimension.height)
			if (ChunkyPNG::Color.a(@image[0,i]) == 255) then
				break
			end
			i += 1
		end
		return P.new(0,i)
	end
# =========================
	def nextPoint(p)
		m = 0
		mp = nil
		for p1 in p.around
			if (ChunkyPNG::Color.a(@image[p1.x,p1.y]) == 255) then
				c = self.count1(p1)
				if (c >= m) && (@line.index{|x| x.x == p1.x && x.y == p1.y} == nil) then
					#a.index { |x| x == "b" }
					m = c
					mp = p1
				end
				puts("x : #{p1.x}, y : #{p1.y}, alpha : #{ChunkyPNG::Color.a(@image[p1.x,p1.y])}, count : #{c}")	
			end
		end
		return mp;
	end
# =========================
	def count1(p)
		c = 0
		for p1 in p.around
			if (ChunkyPNG::Color.a(@image[p1.x,p1.y]) != 255) then
				c += 1
			end
		end
		return c
	end	
# =========================
	def run
		@line = Array.new

		p = self.findFirstPoint
		puts("First point : x = #{p.x}, y = #{p.y}")
		@line.push(p)
		for i in 1..10
			p = self.nextPoint(p)
			if (p != nil) then
				puts("Next point : x = #{p.x}, y = #{p.y}")
				@line.push(p)
			end
		end
	end
end
#==================================
class P
	attr_reader :x, :y

	def initialize(x,y)
		@x = x
		@y = y
	end
	def around
		rs = Array.new
		for i in @x-1..@x+1 
			if (i < 0) then
				next
			end
			for j in @y-1..@y+1 
				if (j < 0) then
					next
				end
				if (i == @x && j == @y) then
					next
				end
				rs.push(P.new(i,j))
			end
		end
		return rs
	end
end
#==================================

c = CreatePlist.new('stage6.png')
c.run
